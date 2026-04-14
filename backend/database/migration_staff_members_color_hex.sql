-- Добавляет поле цвета карточки сотрудника
ALTER TABLE staff_members
  ADD COLUMN color_hex VARCHAR(16) NULL AFTER photo_url;
