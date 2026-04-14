-- Миграция: добавление полей publish_from и publish_to в таблицу stories
-- Выполнить, если эти поля отсутствуют в таблице

ALTER TABLE stories
ADD COLUMN publish_from DATETIME NULL AFTER is_published,
ADD COLUMN publish_to DATETIME NULL AFTER publish_from;

-- Индексы для производительности
CREATE INDEX idx_stories_publish_from ON stories(publish_from);
CREATE INDEX idx_stories_publish_to ON stories(publish_to);
CREATE INDEX idx_stories_is_published ON stories(is_published);
CREATE INDEX idx_stories_sort_order ON stories(sort_order);