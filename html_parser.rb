require 'nokogiri'
require 'open-uri'
require 'json'
require 'csv'
require 'parallel'
# require 'pdf-reader'  # временно отключим
# require 'charlock_holmes'  # временно отключим
require 'net/http'
require 'uri'
require 'stringio'

class HtmlParser
  def initialize(url)
    @url = url
  end

  def parse
    # Загружаем HTML документ
    doc = Nokogiri::HTML(URI.open(@url))
    
    # Создаем хэш для хранения результатов
    result = {
      title: parse_title(doc),
      links: parse_links(doc),
      headings: parse_headings(doc)
    }
    
    result
  end

  def parse_images
    doc = Nokogiri::HTML(URI.open(@url))
    doc.css('img').map do |img|
      {
        src: img['src'],
        alt: img['alt'],
        title: img['title']
      }
    end
  end

  def parse_meta_tags
    doc = Nokogiri::HTML(URI.open(@url))
    doc.css('meta').map do |meta|
      {
        name: meta['name'],
        content: meta['content']
      }
    end
  end

  def search(css_selector)
    doc = Nokogiri::HTML(URI.open(@url))
    doc.css(css_selector).map(&:text)
  end

  # Добавим кэширование документа
  def document
    @document ||= Nokogiri::HTML(URI.open(@url))
  end

  # Поиск элементов по ID
  def find_by_id(id)
    document.at_css("##{id}")&.text&.strip
  end

  # Поиск по классу
  def find_by_class(class_name)
    document.css(".#{class_name}").map(&:text)
  end

  # Извлечение таблиц
  def parse_tables
    document.css('table').map do |table|
      rows = table.css('tr').map do |row|
        row.css('td, th').map(&:text)
      end
      {
        headers: rows.first,
        data: rows[1..-1]
      }
    end
  end

  # Извлечение списков (ul, ol)
  def parse_lists
    {
      unordered: parse_list_items('ul'),
      ordered: parse_list_items('ol')
    }
  end

  # Извлечение скриптов
  def parse_scripts
    document.css('script').map do |script|
      {
        type: script['type'],
        src: script['src'],
        content: script.content
      }
    end
  end

  # Извлечение стилей
  def parse_styles
    document.css('link[rel="stylesheet"], style').map do |style|
      {
        type: style.name,
        href: style['href'],
        content: style.content
      }
    end
  end

  # Извлечение форм
  def parse_forms
    document.css('form').map do |form|
      {
        action: form['action'],
        method: form['method'],
        inputs: form.css('input').map { |input| 
          {
            type: input['type'],
            name: input['name'],
            id: input['id']
          }
        }
      }
    end
  end

  # Извлечение JSON-LD структурированных данных
  def parse_json_ld
    document.css('script[type="application/ld+json"]').map do |script|
      JSON.parse(script.content) rescue nil
    end.compact
  end

  # Извлечение микроданных
  def parse_microdata
    document.css('[itemscope]').map do |element|
      {
        type: element['itemtype'],
        properties: element.css('[itemprop]').map { |prop|
          { name: prop['itemprop'], content: prop.text.strip }
        }
      }
    end
  end

  # Извлечение комментариев в HTML
  def parse_comments
    document.xpath('//comment()').map(&:text)
  end

  # Извлечение iframe
  def parse_iframes
    document.css('iframe').map do |iframe|
      {
        src: iframe['src'],
        width: iframe['width'],
        height: iframe['height'],
        title: iframe['title']
      }
    end
  end

  # Проверка на наличие определенных технологий
  def detect_technologies
    technologies = {
      jquery: document.css('script[src*="jquery"]').any?,
      bootstrap: document.css('link[href*="bootstrap"], script[src*="bootstrap"]').any?,
      google_analytics: document.text.include?('ga(') || document.text.include?('gtag'),
      react: document.css('script[src*="react"]').any? || document.text.include?('React'),
      vue: document.css('script[src*="vue"]').any? || document.text.include?('Vue'),
    }
  end

  # Извлечение всех цветов из CSS
  def parse_colors
    styles = document.css('style').map(&:text).join
    styles.scan(/#[0-9a-fA-F]{3,6}|rgb\([^)]+\)|rgba\([^)]+\)/).uniq
  end

  # Извлечение данных из определенного блока по селектору
  def parse_block(selector)
    block = document.css(selector).first
    return nil unless block

    {
      text: clean_text(block.text),
      links: block.css('a').map { |link| { text: link.text.strip, href: link['href'] } },
      images: block.css('img').map { |img| { src: img['src'], alt: img['alt'] } }
    }
  end

  # Сохранение результатов в файл
  def save_to_file(filename, format = :json)
    data = {
      url: @url,
      timestamp: Time.now,
      title: document.title,
      content: {
        links: parse_links(document),
        images: parse_images,
        tables: parse_tables,
        forms: parse_forms
      }
    }

    case format
    when :json
      File.write("#{filename}.json", JSON.pretty_generate(data))
    when :yaml
      File.write("#{filename}.yaml", data.to_yaml)
    when :csv
      CSV.open("#{filename}.csv", "wb") do |csv|
        csv << data.keys
        csv << data.values
      end
    end
  end

  # Поиск по тексту с контекстом
  def search_with_context(query, context_size = 50)
    document.text.scan(/(?:.{0,#{context_size}})?#{Regexp.escape(query)}(?:.{0,#{context_size}})?/)
  end

  # Извлечение всех email адресов
  def parse_emails
    document.text.scan(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/).uniq
  end

  # 1. Многопоточный парсинг
  def parse_urls_parallel(urls, threads = 4)
    Parallel.map(urls, in_threads: threads) do |url|
      begin
        parser = self.class.new(url)
        {
          url: url,
          data: parser.parse,
          status: 'success'
        }
      rescue StandardError => e
        {
          url: url,
          error: e.message,
          status: 'error'
        }
      end
    end
  end

  # 2. Поддержка прокси
  def initialize(url, proxy_options = nil)
    @url = url
    @proxy_options = proxy_options
  end

  def document
    @document ||= begin
      if @proxy_options
        uri = URI(@url)
        proxy = Net::HTTP::Proxy(@proxy_options[:host], 
                               @proxy_options[:port], 
                               @proxy_options[:user], 
                               @proxy_options[:password])
        
        response = proxy.get_response(uri)
        Nokogiri::HTML(response.body)
      else
        Nokogiri::HTML(URI.open(@url))
      end
    end
  end

  # Заменим метод определения кодировки
  def detect_encoding(content)
    # Пробуем определить кодировку из HTTP заголовков
    if content.respond_to?(:charset)
      return content.charset
    end

    # Пробуем найти кодировку в meta тегах
    doc = Nokogiri::HTML(content)
    meta_charset = doc.at_css('meta[charset]')&.[]('charset')
    return meta_charset if meta_charset

    meta_content_type = doc.at_css('meta[http-equiv="Content-Type"]')&.[]('content')
    if meta_content_type && meta_content_type =~ /charset=(.+)/i
      return $1
    end

    # По умолчанию используем UTF-8
    'utf-8'
  end

  def parse_with_encoding
    response = URI.open(@url)
    content = response.read
    encoding = detect_encoding(response)
    
    # Пробуем сконвертировать в UTF-8 если нужно
    if encoding && encoding.downcase != 'utf-8'
      content = content.encode('UTF-8', encoding, invalid: :replace, undef: :replace)
    end
    
    doc = Nokogiri::HTML(content)
    parse_with_document(doc)
  rescue StandardError => e
    puts "Ошибка при определении кодировки: #{e.message}"
    # Fallback к обычному парсингу
    parse
  end

  # Временно отключим парсинг PDF
  def parse_pdf(pdf_url)
    { error: "PDF parsing temporarily disabled" }
  end

  private

  def parse_title(doc)
    doc.title
  end

  def parse_links(doc)
    doc.css('a').map do |link|
      {
        text: link.text.strip,
        href: link['href']
      }
    end
  end

  def parse_headings(doc)
    doc.css('h1, h2, h3').map do |heading|
      {
        level: heading.name[1].to_i,
        text: heading.text.strip
      }
    end
  end

  def parse_list_items(list_type)
    document.css(list_type).map do |list|
      list.css('li').map(&:text)
    end
  end

  # Добавим метод для очистки текста
  def clean_text(text)
    text.to_s.strip.gsub(/\s+/, ' ')
  end

  def download_pdf(url)
    temp_file = Tempfile.new(['download', '.pdf'])
    temp_file.binmode
    temp_file.write(URI.open(url).read)
    temp_file.rewind
    temp_file
  end

  # 5. Интеграция с базой данных
  def save_to_database(data, db_config)
    require 'sequel'
    
    # Используем локальную переменную вместо константы
    db = Sequel.connect(db_config)
    
    # Создаем таблицу, если она не существует
    db.create_table? :parsed_pages do
      primary_key :id
      String :url
      String :title
      Text :content
      DateTime :parsed_at
      String :status
    end
    
    # Сохраняем данные
    db[:parsed_pages].insert(
      url: @url,
      title: data[:title],
      content: data.to_json,
      parsed_at: Time.now,
      status: 'completed'
    )
  ensure
    # Закрываем соединение с базой данных
    db&.disconnect
  end

  # 6. API для удаленного парсинга
  class << self
    def start_api_server(port = 4567)
      require 'sinatra'
      require 'json'

      set :port, port

      post '/parse' do
        content_type :json
        
        begin
          url = params['url']
          parser = new(url)
          result = parser.parse
          
          { status: 'success', data: result }.to_json
        rescue StandardError => e
          { status: 'error', message: e.message }.to_json
        end
      end

      get '/health' do
        { status: 'ok', timestamp: Time.now }.to_json
      end
    end
  end
end 