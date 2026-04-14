-- Расширение программ обучения: поля карточки "Для кого", "Что вы получите", "Формат занятий"
ALTER TABLE education_programs
  ADD COLUMN target_audience MEDIUMTEXT NULL AFTER details,
  ADD COLUMN outcome_text MEDIUMTEXT NULL AFTER target_audience,
  ADD COLUMN format_text MEDIUMTEXT NULL AFTER outcome_text;
