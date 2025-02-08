require_relative 'html_parser'

# Изменим URL на более содержательный сайт
parser = HtmlParser.new('https://www.ruby-doc.org')

begin
  # Основная информация
  result = parser.parse
  puts "=== ОСНОВНАЯ ИНФОРМАЦИЯ ==="
  puts "Заголовок страницы: #{result[:title]}"
  
  puts "\n=== ССЫЛКИ ==="
  result[:links].first(5).each do |link|
    puts "- #{link[:text]}: #{link[:href]}" unless link[:text].empty?
  end
  
  puts "\n=== ЗАГОЛОВКИ ==="
  result[:headings].each do |heading|
    puts "#{heading[:level]} уровень: #{heading[:text]}"
  end

  puts "\n=== ИЗОБРАЖЕНИЯ ==="
  parser.parse_images.each do |img|
    puts "- #{img[:alt] || 'Без описания'} (#{img[:src]})"
  end

  puts "\n=== МЕТА-ТЕГИ ==="
  parser.parse_meta_tags.each do |meta|
    puts "- #{meta[:name]}: #{meta[:content]}" if meta[:name] && meta[:content]
  end

  puts "\n=== ПАРАГРАФЫ ==="
  paragraphs = parser.search('p')
  paragraphs.first(3).each do |p|
    puts "- #{p[0..100]}..." unless p.strip.empty?
  end

  puts "\n=== ТАБЛИЦЫ ==="
  parser.parse_tables.each_with_index do |table, index|
    puts "Таблица #{index + 1}:"
    puts "Заголовки: #{table[:headers].join(' | ')}"
    table[:data].each do |row|
      puts "Данные: #{row.join(' | ')}"
    end
  end

  puts "\n=== СПИСКИ ==="
  lists = parser.parse_lists
  puts "Маркированные списки:"
  lists[:unordered].each { |list| puts "- #{list.join(', ')}" }
  puts "Нумерованные списки:"
  lists[:ordered].each { |list| puts "- #{list.join(', ')}" }

  puts "\n=== ФОРМЫ ==="
  parser.parse_forms.each do |form|
    puts "Форма: #{form[:action]} (#{form[:method]})"
    form[:inputs].each do |input|
      puts "- Поле: #{input[:name]} (тип: #{input[:type]})"
    end
  end

  puts "\n=== СТИЛИ ==="
  parser.parse_styles.each do |style|
    puts "- #{style[:type]}: #{style[:href]}"
  end

  puts "\n=== ТЕХНОЛОГИИ НА САЙТЕ ==="
  tech = parser.detect_technologies
  tech.each do |name, present|
    puts "- #{name}: #{present ? 'Используется' : 'Не используется'}"
  end

  puts "\n=== EMAIL АДРЕСА ==="
  emails = parser.parse_emails
  emails.each { |email| puts "- #{email}" }

  puts "\n=== ПОИСК С КОНТЕКСТОМ ==="
  results = parser.search_with_context("Ruby")
  results.each { |result| puts "... #{result} ..." }

  puts "\n=== СТРУКТУРИРОВАННЫЕ ДАННЫЕ ==="
  json_ld = parser.parse_json_ld
  puts "JSON-LD данные:" if json_ld.any?
  json_ld.each { |data| puts data }

  puts "\n=== IFRAME ==="
  parser.parse_iframes.each do |iframe|
    puts "- #{iframe[:title]} (#{iframe[:src]})"
  end

  # Сохранение результатов
  parser.save_to_file('parsing_results', :json)
  puts "\nРезультаты сохранены в parsing_results.json"

rescue OpenURI::HTTPError => e
  puts "Ошибка при загрузке страницы: #{e.message}"
rescue StandardError => e
  puts "Произошла ошибка: #{e.message}"
  puts e.backtrace
end 