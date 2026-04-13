-- Миграция: учебная часть (группы/дисциплины/учебные планы)
-- Выполните в phpMyAdmin по одному блоку при ошибках «Duplicate column / table».

-- 1) Расширение академических групп
ALTER TABLE groups_ref
  ADD COLUMN course_year INT NOT NULL DEFAULT 1 AFTER specialty_id;

ALTER TABLE groups_ref
  ADD COLUMN admission_year INT NULL AFTER course_year;

CREATE INDEX idx_groups_specialty_course_active ON groups_ref(specialty_id, course_year, is_active);

-- 2) Справочник дисциплин
CREATE TABLE IF NOT EXISTS disciplines_ref (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_disciplines_active_title ON disciplines_ref(is_active, title, id);

-- 3) Учебные планы: специальность -> семестр(1..8) -> дисциплины
CREATE TABLE IF NOT EXISTS specialty_curriculum (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  specialty_id BIGINT NOT NULL,
  semester TINYINT NOT NULL,
  discipline_id BIGINT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_curriculum (specialty_id, semester, discipline_id),
  CONSTRAINT fk_curriculum_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(id) ON DELETE CASCADE,
  CONSTRAINT fk_curriculum_discipline FOREIGN KEY (discipline_id) REFERENCES disciplines_ref(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_curriculum_specialty_semester_sort ON specialty_curriculum(specialty_id, semester, sort_order, id);

