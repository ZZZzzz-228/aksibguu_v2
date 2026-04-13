-- Миграция: операционный MVP админки
-- 1) Расширение статуса заявок "archived"
ALTER TABLE applications
  MODIFY status ENUM('new','processing','approved','rejected','archived') NOT NULL DEFAULT 'new';

-- 2) Новые роли для разграничения разделов
INSERT INTO roles(code, name) VALUES
('admissions', 'Admissions office'),
('academic', 'Academic office'),
('content_manager', 'Content manager')
ON DUPLICATE KEY UPDATE name = VALUES(name);

