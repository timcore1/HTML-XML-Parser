# Ruby HTML/XML Parser

Мощный и гибкий парсер для извлечения данных из HTML и XML документов, написанный на Ruby.

## 🚀 Возможности

- 📄 **Базовый парсинг**
  - Заголовки страниц
  - Ссылки и их атрибуты
  - Заголовки (h1-h3)
  - Изображения
  - Мета-теги

- 🔍 **Расширенный анализ**
  - Таблицы
  - Формы и поля ввода
  - Списки (ul/ol)
  - Скрипты и стили
  - CSS селекторы

- 📊 **Структурированные данные**
  - JSON-LD
  - Микроданные
  - HTML комментарии
  - iframe элементы

- 🛠 **Технический анализ**
  - Определение фреймворков (jQuery, Bootstrap, React, Vue)
  - Извлечение цветов из CSS
  - Анализ кодировок
  - Поиск email адресов

- ⚡ **Продвинутые функции**
  - Многопоточный парсинг
  - Поддержка прокси
  - Автоопределение кодировки
  - Экспорт в JSON/YAML/CSV
  - Интеграция с БД
  - REST API

## 📦 Установка

Клонирование репозитория

`git clone https://github.com/username/ruby-html-parser.git`
`cd ruby-html-parser`

## Установка зависимостей

`bundle install`


## 🎯 Использование

### Базовый пример

ruby

require_relative 'html_parser'

Создание парсера

parser = HtmlParser.new('https://example.com')

Получение данных

result = parser.parse

puts "Заголовок: #{result[:title]}"


## 📝 Примеры

Смотрите файлы:
- `example.rb` - базовые примеры
- `advanced_example.rb` - продвинутые функции

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/amazing_feature`)
3. Commit изменений (`git commit -m 'Add amazing feature'`)
4. Push в ветку (`git push origin feature/amazing_feature`)
5. Откройте Pull Request

## 📄 Лицензия

MIT License. Подробности в файле [LICENSE](LICENSE)

## 👥 Авторы

- [Mikhail Tarasov]((https://github.com/timcore1))

## 🙏 Благодарности

- [Nokogiri](https://nokogiri.org/) за отличную библиотеку парсинга
- Всем контрибьюторам проекта


## 🔜 Планы развития

- [ ] Поддержка PDF парсинга
- [ ] Интеграция с больше форматами данных
- [ ] Улучшенное кэширование
- [ ] Распределенный парсинг
