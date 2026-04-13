-- Выполни в phpMyAdmin для базы career_center_ak_sibgu (по одной строке, если колонка уже есть — пропусти ошибку Duplicate).

ALTER TABLE applications ADD COLUMN specialty_text VARCHAR(512) NULL AFTER phone;
ALTER TABLE applications ADD COLUMN rejection_reason TEXT NULL AFTER status;
ALTER TABLE applications ADD COLUMN accepted_user_id BIGINT NULL AFTER rejection_reason;
