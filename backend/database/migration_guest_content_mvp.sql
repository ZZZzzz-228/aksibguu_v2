-- Миграция: MVP контента для гостевых экранов
-- Добавляет: окна публикации, ревизии контента, настройки блоков главной.

ALTER TABLE news_items
  ADD COLUMN publish_from DATETIME NULL AFTER published_at;

ALTER TABLE news_items
  ADD COLUMN publish_to DATETIME NULL AFTER publish_from;

ALTER TABLE stories
  ADD COLUMN publish_from DATETIME NULL AFTER sort_order;

ALTER TABLE stories
  ADD COLUMN publish_to DATETIME NULL AFTER publish_from;

ALTER TABLE pages
  ADD COLUMN publish_from DATETIME NULL AFTER is_published;

ALTER TABLE pages
  ADD COLUMN publish_to DATETIME NULL AFTER publish_from;

ALTER TABLE specialties
  ADD COLUMN publish_from DATETIME NULL AFTER is_published;

ALTER TABLE specialties
  ADD COLUMN publish_to DATETIME NULL AFTER publish_from;

CREATE TABLE IF NOT EXISTS content_revisions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  entity_type ENUM('news','page') NOT NULL,
  entity_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content_json JSON NOT NULL,
  created_by BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_content_revisions_user FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_content_revisions_entity ON content_revisions(entity_type, entity_id, id);

INSERT INTO site_settings(`key`, `value`) VALUES
('guest_home_blocks_json', '[{"key":"stories","title":"Истории","enabled":true,"sort_order":0},{"key":"news","title":"Новости","enabled":true,"sort_order":1},{"key":"specialties","title":"Специальности","enabled":true,"sort_order":2},{"key":"career_guidance","title":"Профориентация","enabled":true,"sort_order":3},{"key":"about_college","title":"О колледже","enabled":true,"sort_order":4},{"key":"contacts","title":"Контакты","enabled":true,"sort_order":5}]')
ON DUPLICATE KEY UPDATE `value` = `value`;

