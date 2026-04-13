-- Миграция: админ-панель v2 (заявки, логи входа, настройки, закрепление новостей)
-- Выполните в phpMyAdmin по одному блоку при ошибках «Duplicate column».

CREATE TABLE IF NOT EXISTS applications (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  type ENUM('documents','courses') NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(64) NULL,
  specialty_text VARCHAR(512) NULL,
  payload_json JSON NOT NULL,
  status ENUM('new','processing','approved','rejected') NOT NULL DEFAULT 'new',
  rejection_reason TEXT NULL,
  accepted_user_id BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_applications_accepted_user FOREIGN KEY (accepted_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS application_files (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  application_id BIGINT NOT NULL,
  file_url VARCHAR(512) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  mime VARCHAR(120) NULL,
  size_bytes BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_application_files_app FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_applications_status_created ON applications(status, created_at, id);
CREATE INDEX idx_applications_type ON applications(type, created_at, id);

CREATE TABLE IF NOT EXISTS admin_login_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  ip VARCHAR(45) NULL,
  user_agent VARCHAR(512) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_admin_login_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_admin_login_created ON admin_login_log(created_at, id);

CREATE TABLE IF NOT EXISTS site_settings (
  `key` VARCHAR(64) NOT NULL PRIMARY KEY,
  `value` TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Если таблица applications уже была без новых полей — раскомментируйте:
-- ALTER TABLE applications ADD COLUMN specialty_text VARCHAR(512) NULL AFTER phone;
-- ALTER TABLE applications ADD COLUMN rejection_reason TEXT NULL AFTER status;
-- ALTER TABLE applications ADD COLUMN accepted_user_id BIGINT NULL AFTER rejection_reason;
-- ALTER TABLE applications ADD CONSTRAINT fk_applications_accepted_user FOREIGN KEY (accepted_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Закрепление новостей (если колонка уже есть — пропустите этот запрос)
ALTER TABLE news_items ADD COLUMN is_pinned TINYINT(1) NOT NULL DEFAULT 0 AFTER is_published;
