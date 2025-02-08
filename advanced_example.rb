require_relative 'html_parser'

# 1. Многопоточный парсинг
urls = [
  'https://www.ruby-lang.org',
  'https://www.ruby-doc.org',
  'https://rubygems.org'
]

parser = HtmlParser.new('')
results = parser.parse_urls_parallel(urls)
puts "=== Параллельный парсинг ==="
results.each { |r| puts "#{r[:url]}: #{r[:status]}" }

# 2. Использование прокси
proxy_parser = HtmlParser.new('https://example.com', {
  host: 'proxy.example.com',
  port: 8080,
  user: 'user',
  password: 'pass'
})

# 3. Парсинг с автоопределением кодировки
puts "\n=== Парсинг с определением кодировки ==="
result = parser.parse_with_encoding

# Пропустим парсинг PDF

# 5. Сохранение в базу данных (закомментируем пока нет базы данных)
=begin
db_config = {
  adapter: 'postgres',
  host: 'localhost',
  database: 'parser_db',
  user: 'user',
  password: 'password'
}

parser.save_to_database(result, db_config)
=end

# 6. Запуск API сервера
if ARGV.include?('--api')
  puts "\n=== Запуск API сервера ==="
  HtmlParser.start_api_server
end 