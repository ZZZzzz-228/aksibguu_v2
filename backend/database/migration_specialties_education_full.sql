-- Поля для полного редактирования карточек "Специальности"
ALTER TABLE specialties
  ADD COLUMN short_title VARCHAR(255) NULL AFTER title,
  ADD COLUMN duration_label VARCHAR(120) NULL AFTER description,
  ADD COLUMN study_form_label VARCHAR(120) NULL AFTER duration_label,
  ADD COLUMN qualification_text VARCHAR(255) NULL AFTER study_form_label,
  ADD COLUMN career_text MEDIUMTEXT NULL AFTER qualification_text,
  ADD COLUMN skills_text MEDIUMTEXT NULL AFTER career_text,
  ADD COLUMN salary_text VARCHAR(120) NULL AFTER skills_text,
  ADD COLUMN color_hex VARCHAR(16) NULL AFTER icon_name;

-- Карточки "Обучение" (Доп. образование + Подготовительные курсы)
CREATE TABLE IF NOT EXISTS education_programs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  type ENUM('additional', 'courses') NOT NULL,
  title VARCHAR(255) NOT NULL,
  description MEDIUMTEXT NULL,
  duration_label VARCHAR(120) NULL,
  details MEDIUMTEXT NULL,
  icon_name VARCHAR(80) NULL,
  color_hex VARCHAR(16) NULL,
  image_url VARCHAR(512) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  publish_from DATETIME NULL,
  publish_to DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_education_program_type_title (type, title)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_education_programs_published
  ON education_programs(is_published, type, sort_order, id);

INSERT INTO specialties
  (code, title, short_title, description, sort_order, is_published)
VALUES
  ('09.02.06', 'Сетевое и системное администрирование', 'Сетевое администрирование', 'Подготовка специалистов по настройке и сопровождению сетевой инфраструктуры.', 10, 1),
  ('09.02.07', 'Информационные системы и программирование', 'ИС и программирование', 'Разработка информационных систем, web и мобильных приложений.', 20, 1),
  ('10.02.03', 'Обеспечение информационной безопасности телекоммуникационных систем', 'ИБ телекоммуникаций', 'Защита информации в телекоммуникационных системах и сетях.', 30, 1),
  ('10.02.04', 'Обеспечение информационной безопасности автоматизированных систем', 'ИБ автоматизированных систем', 'Защита автоматизированных информационных систем предприятия.', 40, 1),
  ('13.02.11', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)', 'Электрооборудование', 'Подготовка специалистов по эксплуатации электрического оборудования.', 50, 1),
  ('17.02.12', 'Специальные машины и устройства', 'Спецмашины и устройства', 'Проектирование, сборка и обслуживание специальных машин.', 60, 1),
  ('15.02.08', 'Технология машиностроения', 'Технология машиностроения', 'Технологии машиностроительного производства и ЧПУ.', 70, 1),
  ('15.02.16', 'Мехатроника и мобильная робототехника (по отраслям)', 'Мехатроника и робототехника', 'Интеграция механики, электроники и программирования в робототехнике.', 80, 1),
  ('21.02.03', 'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)', 'Газонефтепроводы', 'Эксплуатация и обслуживание трубопроводного транспорта.', 90, 1),
  ('22.02.06', 'Сварочное производство', 'Сварочное производство', 'Технологии сварки и контроль качества сварных соединений.', 100, 1),
  ('25.02.04', 'Техническое обслуживание авиационных двигателей', 'Авиационные двигатели', 'Техническое обслуживание и ремонт авиационных двигателей.', 110, 1),
  ('12.02.11', 'Контроль работы измерительных приборов', 'Измерительные приборы', 'Метрологическое обеспечение и работа с измерительными приборами.', 120, 1),
  ('13.02.02', 'Электро‑ и теплоэнергетика', 'Электро- и теплоэнергетика', 'Эксплуатация энергетических сетей и тепловых установок.', 130, 1),
  ('25.02.05', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', 'Аэронавигация и РКТ', 'Подготовка специалистов авиационно-космической отрасли.', 140, 1),
  ('38.02.01', 'Экономика и бухгалтерский учет', 'Экономика и бухучёт', 'Экономическое сопровождение и бухгалтерский учет организаций.', 150, 1)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  short_title = VALUES(short_title),
  description = VALUES(description),
  sort_order = VALUES(sort_order),
  is_published = VALUES(is_published);

-- Наполнение specialties данными из текущего приложения
UPDATE specialties
SET short_title='Сетевое администрирование',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Сетевой и системный администратор',
    career_text='Системный администратор, сетевой инженер, DevOps-инженер, специалист технической поддержки',
    skills_text='Linux/Windows Server, настройка сетей, виртуализация, мониторинг серверов',
    salary_text='от 45 000 ₽',
    color_hex='#BE9A03',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/network_admin.png')
WHERE code='09.02.06';

UPDATE specialties
SET short_title='ИС и программирование',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Программист / Разработчик',
    career_text='Frontend/Backend-разработчик, мобильный разработчик, тестировщик ПО, аналитик',
    skills_text='Python, Java, C#, SQL, HTML/CSS/JS, Git, алгоритмы и структуры данных',
    salary_text='от 60 000 ₽',
    color_hex='#191A1C',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/programming.png')
WHERE code='09.02.07';

UPDATE specialties
SET short_title='ИБ телекоммуникаций',
    duration_label='2 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник по защите информации',
    career_text='Специалист по ИБ, пентестер, аналитик SOC, администратор средств защиты',
    skills_text='Криптография, сетевая безопасность, анализ угроз, настройка МСЭ и IDS/IPS',
    salary_text='от 55 000 ₽',
    color_hex='#00695C',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/ib_telecom.png')
WHERE code='10.02.03';

UPDATE specialties
SET short_title='ИБ автоматизированных систем',
    duration_label='2 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник по защите информации',
    career_text='Аудитор информационной безопасности, специалист по защите АСУ ТП, инженер ИБ',
    skills_text='Аудит безопасности, управление доступом, SIEM-системы, анализ уязвимостей',
    salary_text='от 55 000 ₽',
    color_hex='#2E7D32',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/ib_auto.png')
WHERE code='10.02.04';

UPDATE specialties
SET short_title='Электрооборудование',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Техник-электромеханик',
    career_text='Электромеханик, наладчик электрооборудования, энергетик предприятия',
    skills_text='Электрические схемы, наладка оборудования, ремонт электродвигателей, ПУЭ',
    salary_text='от 40 000 ₽',
    color_hex='#F57F17',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/electro.png')
WHERE code='13.02.11';

UPDATE specialties
SET short_title='Спецмашины и устройства',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник-механик',
    career_text='Инженер-конструктор, техник по спецмашинам, мастер производственного участка',
    skills_text='Черчение и САПР, обработка металлов, сборка механизмов, контроль качества',
    salary_text='от 42 000 ₽',
    color_hex='#6A1B9A',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/special_machines.png')
WHERE code='17.02.12';

UPDATE specialties
SET short_title='Технология машиностроения',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Техник-технолог',
    career_text='Технолог машиностроительного производства, оператор ЧПУ, мастер цеха',
    skills_text='Программирование ЧПУ, технологические процессы, метрология, чтение чертежей',
    salary_text='от 45 000 ₽',
    color_hex='#4E342E',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/machining.png')
WHERE code='15.02.08';

UPDATE specialties
SET short_title='Мехатроника и робототехника',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник-мехатроник',
    career_text='Инженер-робототехник, программист роботов, наладчик автоматизированных линий',
    skills_text='Arduino/Raspberry Pi, программирование контроллеров, 3D-моделирование, сенсоры',
    salary_text='от 50 000 ₽',
    color_hex='#0277BD',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/mechatronics.png')
WHERE code='15.02.16';

UPDATE specialties
SET short_title='Газонефтепроводы',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Техник по эксплуатации трубопроводов',
    career_text='Оператор нефтеперекачивающей станции, техник-эксплуатационник, инженер ГНП',
    skills_text='Трубопроводный транспорт, диагностика, сварочные работы, экология',
    salary_text='от 55 000 ₽',
    color_hex='#558B2F',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/gas_oil.png')
WHERE code='21.02.03';

UPDATE specialties
SET short_title='Сварочное производство',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник-сварщик',
    career_text='Сварщик, инженер-технолог сварочного производства, контролёр качества',
    skills_text='MIG/MAG, TIG, ручная дуговая сварка, дефектоскопия, чтение чертежей',
    salary_text='от 50 000 ₽',
    color_hex='#BF360C',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/welding.png')
WHERE code='22.02.06';

UPDATE specialties
SET short_title='Авиационные двигатели',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник по авиационным двигателям',
    career_text='Авиатехник, инженер по ТО двигателей, специалист авиаремонтного завода',
    skills_text='Газотурбинные двигатели, диагностика, авиационные материалы, регламент ТО',
    salary_text='от 55 000 ₽',
    color_hex='#37474F',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/aviation.png')
WHERE code='25.02.04';

UPDATE specialties
SET short_title='Измерительные приборы',
    duration_label='2 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник-метролог',
    career_text='Метролог, контролёр ОТК, калибровщик, инженер по качеству',
    skills_text='Метрология, поверка приборов, стандартизация, работа с эталонами',
    salary_text='от 40 000 ₽',
    color_hex='#98A9B5',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/metrology.png')
WHERE code='12.02.11';

UPDATE specialties
SET short_title='Электро- и теплоэнергетика',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Техник-энергетик',
    career_text='Электромонтёр, энергетик, техник по обслуживанию ТЭЦ, диспетчер энергосистем',
    skills_text='Электрические сети, тепловые установки, релейная защита, энергоаудит',
    salary_text='от 45 000 ₽',
    color_hex='#8D6E63',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/energetics.png')
WHERE code='13.02.02';

UPDATE specialties
SET short_title='Аэронавигация и РКТ',
    duration_label='3 года 10 месяцев',
    study_form_label='Очная',
    qualification_text='Техник по авиационной и РК технике',
    career_text='Техник аэронавигации, инженер РКТ, специалист космодрома, авиадиспетчер',
    skills_text='Аэродинамика, навигационные системы, радиоэлектроника, ракетные двигатели',
    salary_text='от 55 000 ₽',
    color_hex='#1565C0',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/aeronavigation.png')
WHERE code='25.02.05';

UPDATE specialties
SET short_title='Экономика и бухучёт',
    duration_label='2 года 10 месяцев',
    study_form_label='Очная / Заочная',
    qualification_text='Бухгалтер / Экономист',
    career_text='Бухгалтер, экономист, аудитор, финансовый аналитик, налоговый консультант',
    skills_text='1С:Бухгалтерия, налогообложение, финансовый анализ, Excel, отчётность',
    salary_text='от 35 000 ₽',
    color_hex='#2E7D32',
    image_url=COALESCE(NULLIF(image_url, ''), 'assets/images/specialties/economics.png')
WHERE code='38.02.01';

INSERT INTO education_programs
  (type, title, description, duration_label, details, icon_name, color_hex, image_url, sort_order, is_published)
VALUES
  ('additional', 'Веб-разработка (Full Stack)', 'HTML, CSS, JavaScript, React, Node.js — от основ до практики.', '6 месяцев', 'Курс охватывает полный стек веб-разработки: вёрстка, стилизация, JavaScript, фреймворки React и Node.js. После завершения курса вы сможете создавать современные веб-приложения и работать как фронтенд, так и бэкенд разработчиком.', 'web', '#1565C0', NULL, 10, 1),
  ('additional', '1С: Бухгалтерия', 'Практический курс по работе с 1С:Бухгалтерия 8.3.', '3 месяца', 'Освоите работу в программе 1С:Бухгалтерия 8.3: ввод первичных документов, учёт расчётов с контрагентами, формирование отчётности. Курс предназначен для начинающих бухгалтеров и специалистов по учёту.', 'calculate', '#00695C', NULL, 20, 1),
  ('additional', 'AutoCAD для инженеров', 'Черчение и проектирование: 2D/3D основы.', '4 месяца', 'Научитесь создавать технические чертежи и трёхмерные модели в AutoCAD. Курс включает 2D-черчение, 3D-моделирование, оформление чертежей по ГОСТ.', 'design_services', '#6A1B9A', NULL, 30, 1),
  ('additional', 'Основы кибербезопасности', 'Уязвимости, защита инфраструктуры, базовые практики.', '5 месяцев', 'Курс знакомит с основными угрозами информационной безопасности, методами защиты сетей и систем, основами криптографии. Вы научитесь выявлять уязвимости и применять инструменты защиты информации.', 'lock', '#2E7D32', NULL, 40, 1),
  ('courses', 'Математика для поступающих', 'Алгебра, геометрия, типовые задачи — интенсив.', '2 месяца', 'Интенсивная подготовка к поступлению: алгебра, геометрия, тригонометрия, типовые задачи вступительных испытаний. Занятия в малых группах, разбор типичных ошибок.', 'functions', '#F57F17', NULL, 50, 1),
  ('courses', 'Русский язык и изложение', 'Орфография, пунктуация, сочинения и изложение.', '2 месяца', 'Подготовка по русскому языку: повторение орфографии и пунктуации, практика написания изложений и сочинений. Разбор типовых ошибок и заданий вступительных испытаний.', 'menu_book', '#BF360C', NULL, 60, 1),
  ('courses', 'Информатика — базовый курс', 'Алгоритмы, основы программирования, практика.', '1,5 месяца', 'Базовая подготовка по информатике: алгоритмы и основы программирования, работа с офисными программами, устройство компьютера.', 'computer', '#0277BD', NULL, 70, 1),
  ('courses', 'Физика для технических специальностей', 'Механика, электричество, термодинамика — подготовка.', '2 месяца', 'Подготовительный курс по физике: механика, молекулярная физика, электричество и магнетизм, оптика. Разбор задач вступительных испытаний и практические лабораторные работы.', 'science', '#37474F', NULL, 80, 1)
ON DUPLICATE KEY UPDATE
  description = VALUES(description),
  duration_label = VALUES(duration_label),
  details = VALUES(details),
  icon_name = VALUES(icon_name),
  color_hex = VALUES(color_hex),
  image_url = VALUES(image_url),
  sort_order = VALUES(sort_order),
  is_published = VALUES(is_published);
