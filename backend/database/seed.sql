INSERT INTO roles (code, name) VALUES
('guest', 'Guest'),
('applicant', 'Applicant'),
('student', 'Student'),
('staff', 'Staff'),
('admin', 'Admin');

INSERT INTO users (full_name, email, phone, password_hash, is_active) VALUES
('Администратор системы', 'admin@aksibgu.local', '+79990000000', '$2y$10$85R93Dq2IuB0rfuHMjHjwuk3S3G5DpcwgR3fuCujn2vPUasfeDgli', 1),
('Контент-менеджер', 'staff.content@aksibgu.local', '+79990000001', '$2y$10$85R93Dq2IuB0rfuHMjHjwuk3S3G5DpcwgR3fuCujn2vPUasfeDgli', 1),
('Редактор новостей', 'staff.news@aksibgu.local', '+79990000002', '$2y$10$85R93Dq2IuB0rfuHMjHjwuk3S3G5DpcwgR3fuCujn2vPUasfeDgli', 1),
('Студент тестовый', 'student@aksibgu.local', '+79990000003', '$2y$10$85R93Dq2IuB0rfuHMjHjwuk3S3G5DpcwgR3fuCujn2vPUasfeDgli', 1),
('Преподаватель тестовый', 'teacher@aksibgu.local', '+79990000004', '$2y$10$85R93Dq2IuB0rfuHMjHjwuk3S3G5DpcwgR3fuCujn2vPUasfeDgli', 1);

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'admin'
WHERE u.email = 'admin@aksibgu.local';

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'staff'
WHERE u.email IN ('staff.content@aksibgu.local', 'staff.news@aksibgu.local');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'student'
WHERE u.email = 'student@aksibgu.local';

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'teacher'
WHERE u.email = 'teacher@aksibgu.local';

INSERT INTO contacts (type, value, label, sort_order, is_active) VALUES
('phone', '+7 (391) 264-06-59', 'Приемная', 1, 1),
('phone', '+7 (391) 264-57-35', 'Учебная часть', 2, 1),
('email', 'ak@sibsau.ru', 'Основной email', 3, 1),
('website', 'https://sibsau.ru', 'Сайт университета', 4, 1),
('website', 'https://abiturient.sibsau.ru', 'Абитуриенту', 5, 1);

INSERT INTO news_items (title, content, image_url, published_at, is_published) VALUES
('В Волгограде наградили победителей «Зарницы 2.0»', 'На Мамаевом кургане состоялась торжественная церемония награждения участников Всероссийского финала.', NULL, NOW(), 1),
('Спортивные мероприятия колледжа', 'Студенты колледжа активно участвуют в спортивных соревнованиях и показывают отличные результаты.', NULL, NOW(), 1);

INSERT INTO vacancies (title, company, city, employment_type, salary, description, published_at, is_active) VALUES
('Младший программист', 'АЭРОКОС Технологии', 'Москва', 'Полная занятость', '80 000 — 120 000 ₽', 'Стартовая позиция для выпускников и студентов.', NOW(), 1),
('Инженер-конструктор', 'АЭРОКОС Технологии', 'Москва', 'Полная занятость', '100 000 — 120 000 ₽', 'Работа в конструкторском отделе.', NOW(), 1);

INSERT INTO staff_members (full_name, position_title, email, phone, office_hours, photo_url, sort_order, is_published) VALUES
('Тимошев Павел Викторович', 'Директор Аэрокосмического колледжа', 'ak@sibsau.ru', '2919115', 'Часы приёма: вторник, четверг с 14:00 до 16:00', NULL, 1, 1),
('Шувалова М.А.', 'Заместитель директора по учебно-методической работе', 'shuvalovav@sibsau.ru', '+7(391) 291-91-15', 'Часы приёма: понедельник, среда с 10:00 до 12:00', NULL, 2, 1);

INSERT INTO specialties (code, title, description, sort_order, is_published) VALUES
('09.02.01', 'Компьютерные системы и комплексы', 'Подготовка специалистов по вычислительным системам.', 1, 1),
('09.02.07', 'Информационные системы и программирование', 'Разработка ПО, мобильных и web-приложений.', 2, 1),
('11.02.16', 'Монтаж и техническое обслуживание электронных приборов', 'Работа с электронной аппаратурой и автоматикой.', 3, 1);

INSERT INTO groups_ref (code, title, curator_staff_id, specialty_id, is_active)
SELECT 'ИСП-1-22', 'Группа ИСП-1-22', s.id, sp.id, 1
FROM staff_members s, specialties sp
WHERE s.sort_order = 1 AND sp.code = '09.02.07'
LIMIT 1;

INSERT INTO partners (name, description, website_url, sort_order, is_published) VALUES
('АО РЕШЕТНЁВ', 'Базовый индустриальный партнер по стажировкам.', 'https://www.iss-reshetnev.ru/', 1, 1),
('Красмаш', 'Партнер по практикам и трудоустройству.', 'https://krasm.com/', 2, 1),
('Россети Сибирь', 'Партнер по инженерным специальностям.', 'https://www.rosseti-sib.ru/', 3, 1);

INSERT INTO media_assets (title, media_type, audience, url, alt_text, sort_order, is_published)
VALUES
('Главный баннер абитуриента', 'image', 'applicant', '/uploads/demo/applicant-hero.jpg', 'Абитуриентам', 1, 1),
('Баннер студентам', 'image', 'student', '/uploads/demo/student-hero.jpg', 'Студентам', 1, 1);

INSERT INTO pages (slug, title, audience, content_json, cover_image_url, is_published)
VALUES
('about-college', 'О колледже', 'applicant', JSON_OBJECT('lead', 'Современный аэрокосмический колледж', 'body', 'Подготовка востребованных специалистов для индустрии.'), '/uploads/demo/about.jpg', 1),
('student-home', 'Главная для студентов', 'student', JSON_OBJECT('lead', 'Личный кабинет студента', 'body', 'Расписание, профиль, портфолио и вакансии.'), '/uploads/demo/student-home.jpg', 1);

INSERT INTO student_profiles (user_id, student_code, group_id, curator_staff_id, birth_date, bio, portfolio_public)
SELECT u.id, 'ST-0001', g.id, g.curator_staff_id, '2006-04-10', 'Студент направления ИСП.', 1
FROM users u
LEFT JOIN groups_ref g ON g.code = 'ИСП-1-22'
WHERE u.email = 'student@aksibgu.local'
LIMIT 1;

INSERT INTO teacher_profiles (user_id, staff_member_id, department, bio)
SELECT u.id, s.id, 'Информационные технологии', 'Преподаватель профильных IT-дисциплин.'
FROM users u
LEFT JOIN staff_members s ON s.sort_order = 2
WHERE u.email = 'teacher@aksibgu.local'
LIMIT 1;

INSERT INTO student_resumes (student_user_id, title, summary, skills_json, experience_json, education_json, is_published)
SELECT u.id, 'Резюме начинающего разработчика', 'Ищу стажировку frontend/backend.', JSON_ARRAY('Dart', 'Flutter', 'PHP', 'MySQL'), JSON_ARRAY(JSON_OBJECT('company', 'Учебный проект', 'role', 'Разработчик', 'period', '2025-2026')), JSON_ARRAY(JSON_OBJECT('institution', 'АК СИБГУ', 'program', 'ИСП', 'year', '2022-2026')), 1
FROM users u
WHERE u.email = 'student@aksibgu.local'
LIMIT 1;

INSERT INTO student_portfolio_items (student_user_id, title, description, project_url, image_url, sort_order, is_published)
SELECT u.id, 'Мобильное приложение колледжа', 'Прототип приложения с API интеграцией.', 'https://github.com/example/college-app', '/uploads/demo/portfolio-1.jpg', 1, 1
FROM users u
WHERE u.email = 'student@aksibgu.local'
LIMIT 1;

INSERT INTO stories (title, content, image_url, sort_order, is_published) VALUES
('Зарница 2.0', 'В Волгограде наградили победителей военно-патриотической игры', NULL, 1, 1),
('Спорт', 'Студенты колледжа заняли первое место в соревнованиях', NULL, 2, 1),
('Новости', 'Открытие новой лаборатории по робототехнике', NULL, 3, 1);
