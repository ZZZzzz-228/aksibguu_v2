import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../widgets/centered_app_bar_title.dart';
import 'career_guidance_screen.dart';
import 'document_submission_screen.dart';

String _toAbsoluteUrl(String baseUrl, String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  if (value.startsWith('/')) {
    return '$base$value';
  }
  return '$base/$value';
}

Widget _imageFromPath(
  String baseUrl,
  String path, {
  required BoxFit fit,
  Widget? errorFallback,
}) {
  final p = path.trim();
  if (p.isEmpty) {
    return errorFallback ?? const SizedBox.shrink();
  }
  if (p.startsWith('assets/')) {
    return Image.asset(
      p,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
    );
  }
  return Image.network(
    _toAbsoluteUrl(baseUrl, p),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
  );
}
// ─────────────────────────────────────────────────────────────────────────────
// Избранные специальности ("звёздочка")
// ─────────────────────────────────────────────────────────────────────────────
class FavoriteSpecialtyStore {
  FavoriteSpecialtyStore._();
  static final FavoriteSpecialtyStore instance = FavoriteSpecialtyStore._();
  final ValueNotifier<Set<String>> favorites = ValueNotifier(<String>{});
  bool isFavorite(String id) => favorites.value.contains(id);
  void toggle(String id) {
    final next = Set<String>.from(favorites.value);
    if (next.contains(id)) { next.remove(id); } else { next.add(id); }
    favorites.value = next;
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Модель специальности (добавлены поля: квалификация, карьера, навыки, зарплата)
// ─────────────────────────────────────────────────────────────────────────────
class Specialty {
  final String id;
  final String title;
  final String shortTitle;
  final String code;
  final String description;
  final String duration;
  final String form;
  final IconData icon;
  final Color color;
  final String qualification;
  final String career;
  final String skills;
  final String salary;
  final String imagePath;
  const Specialty({
    required this.id, required this.title, required this.shortTitle,
    required this.code, required this.description, required this.duration,
    required this.form, required this.icon, required this.color,
    required this.qualification, required this.career, required this.skills,
    required this.salary, required this.imagePath,
  });
}
const List<Specialty> specialties = [
  Specialty(
    id: 'Сетевое и системное администрирование', title: 'Сетевое и системное администрирование', shortTitle: 'Сетевое администрирование', code: '09.02.06',
    description: 'Специальность готовит специалистов по установке, настройке и обслуживанию сетевого оборудования, серверов и операционных систем. Выпускники работают системными администраторами, сетевыми инженерами и IT-специалистами.',
    duration: '3 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.lan, color: Color(
      0xFFBE9A03),
    qualification: 'Сетевой и системный администратор',
    career: 'Системный администратор, сетевой инженер, DevOps-инженер, специалист технической поддержки',
    skills: 'Linux/Windows Server, настройка сетей, виртуализация, мониторинг серверов',
    salary: 'от 45 000 ₽', imagePath: 'assets/images/specialties/network_admin.png',
  ),
  Specialty(
    id: 'Информационные системы и программирование', title: 'Информационные системы и программирование', shortTitle: 'ИС и программирование', code: '09.02.07',
    description: 'Обучение разработке программного обеспечения, созданию веб-приложений и информационных систем. Специальность охватывает языки программирования, базы данных, алгоритмы и проектирование ПО.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.code, color: Color(
      0xFF191A1C),
    qualification: 'Программист / Разработчик',
    career: 'Frontend/Backend-разработчик, мобильный разработчик, тестировщик ПО, аналитик',
    skills: 'Python, Java, C#, SQL, HTML/CSS/JS, Git, алгоритмы и структуры данных',
    salary: 'от 60 000 ₽', imagePath: 'assets/images/specialties/programming.png',
  ),
  Specialty(
    id: 'Обеспечение информационной безопасности телекоммуникационных систем', title: 'Обеспечение информационной безопасности телекоммуникационных систем', shortTitle: 'ИБ телекоммуникаций', code: '10.02.03',
    description: 'Специальность по защите информации в телекоммуникационных системах и сетях. Включает криптографию, защиту каналов связи и противодействие сетевым атакам.',
    duration: '2 года 10 месяцев', form: 'Очная', icon: Icons.security, color: Color(0xFF00695C),
    qualification: 'Техник по защите информации',
    career: 'Специалист по ИБ, пентестер, аналитик SOC, администратор средств защиты',
    skills: 'Криптография, сетевая безопасность, анализ угроз, настройка МСЭ и IDS/IPS',
    salary: 'от 55 000 ₽', imagePath: 'assets/images/specialties/ib_telecom.png',
  ),
  Specialty(
    id: 'Обеспечение информационной безопасности автоматизированных систем', title: 'Обеспечение информационной безопасности автоматизированных систем', shortTitle: 'ИБ автоматизированных систем', code: '10.02.04',
    description: 'Подготовка специалистов по защите автоматизированных информационных систем. Студенты изучают методы анализа уязвимостей, управление доступом и аудит безопасности.',
    duration: '2 года 10 месяцев', form: 'Очная', icon: Icons.shield, color: Color(0xFF2E7D32),
    qualification: 'Техник по защите информации',
    career: 'Аудитор информационной безопасности, специалист по защите АСУ ТП, инженер ИБ',
    skills: 'Аудит безопасности, управление доступом, SIEM-системы, анализ уязвимостей',
    salary: 'от 55 000 ₽', imagePath: 'assets/images/specialties/ib_auto.png',
  ),
  Specialty(
    id: 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)', title: 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)', shortTitle: 'Электрооборудование', code: '13.02.11',
    description: 'Специальность по технической эксплуатации и обслуживанию электрического и электромеханического оборудования различных отраслей промышленности.',
    duration: '3 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.electrical_services, color: Color(0xFFF57F17),
    qualification: 'Техник-электромеханик',
    career: 'Электромеханик, наладчик электрооборудования, энергетик предприятия',
    skills: 'Электрические схемы, наладка оборудования, ремонт электродвигателей, ПУЭ',
    salary: 'от 40 000 ₽', imagePath: 'assets/images/specialties/electro.png',
  ),
  Specialty(
    id: 'Специальные машины и устройства', title: 'Специальные машины и устройства', shortTitle: 'Спецмашины и устройства', code: '17.02.12',
    description: 'Обучение проектированию, изготовлению и обслуживанию специальных машин и механизмов для промышленности.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.precision_manufacturing, color: Color(0xFF6A1B9A),
    qualification: 'Техник-механик',
    career: 'Инженер-конструктор, техник по спецмашинам, мастер производственного участка',
    skills: 'Черчение и САПР, обработка металлов, сборка механизмов, контроль качества',
    salary: 'от 42 000 ₽', imagePath: 'assets/images/specialties/special_machines.png',
  ),
  Specialty(
    id: 'Технология машиностроения', title: 'Технология машиностроения', shortTitle: 'Технология машиностроения', code: '15.02.08',
    description: 'Подготовка техников-технологов для машиностроительного производства. Охватывает металлообработку, станочное оборудование и технологические процессы.',
    duration: '3 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.settings, color: Color(0xFF4E342E),
    qualification: 'Техник-технолог',
    career: 'Технолог машиностроительного производства, оператор ЧПУ, мастер цеха',
    skills: 'Программирование ЧПУ, технологические процессы, метрология, чтение чертежей',
    salary: 'от 45 000 ₽', imagePath: 'assets/images/specialties/machining.png',
  ),
  Specialty(
    id: 'Мехатроника и мобильная робототехника (по отраслям)', title: 'Мехатроника и мобильная робототехника (по отраслям)', shortTitle: 'Мехатроника и робототехника', code: '15.02.16',
    description: 'Современная специальность на стыке механики, электроники и программирования. Студенты создают роботизированные системы и мобильные роботы для различных отраслей.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.smart_toy, color: Color(0xFF0277BD),
    qualification: 'Техник-мехатроник',
    career: 'Инженер-робототехник, программист роботов, наладчик автоматизированных линий',
    skills: 'Arduino/Raspberry Pi, программирование контроллеров, 3D-моделирование, сенсоры',
    salary: 'от 50 000 ₽', imagePath: 'assets/images/specialties/mechatronics.png',
  ),
  Specialty(
    id: 'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)', title: 'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)', shortTitle: 'Газонефтепроводы', code: '21.02.03',
    description: 'Специальность по сооружению и эксплуатации трубопроводного транспорта нефти и газа. Подготовка специалистов для нефтегазовой отрасли.',
    duration: '3 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.oil_barrel, color: Color(0xFF558B2F),
    qualification: 'Техник по эксплуатации трубопроводов',
    career: 'Оператор нефтеперекачивающей станции, техник-эксплуатационник, инженер ГНП',
    skills: 'Трубопроводный транспорт, диагностика, сварочные работы, экология',
    salary: 'от 55 000 ₽', imagePath: 'assets/images/specialties/gas_oil.png',
  ),
  Specialty(
    id: 'Сварочное производство', title: 'Сварочное производство', shortTitle: 'Сварочное производство', code: '22.02.06',
    description: 'Подготовка специалистов в области технологии сварочного производства. Обучение современным методам сварки и контроля качества сварных соединений.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.local_fire_department, color: Color(0xFFBF360C),
    qualification: 'Техник-сварщик',
    career: 'Сварщик, инженер-технолог сварочного производства, контролёр качества',
    skills: 'MIG/MAG, TIG, ручная дуговая сварка, дефектоскопия, чтение чертежей',
    salary: 'от 50 000 ₽', imagePath: 'assets/images/specialties/welding.png',
  ),
  Specialty(
    id: 'Техническое обслуживание авиационных двигателей', title: 'Техническое обслуживание авиационных двигателей', shortTitle: 'Авиационные двигатели', code: '25.02.04',
    description: 'Специальность по техническому обслуживанию и ремонту авиационных двигателей. Выпускники работают на авиационных предприятиях и в авиакомпаниях.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.flight, color: Color(
      0xFF37474F),
    qualification: 'Техник по авиационным двигателям',
    career: 'Авиатехник, инженер по ТО двигателей, специалист авиаремонтного завода',
    skills: 'Газотурбинные двигатели, диагностика, авиационные материалы, регламент ТО',
    salary: 'от 55 000 ₽', imagePath: 'assets/images/specialties/aviation.png',
  ),
  Specialty(
    id: 'Контроль работы измерительных приборов', title: 'Контроль работы измерительных приборов', shortTitle: 'Измерительные приборы', code: '12.02.11',
    description: 'Обучение методам контроля, настройки и поверки измерительного оборудования. Специалисты востребованы в промышленности и лабораториях.',
    duration: '2 года 10 месяцев', form: 'Очная', icon: Icons.speed, color: Color(
      0xFF98A9B5),
    qualification: 'Техник-метролог',
    career: 'Метролог, контролёр ОТК, калибровщик, инженер по качеству',
    skills: 'Метрология, поверка приборов, стандартизация, работа с эталонами',
    salary: 'от 40 000 ₽', imagePath: 'assets/images/specialties/metrology.png',
  ),
  Specialty(
    id: 'Электро‑ и теплоэнергетика', title: 'Электро‑ и теплоэнергетика', shortTitle: 'Электро‑ и теплоэнергетика', code: '13.02.02',
    description: 'Подготовка специалистов для энергетической отрасли. Охватывает электрические сети, тепловые установки и системы энергоснабжения.',
    duration: '3 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.bolt, color: Color(0xFFE65100),
    qualification: 'Техник-энергетик',
    career: 'Электромонтёр, энергетик, техник по обслуживанию ТЭЦ, диспетчер энергосистем',
    skills: 'Электрические сети, тепловые установки, релейная защита, энергоаудит',
    salary: 'от 45 000 ₽', imagePath: 'assets/images/specialties/energetics.png',
  ),
  Specialty(
    id: 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', title: 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', shortTitle: 'Аэронавигация', code: '25.02.01',
    description: 'Специальность по эксплуатации авиационной и ракетно-космической техники. Подготовка специалистов для авиационно-космической отрасли.',
    duration: '3 года 10 месяцев', form: 'Очная', icon: Icons.rocket_launch, color: Color(0xFF283593),
    qualification: 'Техник по авиационной и РК технике',
    career: 'Техник аэронавигации, инженер РКТ, специалист космодрома, авиадиспетчер',
    skills: 'Аэродинамика, навигационные системы, радиоэлектроника, ракетные двигатели',
    salary: 'от 55 000 ₽', imagePath: 'assets/images/specialties/aeronavigation.png',
  ),
  Specialty(
    id: 'Экономика и бухгалтерский учет', title: 'Экономика и бухгалтерский учет', shortTitle: 'Экономика и бухучёт', code: '38.02.01',
    description: 'Специальность по экономике, финансам и бухгалтерскому учёту. Выпускники работают бухгалтерами, экономистами и финансовыми аналитиками.',
    duration: '2 года 10 месяцев', form: 'Очная / Заочная', icon: Icons.account_balance_wallet, color: Color(0xFF00796B),
    qualification: 'Бухгалтер / Экономист',
    career: 'Бухгалтер, экономист, аудитор, финансовый аналитик, налоговый консультант',
    skills: '1С:Бухгалтерия, налогообложение, финансовый анализ, Excel, отчётность',
    salary: 'от 35 000 ₽', imagePath: 'assets/images/specialties/economics.png',
  ),
];
// ─────────────────────────────────────────────────────────────────────────────
// Обучение (добавлены поля: для кого, что получите, формат)
// ─────────────────────────────────────────────────────────────────────────────
enum EducationFilter { additional, courses }
enum EducationType { additional, courses }
class EducationProgram {
  final EducationType type;
  final String title;
  final String description;
  final String duration;
  final String details;
  final IconData icon;
  final Color color;
  final String targetAudience;
  final String outcome;
  final String format;
  final String imagePath;
  const EducationProgram({required this.type, required this.title, required this.description, required this.duration, required this.details, required this.icon, required this.color, required this.targetAudience, required this.outcome, required this.format, required this.imagePath});
}
const List<EducationProgram> educationPrograms = [
  EducationProgram(type: EducationType.additional, title: 'Веб-разработка (Full Stack)', description: 'HTML, CSS, JavaScript, React, Node.js — от основ до практики.', duration: '6 месяцев', details: 'Курс охватывает полный стек веб-разработки: вёрстка, стилизация, JavaScript, фреймворки React и Node.js. После завершения курса вы сможете создавать современные веб-приложения и работать как фронтенд, так и бэкенд разработчиком.', icon: Icons.web, color: Color(0xFF1565C0),
    targetAudience: 'Для начинающих и тех, кто хочет сменить профессию на IT',
    outcome: 'Сертификат о доп. образовании, портфолио из 3+ проектов',
    format: 'Очно, 3 раза в неделю по 2 часа', imagePath: 'assets/images/education/web_dev.png',
  ),
  EducationProgram(type: EducationType.additional, title: '1С: Бухгалтерия', description: 'Практический курс по работе с 1С:Бухгалтерия 8.3.', duration: '3 месяца', details: 'Освоите работу в программе 1С:Бухгалтерия 8.3: ввод первичных документов, учёт расчётов с контрагентами, формирование отчётности. Курс предназначен для начинающих бухгалтеров и специалистов по учёту.', icon: Icons.calculate, color: Color(0xFF00695C),
    targetAudience: 'Для начинающих бухгалтеров и экономистов',
    outcome: 'Сертификат 1С:Профессионал, навыки ведения учёта',
    format: 'Очно, 2 раза в неделю по 3 часа', imagePath: 'assets/images/education/accounting.png',
  ),
  EducationProgram(type: EducationType.additional, title: 'AutoCAD для инженеров', description: 'Черчение и проектирование: 2D/3D основы.', duration: '4 месяца', details: 'Научитесь создавать технические чертежи и трёхмерные модели в AutoCAD. Курс включает 2D-черчение, 3D-моделирование, оформление чертежей по ГОСТ.', icon: Icons.design_services, color: Color(0xFF6A1B9A),
    targetAudience: 'Для студентов технических специальностей и инженеров',
    outcome: 'Удостоверение, навыки работы с AutoCAD 2D/3D',
    format: 'Очно, 2 раза в неделю по 2,5 часа', imagePath: 'assets/images/education/autocad.png',
  ),
  EducationProgram(type: EducationType.additional, title: 'Основы кибербезопасности', description: 'Уязвимости, защита инфраструктуры, базовые практики.', duration: '5 месяцев', details: 'Курс знакомит с основными угрозами информационной безопасности, методами защиты сетей и систем, основами криптографии. Вы научитесь выявлять уязвимости и применять инструменты защиты информации.', icon: Icons.lock, color: Color(0xFF2E7D32),
    targetAudience: 'Для студентов IT-направлений и всех интересующихся ИБ',
    outcome: 'Сертификат, базовые навыки пентеста и защиты сетей',
    format: 'Очно, 2 раза в неделю по 2 часа + лабораторные', imagePath: 'assets/images/education/cybersecurity.png',
  ),
  EducationProgram(type: EducationType.courses, title: 'Математика для поступающих', description: 'Алгебра, геометрия, типовые задачи — интенсив.', duration: '2 месяца', details: 'Интенсивная подготовка к поступлению: алгебра, геометрия, тригонометрия, типовые задачи вступительных испытаний. Занятия в малых группах, разбор типичных ошибок.', icon: Icons.functions, color: Color(0xFFF57F17),
    targetAudience: 'Для школьников 9–11 классов, поступающих в колледж',
    outcome: 'Уверенное решение задач вступительных экзаменов',
    format: 'Очно, 3 раза в неделю, группы до 12 человек', imagePath: 'assets/images/education/math.png',
  ),
  EducationProgram(type: EducationType.courses, title: 'Русский язык и изложение', description: 'Орфография, пунктуация, сочинения и изложение.', duration: '2 месяца', details: 'Подготовка по русскому языку: повторение орфографии и пунктуации, практика написания изложений и сочинений. Разбор типовых ошибок и заданий вступительных испытаний.', icon: Icons.menu_book, color: Color(0xFFBF360C),
    targetAudience: 'Для школьников, готовящихся к поступлению',
    outcome: 'Грамотность, уверенное написание изложений и сочинений',
    format: 'Очно, 3 раза в неделю, группы до 10 человек', imagePath: 'assets/images/education/russian.png',
  ),
  EducationProgram(type: EducationType.courses, title: 'Информатика — базовый курс', description: 'Алгоритмы, основы программирования, практика.', duration: '1,5 месяца', details: 'Базовая подготовка по информатике: алгоритмы и основы программирования, работа с офисными программами, устройство компьютера.', icon: Icons.computer, color: Color(0xFF0277BD),
    targetAudience: 'Для школьников без опыта в программировании',
    outcome: 'Основы алгоритмизации, уверенная работа с ПК',
    format: 'Очно, 2 раза в неделю с практикой на компьютерах', imagePath: 'assets/images/education/informatics.png',
  ),
  EducationProgram(type: EducationType.courses, title: 'Физика для технических специальностей', description: 'Механика, электричество, термодинамика — подготовка.', duration: '2 месяца', details: 'Подготовительный курс по физике: механика, молекулярная физика, электричество и магнетизм, оптика. Разбор задач вступительных испытаний и практические лабораторные работы.', icon: Icons.science, color: Color(0xFF37474F),
    targetAudience: 'Для школьников, поступающих на технические специальности',
    outcome: 'Уверенное решение задач по физике, понимание основ',
    format: 'Очно, 2 раза в неделю + лабораторные работы', imagePath: 'assets/images/education/physics.png',
  ),
];

String _educationProgramTypeLabel(EducationType t) {
  switch (t) {
    case EducationType.additional:
      return 'Доп. образование';
    case EducationType.courses:
      return 'Курсы';
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Мероприятия (истории)
// ─────────────────────────────────────────────────────────────────────────────
class StoryData {
  final String title;
  final String content;
  final Color color;
  final String imagePath;
  final String date;
  final String time;
  final String location;
  final String schedule;
  StoryData({required this.title, required this.content, required this.color, required this.imagePath, required this.date, required this.time, required this.location, required this.schedule});
}
final List<StoryData> applicantStories = [
  StoryData(
    title: 'День открытых дверей',
    content: 'Приглашаем школьников и родителей на экскурсии по учебным корпусам и лабораториям. Презентации всех 15 специальностей, живое общение с преподавателями и студентами, ответы на вопросы о поступлении.',
    color: Colors.blue,
    imagePath: 'assets/images/stories/story1.jpg',
    date: '15 апреля 2025',
    time: '10:00 – 14:00',
    location: 'Главный корпус, ул. Красноярский рабочий, 31',
    schedule: '10:00 — Регистрация\n10:30 — Обзорная экскурсия\n11:30 — Презентации специальностей\n13:00 — Ответы на вопросы\n13:30 — Фуршет',
  ),
  StoryData(
    title: 'Олимпиада',
    content: 'Региональная олимпиада для школьников 8–11 классов по информатике, математике и физике. Победители получают дополнительные баллы при поступлении и ценные призы.',
    color: Colors.green,
    imagePath: 'assets/images/stories/story2.jpg',
    date: '20 марта 2025',
    time: '09:00 – 15:00',
    location: 'Корпус №2, компьютерные классы',
    schedule: '09:00 — Регистрация участников\n09:30 — Начало олимпиады\n12:00 — Перерыв\n12:30 — Второй тур\n14:30 — Награждение победителей',
  ),
  StoryData(
    title: 'Мастер-класс',
    content: 'Практические мастер-классы по направлениям: веб-разработка, робототехника, 3D-моделирование, сварочные технологии. Каждый участник попробует себя в реальной работе на профессиональном оборудовании.',
    color: Colors.orange,
    imagePath: 'assets/images/stories/story3.jpg',
    date: '5 мая 2025',
    time: '11:00 – 16:00',
    location: 'Учебные лаборатории, корпус №3',
    schedule: '11:00 — Открытие и распределение по группам\n11:30 — Мастер-класс (сессия 1)\n13:00 — Обед\n13:30 — Мастер-класс (сессия 2)\n15:30 — Подведение итогов',
  ),
  StoryData(
    title: 'Встреча с работодателями',
    content: 'Ведущие партнёры колледжа — КрасМаш, РЕШЕТНЁВ, Россети и другие — расскажут о стажировках, практике и карьерных перспективах. Возможность задать вопросы представителям компаний напрямую.',
    color: Colors.purple,
    imagePath: 'assets/images/stories/story4.jpg',
    date: '25 апреля 2025',
    time: '13:00 – 17:00',
    location: 'Актовый зал, главный корпус',
    schedule: '13:00 — Открытие\n13:30 — Презентации компаний-партнёров\n15:00 — Круглый стол: вопросы и ответы\n16:00 — Индивидуальные консультации\n16:45 — Закрытие',
  ),
  StoryData(
    title: 'Экскурсия в лаборатории',
    content: 'Покажем современное оборудование: робототехнические стенды, авиационный ангар, сварочные мастерские, компьютерные лаборатории. Увидите, где и как проходит обучение наших студентов.',
    color: Colors.red,
    imagePath: 'assets/images/stories/story5.jpg',
    date: '10 апреля 2025',
    time: '12:00 – 15:00',
    location: 'Сбор у главного входа, корпус №1',
    schedule: '12:00 — Сбор группы\n12:15 — IT-лаборатории\n13:00 — Авиационный ангар\n13:45 — Сварочные мастерские\n14:30 — Робототехника\n15:00 — Завершение',
  ),
];
// ─────────────────────────────────────────────────────────────────────────────
// Партнёры
// ─────────────────────────────────────────────────────────────────────────────
class Partner {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String url;
  final String imagePath;
  const Partner({required this.name, required this.description, required this.icon, required this.color, required this.url, required this.imagePath});
}
const List<Partner> partners = [
  Partner(name: 'АО «Красмаш»', description: 'Красноярский машиностроительный завод', icon: Icons.precision_manufacturing, color: Color(0xFF1A237E), url: 'https://www.krskmz.ru/news/news.aspx', imagePath: 'assets/images/partners/krasmash.png'),
  Partner(name: 'АО «РЕШЕТНЁВ»', description: 'Спутниковые системы и космические аппараты', icon: Icons.satellite_alt, color: Color(0xFF00695C), url: 'https://www.iss-reshetnev.ru/', imagePath: 'assets/images/partners/reshetnev.png'),
  Partner(name: 'АО «НПП «Радиосвязь»»', description: 'Высокотехнологичное предприятие связи', icon: Icons.cell_tower, color: Color(0xFFB71C1C), url: 'https://krtz.su/', imagePath: 'assets/images/partners/radiosvyaz.png'),
  Partner(name: 'АО «ОКБ Зенит»', description: 'Опытно-конструкторское бюро', icon: Icons.rocket_launch, color: Color(0xFF1565C0), url: 'https://www.zenith.ru/', imagePath: 'assets/images/partners/zenith.png'),
  Partner(name: 'АО «ЦКБ «Геофизика»»', description: 'Центральное конструкторское бюро', icon: Icons.public, color: Color(0xFF2E7D32), url: 'https://www.geockb.ru/', imagePath: 'assets/images/partners/geofizika.png'),
  Partner(name: 'ООО «КРАМЗ»', description: 'Красноярский алюминиево-металлургический завод', icon: Icons.factory, color: Color(0xFF4E342E), url: 'https://www.aluminas.ru/association/the-registry/kramz/', imagePath: 'assets/images/partners/kramz.png'),
  Partner(name: 'ФГУП «ГХК»', description: 'Горно-химический комбинат', icon: Icons.science, color: Color(0xFFE65100), url: 'https://sibghk.ru/', imagePath: 'assets/images/partners/ghk.png'),
  Partner(name: 'ООО «РН-Ванкор»', description: 'Нефтегазодобывающее предприятие', icon: Icons.oil_barrel, color: Color(0xFF00796B), url: 'https://vankorneft.orgs.biz/', imagePath: 'assets/images/partners/vankor.png'),
  Partner(name: 'ПАО «Россети»', description: 'Электросетевая компания России', icon: Icons.bolt, color: Color(0xFF006064), url: 'https://www.rosseti.ru/', imagePath: 'assets/images/partners/rosseti.png'),
  Partner(name: 'ООО «МегаВатт»', description: 'Энергетическая компания', icon: Icons.electric_bolt, color: Color(0xFFF57F17), url: 'https://mw-power.ru/company/', imagePath: 'assets/images/partners/megavatt.png'),
  Partner(name: 'ООО «Про Ток»', description: 'Электротехническая компания', icon: Icons.electrical_services, color: Color(0xFF6A1B9A), url: 'https://pro-tok.pro/', imagePath: 'assets/images/partners/protok.png'),
  Partner(name: 'ООО «Апогей-БК»', description: 'Инженерная компания', icon: Icons.engineering, color: Color(0xFF0277BD), url: 'https://apogey.ru/', imagePath: 'assets/images/partners/apogey.png'),
  Partner(name: 'ООО «АэроГЕО»', description: 'Аэрогеодезические работы', icon: Icons.flight, color: Color(0xFF283593), url: 'https://www.ag24.ru/', imagePath: 'assets/images/partners/aerogeo.png'),
  Partner(name: 'ООО «Форсайт»', description: 'IT и аналитические решения', icon: Icons.analytics, color: Color(0xFF00897B), url: 'https://www.fsight.ru/', imagePath: 'assets/images/partners/forsight.png'),
  Partner(name: 'АО «Енисейское речное пароходство»', description: 'Речной транспорт и логистика', icon: Icons.directions_boat, color: Color(0xFF1565C0), url: 'https://www.e-river.ru/', imagePath: 'assets/images/partners/erp.png'),
  Partner(name: 'ООО «Аэропорт Емельяново»', description: 'Международный аэропорт Красноярска', icon: Icons.local_airport, color: Color(0xFF00838F), url: 'https://www.kja.aero/', imagePath: 'assets/images/partners/emelyanov.png'),
  Partner(name: 'АО «ТК «РусГидро»»', description: 'Гидроэнергетическая компания', icon: Icons.water, color: Color(0xFF1976D2), url: 'https://tk.rushydro.ru/activity/', imagePath: 'assets/images/partners/rushydro.png'),
  Partner(name: 'ОКБ «Микрон»', description: 'Опытно-конструкторское бюро микроэлектроники', icon: Icons.memory, color: Color(0xFF0D47A1), url: 'https://okbmikron.ru/', imagePath: 'assets/images/partners/mikron.png'),
];
// ─────────────────────────────────────────────────────────────────────────────
// Экран «Абитуриенту»
// ─────────────────────────────────────────────────────────────────────────────
class AboutCollegeScreen extends StatefulWidget {
  const AboutCollegeScreen({super.key});
  @override
  State<AboutCollegeScreen> createState() => _AboutCollegeScreenState();
}
class _AboutCollegeScreenState extends State<AboutCollegeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showMainTitle = false;
  final Set<int> _viewedStories = {};
  final PageController _specialtyController = PageController(viewportFraction: 0.86, initialPage: 0);
  int _currentSpecialtyPage = 0;
  EducationFilter _educationFilter = EducationFilter.additional;
  final PageController _educationController = PageController(viewportFraction: 0.86, initialPage: 0);
  int _currentEducationPage = 0;
  final ApiClient _api = AppSession.apiClient;
  PageContentItem? _cmsAboutCollege;
  List<Specialty> _specialtiesUi = specialties;
  List<Partner> _partnersUi = partners;

  Future<void> _loadCms() async {
    try {
      final page = await _api.fetchPageBySlug('about-college');
      final cmsSpecialties = await _api.fetchSpecialties();
      final cmsPartners = await _api.fetchPartners();

      final specByCode = <String, SpecialtyItem>{
        for (final s in cmsSpecialties) s.code.trim(): s,
      };

      final mergedSpecialties = specialties.map((s) {
        final cms = specByCode[s.code.trim()];
        if (cms == null) return s;
        return Specialty(
          id: s.id,
          title: cms.title.isNotEmpty ? cms.title : s.title,
          shortTitle: s.shortTitle,
          code: s.code,
          description: cms.description.isNotEmpty ? cms.description : s.description,
          duration: s.duration,
          form: s.form,
          icon: s.icon,
          color: s.color,
          qualification: s.qualification,
          career: s.career,
          skills: s.skills,
          salary: s.salary,
          imagePath: cms.imageUrl.isNotEmpty ? cms.imageUrl : s.imagePath,
        );
      }).toList(growable: false);

      final fallbackByName = <String, Partner>{
        for (final p in partners) p.name.trim(): p,
      };

      const icons = <IconData>[
        Icons.handshake,
        Icons.business,
        Icons.precision_manufacturing,
        Icons.satellite_alt,
        Icons.engineering,
        Icons.public,
      ];
      const colors = <Color>[
        Color(0xFF1A237E),
        Color(0xFF00695C),
        Color(0xFF1565C0),
        Color(0xFF2E7D32),
        Color(0xFFE65100),
        Color(0xFF283593),
      ];

      final mergedPartners = cmsPartners.isEmpty
          ? partners
          : cmsPartners.asMap().entries.map((e) {
              final i = e.key;
              final cms = e.value;
              final fb = fallbackByName[cms.name.trim()];
              return Partner(
                name: cms.name.isNotEmpty ? cms.name : (fb?.name ?? 'Партнер'),
                description: cms.description.isNotEmpty ? cms.description : (fb?.description ?? ''),
                icon: fb?.icon ?? icons[i % icons.length],
                color: fb?.color ?? colors[i % colors.length],
                url: cms.websiteUrl.isNotEmpty ? cms.websiteUrl : (fb?.url ?? ''),
                imagePath: cms.logoUrl.isNotEmpty ? cms.logoUrl : (fb?.imagePath ?? ''),
              );
            }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _cmsAboutCollege = page;
        _specialtiesUi = mergedSpecialties;
        _partnersUi = mergedPartners;
      });
    } catch (_) {
      // fallback: keep static data
    }
  }
  List<EducationProgram> get _filteredEducationPrograms {
    final type = _educationFilter == EducationFilter.additional ? EducationType.additional : EducationType.courses;
    return educationPrograms.where((p) => p.type == type).toList();
  }
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadCms());
  }
  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showMainTitle) setState(() => _showMainTitle = shouldShow);
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _specialtyController.dispose();
    _educationController.dispose();
    super.dispose();
  }
  bool _isViewed(int index) => _viewedStories.contains(index);
  void _markAsViewed(int index) => setState(() => _viewedStories.add(index));
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final horizontalPadding = isLargeScreen ? 24.0 : 16.0;
    final storyHeight = isSmallScreen ? 150.0 : (isLargeScreen ? 220.0 : 180.0);
    final buttonHeight = isSmallScreen ? 80.0 : (isLargeScreen ? 120.0 : 100.0);
    final cardHeight = isSmallScreen ? 180.0 : (isLargeScreen ? 240.0 : 200.0);
    final partnerCrossAxisCount = isLargeScreen ? 4 : (isSmallScreen ? 2 : 3);
    final partnerAspectRatio = isSmallScreen ? 0.85 : 0.75;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final buttonIconSize = isSmallScreen ? 26.0 : 32.0;
    final buttonFontSize = isSmallScreen ? 11.0 : 13.0;
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true, floating: false, snap: false,
                  elevation: 0, scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 74,
                  flexibleSpace: _FrostedHeader(showCenterTitle: _showMainTitle),
                ),
              ];
            },
            body: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              children: [
                // ── 1) ИСТОРИИ ────────────────────────────────────────────────
                SizedBox(
                  height: storyHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: applicantStories.length,
                    itemBuilder: (context, index) {
                      return _buildStoryItem(context, index, applicantStories[index]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                // ── 2) КНОПКИ ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerGuidanceScreen())),
                        child: Container(
                          height: buttonHeight, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.explore, size: buttonIconSize, color: const Color(0xFF4A90E2)),
                            const SizedBox(height: 8),
                            Text('Профориентация', textAlign: TextAlign.center, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollegeInfoScreen())),
                        child: Container(
                          height: buttonHeight, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.school, size: buttonIconSize, color: const Color(0xFF4A90E2)),
                            const SizedBox(height: 8),
                            Text('О колледже', textAlign: TextAlign.center, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // ── 3) СПЕЦИАЛЬНОСТИ ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Специальности',
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSpecialtiesScreen(
                              specialties: _specialtiesUi,
                            ),
                          ),
                        );
                      },
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoriteSpecialtyStore.instance.favorites,
                  builder: (context, favorites, _) {
                    final list = _specialtiesUi;
                    return Column(
                      children: [
                        SizedBox(
                          height: cardHeight,
                          child: PageView.builder(
                            controller: _specialtyController,
                            padEnds: false,
                            itemCount: list.length,
                            onPageChanged: (i) => setState(() => _currentSpecialtyPage = i),
                            itemBuilder: (context, index) {
                              final spec = list[index];
                              return _SpecialtyCard(
                                specialty: spec,
                                isFavorite: favorites.contains(spec.id),
                                onToggleFavorite: () => FavoriteSpecialtyStore.instance.toggle(spec.id),
                                onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialtyDetailScreen(specialty: spec))),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(list.length, (i) {
                            final active = i == _currentSpecialtyPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 18 : 6, height: 6,
                              decoration: BoxDecoration(color: active ? const Color(0xFF4A90E2) : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                            );
                          }),
                        ),
                        // Кнопка «Подать документы» — появляется когда есть избранные
                        if (favorites.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DocumentSubmissionScreen(initialSpecialties: favorites.toList()),
                              )),
                              icon: const Icon(Icons.description_outlined),
                              label: Text('Подать документы (${favorites.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                // ── 4) ОБУЧЕНИЕ ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Обучение',
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllEducationProgramsScreen(programs: educationPrograms),
                          ),
                        );
                      },
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Доп. образование'),
                      selected: _educationFilter == EducationFilter.additional,
                      onSelected: (v) { if (!v) return; setState(() { _educationFilter = EducationFilter.additional; _currentEducationPage = 0; }); _educationController.jumpToPage(0); },
                      selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                      labelStyle: TextStyle(color: _educationFilter == EducationFilter.additional ? const Color(0xFF4A90E2) : Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Курсы'),
                      selected: _educationFilter == EducationFilter.courses,
                      onSelected: (v) { if (!v) return; setState(() { _educationFilter = EducationFilter.courses; _currentEducationPage = 0; }); _educationController.jumpToPage(0); },
                      selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                      labelStyle: TextStyle(color: _educationFilter == EducationFilter.courses ? const Color(0xFF4A90E2) : Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final list = _filteredEducationPrograms;
                  return Column(children: [
                    SizedBox(
                      height: cardHeight,
                      child: PageView.builder(
                        controller: _educationController,
                        padEnds: false,
                        itemCount: list.length,
                        onPageChanged: (i) => setState(() => _currentEducationPage = i),
                        itemBuilder: (context, index) => _EducationCard(program: list[index]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(list.length, (i) {
                        final active = i == _currentEducationPage;
                        return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3), width: active ? 18 : 6, height: 6, decoration: BoxDecoration(color: active ? const Color(0xFF4A90E2) : Colors.grey[300], borderRadius: BorderRadius.circular(3)));
                      }),
                    ),
                  ]);
                }),
                const SizedBox(height: 28),
                // ── 5) ПАРТНЁРЫ ───────────────────────────────────────────────
                Text('Партнёры', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: partnerCrossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: partnerAspectRatio),
                  itemCount: _partnersUi.length,
                  itemBuilder: (context, i) => _buildPartnerCard(_partnersUi[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStoryItem(BuildContext context, int index, StoryData story) {
    final bool isViewed = _isViewed(index);
    final sw = MediaQuery.of(context).size.width;
    final storyItemWidth = sw < 360 ? 100.0 : (sw > 600 ? 150.0 : 120.0);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(initialIndex: index, stories: applicantStories)));
        _markAsViewed(index);
      },
      child: Container(
        width: storyItemWidth, margin: const EdgeInsets.only(right: 12),
        child: Container(
          width: storyItemWidth, height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isViewed ? Colors.grey : story.color, width: 3)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(children: [
              Image.asset(story.imagePath, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)))),
              Align(alignment: Alignment.bottomCenter, child: Container(height: 60, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
              Align(alignment: Alignment.bottomLeft, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }
  Widget _buildPartnerCard(Partner p) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(p.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _imageFromPath(
                baseUrl,
                p.imagePath,
                fit: BoxFit.cover,
                errorFallback: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: p.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(p.icon, color: p.color, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 4),
          Text(p.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.3)),
        ]),
      ),
    );
  }
}

class AllSpecialtiesScreen extends StatefulWidget {
  const AllSpecialtiesScreen({super.key, required this.specialties});

  final List<Specialty> specialties;

  @override
  State<AllSpecialtiesScreen> createState() => _AllSpecialtiesScreenState();
}

class _AllSpecialtiesScreenState extends State<AllSpecialtiesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showScrolledTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 10;
    if (show != _showScrolledTitle) {
      setState(() => _showScrolledTitle = show);
    }
  }

  List<Specialty> _filteredSpecialties() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.specialties;
    bool matches(Specialty s) {
      return s.title.toLowerCase().contains(q) ||
          s.shortTitle.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.form.toLowerCase().contains(q) ||
          s.duration.toLowerCase().contains(q) ||
          s.qualification.toLowerCase().contains(q) ||
          s.career.toLowerCase().contains(q) ||
          s.skills.toLowerCase().contains(q) ||
          s.salary.toLowerCase().contains(q);
    }

    return widget.specialties.where(matches).toList(growable: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    final filtered = _filteredSpecialties();
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: _FrostedPushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: 'Все специальности',
                alwaysShowTitle: true,
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Поиск по названию, коду, описанию…',
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black45),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    widget.specialties.isEmpty
                        ? 'Список специальностей пуст'
                        : 'Ничего не найдено — попробуйте другой запрос',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...List.generate(filtered.length, (index) {
                final spec = filtered[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: _AllSpecialtiesRectCard(
                    specialty: spec,
                    baseUrl: baseUrl,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpecialtyDetailScreen(specialty: spec),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Прямоугольная карточка специальности: слева фото, справа текст.
class _AllSpecialtiesRectCard extends StatelessWidget {
  const _AllSpecialtiesRectCard({
    required this.specialty,
    required this.baseUrl,
    required this.onTap,
  });

  final Specialty specialty;
  final String baseUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageFromPath(
                          baseUrl,
                          specialty.imagePath,
                          fit: BoxFit.cover,
                          errorFallback: ColoredBox(color: specialty.color.withOpacity(0.35)),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            specialty.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: specialty.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              specialty.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: specialty.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  specialty.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  specialty.form,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AllEducationKindFilter { all, additional, courses }

class AllEducationProgramsScreen extends StatefulWidget {
  const AllEducationProgramsScreen({super.key, required this.programs});

  final List<EducationProgram> programs;

  @override
  State<AllEducationProgramsScreen> createState() => _AllEducationProgramsScreenState();
}

class _AllEducationProgramsScreenState extends State<AllEducationProgramsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showScrolledTitle = false;
  _AllEducationKindFilter _kindFilter = _AllEducationKindFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 10;
    if (show != _showScrolledTitle) {
      setState(() => _showScrolledTitle = show);
    }
  }

  List<EducationProgram> _visiblePrograms() {
    Iterable<EducationProgram> list = widget.programs;
    switch (_kindFilter) {
      case _AllEducationKindFilter.additional:
        list = list.where((p) => p.type == EducationType.additional);
        break;
      case _AllEducationKindFilter.courses:
        list = list.where((p) => p.type == EducationType.courses);
        break;
      case _AllEducationKindFilter.all:
        break;
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return list.toList(growable: false);
    }
    return list.where((p) {
      final typeLabel = _educationProgramTypeLabel(p.type).toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.duration.toLowerCase().contains(q) ||
          p.details.toLowerCase().contains(q) ||
          p.targetAudience.toLowerCase().contains(q) ||
          p.outcome.toLowerCase().contains(q) ||
          p.format.toLowerCase().contains(q) ||
          typeLabel.contains(q);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    final filtered = _visiblePrograms();
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: _FrostedPushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: 'Все обучения',
                alwaysShowTitle: true,
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Поиск по названию, описанию, формату…',
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black45),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _kindFilter == _AllEducationKindFilter.all,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = _AllEducationKindFilter.all);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == _AllEducationKindFilter.all ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Доп. образование'),
                  selected: _kindFilter == _AllEducationKindFilter.additional,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = _AllEducationKindFilter.additional);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == _AllEducationKindFilter.additional ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Курсы'),
                  selected: _kindFilter == _AllEducationKindFilter.courses,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = _AllEducationKindFilter.courses);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == _AllEducationKindFilter.courses ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    widget.programs.isEmpty
                        ? 'Список программ пуст'
                        : 'Ничего не найдено — смените фильтр или запрос',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...List.generate(filtered.length, (index) {
                final program = filtered[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: _AllEducationRectCard(
                    program: program,
                    baseUrl: baseUrl,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EducationDetailScreen(program: program),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AllEducationRectCard extends StatelessWidget {
  const _AllEducationRectCard({
    required this.program,
    required this.baseUrl,
    required this.onTap,
  });

  final EducationProgram program;
  final String baseUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = _educationProgramTypeLabel(program.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageFromPath(
                          baseUrl,
                          program.imagePath,
                          fit: BoxFit.cover,
                          errorFallback: ColoredBox(color: program.color.withOpacity(0.35)),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            program.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: program.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: program.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  program.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_list_bulleted, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  program.format,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted header: при скролле иконка и «Центр карьеры» полностью исчезают,
// «Главная» плавно появляется по центру.
// ─────────────────────────────────────────────────────────────────────────────
class _FrostedHeader extends StatelessWidget {
  final bool showCenterTitle;
  const _FrostedHeader({required this.showCenterTitle});
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Матовый фон — появляется плавно
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showCenterTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          // «Центр карьеры» — исчезает при скролле
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 0 : 1,
                  child: const CenteredAppBarTitle(),
                ),
              ),
            ),
          ),
          // «Главная» — плавно появляется по центру при скролле
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    offset: showCenterTitle ? Offset.zero : const Offset(0, -0.15),
                    child: const Text('Главная', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Карточка специальности (добавлена форма обучения в нижнюю строку)
// ─────────────────────────────────────────────────────────────────────────────
class _SpecialtyCard extends StatelessWidget {
  final Specialty specialty;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  const _SpecialtyCard({required this.specialty, required this.isFavorite, required this.onToggleFavorite, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Stack(children: [
          Container(
            decoration: BoxDecoration(color: specialty.color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: specialty.color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [
                // Фоновая картинка специальности
                Positioned.fill(
                  child: _imageFromPath(
                    baseUrl,
                    specialty.imagePath,
                    fit: BoxFit.cover,
                    errorFallback: Container(color: specialty.color),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.28)),
                ),
                Padding(
                  // Правый отступ увеличен, чтобы код НЕ заходил под звёздочку
                  padding: const EdgeInsets.fromLTRB(18, 18, 60, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(specialty.icon, color: Colors.white, size: 26)),
                        const SizedBox(width: 10),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(specialty.code, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                      ]),
                      const Spacer(),
                      Text(specialty.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(specialty.duration, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.school, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Expanded(child: Text(specialty.form, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleFavorite, borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.35))),
                  child: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? const Color(0xFFFFD54F) : Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Карточка обучения (добавлена целевая аудитория в нижнюю строку)
// ─────────────────────────────────────────────────────────────────────────────
class _EducationCard extends StatelessWidget {
  final EducationProgram program;
  const _EducationCard({required this.program});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationDetailScreen(program: program))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(program.imagePath, width: 52, height: 52, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: program.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(program.icon, color: program.color, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(program.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 4),
              Text(program.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              const SizedBox(height: 4),
              Text(program.targetAudience, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: program.color.withOpacity(0.8), fontStyle: FontStyle.italic)),
              const Spacer(),
              Row(children: [
                Icon(Icons.timer_outlined, size: 14, color: program.color),
                const SizedBox(width: 4),
                Text(program.duration, style: TextStyle(fontSize: 12, color: program.color, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Подробнее →', style: TextStyle(fontSize: 11, color: program.color, fontWeight: FontWeight.w600)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Экран деталей программы обучения (добавлены секции: Для кого, Что вы получите, Формат)
// ─────────────────────────────────────────────────────────────────────────────
class EducationDetailScreen extends StatelessWidget {
  final EducationProgram program;
  const EducationDetailScreen({super.key, required this.program});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), title: Text(program.title), backgroundColor: program.color, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset(program.imagePath, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, decoration: BoxDecoration(color: program.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Icon(program.icon, color: program.color, size: 44))))),
          const SizedBox(height: 20),
          Text(program.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: program.color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined, size: 18, color: program.color),
              const SizedBox(width: 6),
              Text('Срок обучения: ${program.duration}', style: TextStyle(fontSize: 14, color: program.color, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('О программе', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(program.details, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
          const SizedBox(height: 20),
          // Для кого
          _buildDetailSection(Icons.people_outline, 'Для кого', program.targetAudience, program.color),
          const SizedBox(height: 12),
          // Что вы получите
          _buildDetailSection(Icons.emoji_events_outlined, 'Что вы получите', program.outcome, program.color),
          const SizedBox(height: 12),
          // Формат занятий
          _buildDetailSection(Icons.calendar_today_outlined, 'Формат занятий', program.format, program.color),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EnrollmentFormScreen(programTitle: program.title, programColor: program.color)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: program.color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: const Text('Записаться', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
  Widget _buildDetailSection(IconData icon, String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          ])),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Экран деталей специальности (добавлены: квалификация, карьера, навыки, зарплата)
// ─────────────────────────────────────────────────────────────────────────────
class SpecialtyDetailScreen extends StatelessWidget {
  final Specialty specialty;
  const SpecialtyDetailScreen({super.key, required this.specialty});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true, backgroundColor: specialty.color,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(background: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [specialty.color, specialty.color.withOpacity(0.72)])),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(specialty.imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox()),
              Container(color: specialty.color.withOpacity(0.45)),
              Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Icon(specialty.icon, color: Colors.white, size: 48)),
              ])),
            ]),
          )),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: specialty.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(specialty.code, style: TextStyle(color: specialty.color, fontSize: 13, fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            Text(specialty.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 16),
            // Квалификация
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: specialty.color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.workspace_premium, color: specialty.color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Квалификация: ${specialty.qualification}', style: TextStyle(fontSize: 13, color: specialty.color, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                Expanded(child: _buildInfoChip(Icons.schedule, 'Срок обучения', specialty.duration, specialty.color)),
                Container(width: 1, height: 48, color: Colors.grey.shade300),
                Expanded(child: _buildInfoChip(Icons.school, 'Форма', specialty.form, specialty.color)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('О специальности', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(specialty.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
            const SizedBox(height: 20),
            // Кем работать
            _buildSpecialtyInfoBlock(Icons.work_outline, 'Кем работать', specialty.career, specialty.color),
            const SizedBox(height: 12),
            // Ключевые навыки
            _buildSpecialtyInfoBlock(Icons.build_outlined, 'Ключевые навыки', specialty.skills, specialty.color),
            const SizedBox(height: 12),
            // Зарплата
            _buildSpecialtyInfoBlock(Icons.payments_outlined, 'Зарплата выпускников', specialty.salary, specialty.color),
            const SizedBox(height: 28),
            ValueListenableBuilder<Set<String>>(
              valueListenable: FavoriteSpecialtyStore.instance.favorites,
              builder: (context, favorites, _) {
                final isFav = favorites.contains(specialty.id);
                return Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                    child: IconButton(onPressed: () => FavoriteSpecialtyStore.instance.toggle(specialty.id), icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? const Color(0xFFFFD54F) : Colors.grey[600]), tooltip: 'Хочу эту специальность'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {
                      // Собираем все избранные специальности + текущую
                      final allFavorites = Set<String>.from(FavoriteSpecialtyStore.instance.favorites.value);
                      allFavorites.add(specialty.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentSubmissionScreen(initialSpecialties: allFavorites.toList())));
                    },
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Подать документы', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: specialty.color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  )),
                ]);
              },
            ),
          ]),
        )),
      ]),
    );
  }
  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
      Icon(icon, color: color, size: 22), const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])), const SizedBox(height: 2),
      Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ]));
  }
  Widget _buildSpecialtyInfoBlock(IconData icon, String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          ])),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Просмотрщик историй — с кнопкой «Подробнее» внизу
// ─────────────────────────────────────────────────────────────────────────────
class StoryViewerScreen extends StatefulWidget {
  final int initialIndex;
  final List<StoryData> stories;
  const StoryViewerScreen({super.key, required this.initialIndex, required this.stories});
  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}
class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  Timer? _timer;
  double _progress = 0.0;
  bool _isPaused = false;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startTimer();
  }
  @override
  void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }
  void _startTimer() {
    _timer?.cancel(); _progress = 0.0;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 0.05 / 5;
        if (_progress >= 1.0) { _progress = 0.0; _nextStory(); }
      });
    });
  }
  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 0.05 / 5;
        if (_progress >= 1.0) { _progress = 0.0; _nextStory(); }
      });
    });
  }
  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() { _currentIndex++; _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); });
      _startTimer();
    } else { Navigator.pop(context); }
  }
  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() { _currentIndex--; _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); });
      _startTimer();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          // Нижние 25% экрана — зона кнопки «Подробнее», не переключаем
          if (details.globalPosition.dy > screenHeight * 0.75) return;
          if (details.globalPosition.dx < screenWidth / 2) { _previousStory(); } else { _nextStory(); }
        },
        onLongPressStart: (_) {
          setState(() => _isPaused = true);
          _timer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _resumeTimer();
        },
        child: Stack(children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => _buildStoryContent(widget.stories[index]),
          ),
          SafeArea(child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: List.generate(widget.stories.length, (i) {
                double value = i < _currentIndex ? 1.0 : (i == _currentIndex ? _progress : 0.0);
                return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 3,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(3)),
                    child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: value, child: Container(height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)))))));
              })),
            ),
            Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 8), child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)))),
          ])),
          // Кнопка «Подробнее» внизу
          Positioned(
            bottom: 40, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventsFeedScreen(
                          stories: widget.stories,
                          initialIndex: _currentIndex,
                        ),
                      ),
                    ).then((_) => _startTimer());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Подробнее', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),),),
        ]),
      ),
    );
  }
  Widget _buildStoryContent(StoryData story) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset(story.imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.black)),
      Container(color: Colors.black.withOpacity(0.55)),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 90, 16, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black)])),
        const SizedBox(height: 10),
        Text(story.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black)])),
        const Spacer(),
        // Дата, время и место на самой истории
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(story.date, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(story.time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(child: Text(story.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
      ]))),
    ]);
  }
}

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<StoryData> stories;
  final int initialIndex;

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  late final ScrollController _scrollController;
  late int _selectedIndex;
  bool _showScrolledTitle = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExt = _scrollController.position.maxScrollExtent;
      final targetOffset = (_selectedIndex * 340.0).clamp(0.0, maxExt);
      _scrollController.jumpTo(targetOffset);
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showScrolledTitle) {
      setState(() => _showScrolledTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: _FrostedPushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: 'Мероприятия',
              ),
            ),
          ];
        },
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
          final story = widget.stories[index];
          final isSelected = index == _selectedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedIndex = index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _imageFromPath(
                            baseUrl,
                            story.imagePath,
                            fit: BoxFit.cover,
                            errorFallback: Container(color: Colors.grey.shade200),
                          ),
                          Container(color: Colors.black.withOpacity(0.15)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(child: Text(story.date, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(child: Text(story.time, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                story.location,
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          story.content,
                          maxLines: isSelected ? 999 : 2,
                          overflow: isSelected ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          const Text('Программа', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.15)),
                            ),
                            child: Text(
                              story.schedule,
                              style: const TextStyle(fontSize: 13, height: 1.55),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            isSelected ? 'Выбрано' : 'Нажмите, чтобы открыть',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF4A90E2) : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

/// Шапка вложенных экранов (мероприятия, все специальности): до скролла — назад и опционально бренд или постоянный [scrolledTitle]; после — матовый фон.
class _FrostedPushedHeader extends StatelessWidget {
  const _FrostedPushedHeader({
    required this.showScrolledTitle,
    required this.onBack,
    required this.scrolledTitle,
    this.showBranding = true,
    this.alwaysShowTitle = false,
  });

  final bool showScrolledTitle;
  final VoidCallback onBack;
  final String scrolledTitle;
  final bool showBranding;
  /// Если true — [scrolledTitle] всегда в шапке (например «Все специальности»); матовый слой по-прежнему только при прокрутке.
  final bool alwaysShowTitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showScrolledTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: onBack,
                    tooltip: 'Назад',
                  ),
                  Expanded(
                    child: alwaysShowTitle
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                scrolledTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: showScrolledTitle ? 0 : 1,
                                child: showBranding ? const CenteredAppBarTitle() : const SizedBox.shrink(),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: showScrolledTitle ? 1 : 0,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 220),
                                  offset: showScrolledTitle ? Offset.zero : const Offset(0, -0.15),
                                  child: Text(
                                    scrolledTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Экран «О колледже» — обогащённая версия
// ─────────────────────────────────────────────────────────────────────────────
class CollegeInfoScreen extends StatefulWidget {
  const CollegeInfoScreen({super.key});

  @override
  State<CollegeInfoScreen> createState() => _CollegeInfoScreenState();
}

class _CollegeInfoScreenState extends State<CollegeInfoScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<PageContentItem?> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _api.fetchPageBySlug('about-college');
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), centerTitle: true, title: const Text('О колледже')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Фото колледжа
          Container(
            width: double.infinity, height: 180,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[300]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<PageContentItem?>(
                future: _pageFuture,
                builder: (context, snapshot) {
                  final page = snapshot.data;
                  final cover = page?.coverImageUrl ?? '';
                  return _imageFromPath(
                    baseUrl,
                    cover.isNotEmpty ? cover : 'assets/images/college/college_building.jpg',
                    fit: BoxFit.cover,
                    errorFallback: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Наша миссия ──
          const Text('Наша миссия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<PageContentItem?>(
            future: _pageFuture,
            builder: (context, snapshot) {
              final page = snapshot.data;
              final lead = (page?.lead ?? '').trim();
              return Text(
                lead.isNotEmpty
                    ? lead
                    : 'Подготовка высококвалифицированных специалистов, готовых к успешной профессиональной деятельности в современных условиях. '
                        'Мы стремимся воспитать не только профессионалов, но и ответственных граждан, способных внести значимый вклад в развитие общества и технологий.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
              );
            },
          ),
          const SizedBox(height: 20),
          // ── О нас ──
          const Text('О нас', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<PageContentItem?>(
            future: _pageFuture,
            builder: (context, snapshot) {
              final page = snapshot.data;
              final body = (page?.body ?? '').trim();
              return Text(
                body.isNotEmpty
                    ? body
                    : 'Аэрокосмический колледж СибГУ им. академика М.Ф. Решетнёва — одно из ведущих учебных заведений среднего профессионального образования в Красноярском крае. '
                        'Колледж является структурным подразделением Сибирского государственного университета науки и технологий и имеет богатую историю подготовки специалистов для авиационно-космической, машиностроительной и IT-отраслей.\n\n'
                        'На протяжении десятилетий наш колледж выпускает квалифицированных техников, программистов, инженеров и экономистов, которые успешно трудоустраиваются на ведущих предприятиях региона и страны. '
                        'Тесное сотрудничество с промышленными партнёрами — ОКБ «Зенит», КрасМаш, АО «РЕШЕТНЁВ» — обеспечивает студентам возможность проходить производственную практику на реальном оборудовании.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
              );
            },
          ),
          const SizedBox(height: 24),
          // ── Колледж в цифрах ──
          const Text('Колледж в цифрах', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(icon: Icons.people, value: '2 500+', label: 'Студентов', color: Color(0xFF4A90E2))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: Icons.auto_stories, value: '15', label: 'Специальностей', color: Color(0xFF66BB6A))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(icon: Icons.emoji_events, value: '60+', label: 'Лет истории', color: Color(0xFFFFA726))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: Icons.business, value: '17', label: 'Партнёра', color: Color(0xFFAB47BC))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(icon: Icons.school, value: '95%', label: 'Трудоустройство', color: Color(0xFF26A69A))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: Icons.groups, value: '150+', label: 'Преподавателей', color: Color(0xFFEF5350))),
          ]),
          const SizedBox(height: 24),
          // ── Почему выбирают нас ──
          const Text('Почему выбирают нас', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _AdvantageItem(icon: Icons.rocket_launch, title: 'Аэрокосмическое наследие', text: 'Уникальные специальности, связанные с авиацией и ракетно-космической техникой, которые есть далеко не в каждом колледже.', color: Color(0xFF283593)),
          const SizedBox(height: 10),
          _AdvantageItem(icon: Icons.computer, title: 'Современные IT-направления', text: 'Программирование, кибербезопасность, системное администрирование — востребованные специальности с высоким спросом на рынке труда.', color: Color(0xFF0288D1)),
          const SizedBox(height: 10),
          _AdvantageItem(icon: Icons.handshake, title: 'Связь с индустрией', text: 'Производственная практика на реальных предприятиях. Наши партнёры — КрасМаш, РЕШЕТНЁВ, ОКБ «Зенит» — берут выпускников на работу.', color: Color(0xFF2E7D32)),
          const SizedBox(height: 10),
          _AdvantageItem(icon: Icons.trending_up, title: 'Карьерный рост', text: 'Центр карьеры помогает с трудоустройством, стажировками и развитием профессиональных навыков ещё во время обучения.', color: Color(0xFFE65100)),
          const SizedBox(height: 24),
          // ── Наши достижения ──
          const Text('Наши достижения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _AchievementCard(icon: Icons.military_tech, title: 'Победители WorldSkills Russia', text: 'Студенты колледжа регулярно занимают призовые места в региональных и национальных чемпионатах WorldSkills по компетенциям «Сетевое администрирование», «Мехатроника» и «Сварочные технологии».', color: Color(0xFFFFA726)),
          const SizedBox(height: 10),
          _AchievementCard(icon: Icons.workspace_premium, title: 'Аккредитация и лицензии', text: 'Все образовательные программы прошли государственную аккредитацию. Выпускники получают дипломы государственного образца, признаваемые по всей России.', color: Color(0xFF4A90E2)),
          const SizedBox(height: 10),
          _AchievementCard(icon: Icons.science, title: 'Научно-техническое творчество', text: 'Ежегодно студенты участвуют в научных конференциях и инженерных конкурсах, представляя проекты по робототехнике, программированию и 3D-моделированию.', color: Color(0xFF66BB6A)),
          const SizedBox(height: 10),
          _AchievementCard(icon: Icons.diversity_3, title: 'Активная студенческая жизнь', text: 'Более 10 кружков и секций: от спортивных команд до IT-клуба и инженерного общества. Регулярные фестивали, соревнования и волонтёрские проекты.', color: Color(0xFFAB47BC)),
          const SizedBox(height: 24),
          // ── Инфраструктура ──
          const Text('Инфраструктура', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Колледж располагает современными учебными корпусами, оснащёнными лабораториями и мастерскими:\n'
                '• Компьютерные классы с лицензионным ПО\n'
                '• Лаборатории робототехники и мехатроники\n'
                '• Сварочные мастерские с современным оборудованием\n'
                '• Лаборатории электротехники и измерительных приборов\n'
                '• Авиационный ангар для практических занятий\n'
                '• Библиотека с электронными ресурсами\n'
                '• Спортивный зал и площадки',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}
// ── Карточка статистики ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700]), textAlign: TextAlign.center),
      ]),
    );
  }
}
// ── Карточка преимущества ──
class _AdvantageItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _AdvantageItem({required this.icon, required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
        ])),
      ]),
    );
  }
}
// ── Карточка достижения ──
class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _AchievementCard({required this.icon, required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
        ])),
      ]),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Экран формы записи на обучение (ФИО, телефон, мессенджер)
// ─────────────────────────────────────────────────────────────────────────────
class EnrollmentFormScreen extends StatefulWidget {
  final String programTitle;
  final Color programColor;
  const EnrollmentFormScreen({super.key, required this.programTitle, required this.programColor});
  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}
class _EnrollmentFormScreenState extends State<EnrollmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messengerController = TextEditingController();
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  int _applicationId = 0;
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messengerController.dispose();
    super.dispose();
  }
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final id = await AppSession.apiClient.submitPublicApplication(
        type: 'courses',
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        payload: {
          'program_title': widget.programTitle,
          'preferred_messenger': _messengerController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _applicationId = id;
        _isSubmitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Запись на обучение'),
        backgroundColor: widget.programColor,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitted ? _buildSuccessView() : _buildFormView(),
    );
  }
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: widget.programColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline, color: widget.programColor, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Заявка отправлена!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'Спасибо за интерес к программе «${widget.programTitle}»!\n\nМы получили вашу заявку и свяжемся с вами в ближайшее время для уточнения деталей и подтверждения записи.\n\nОжидайте звонка или сообщения в выбранном вами мессенджере.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
            ),
            if (_applicationId > 0) ...[
              const SizedBox(height: 10),
              Text('Номер заявки: $_applicationId', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.programColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Вернуться', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.programColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.programColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.school, color: widget.programColor, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Программа: ${widget.programTitle}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.programColor))),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('ФИО', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Введите ваше ФИО',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, введите ФИО';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Телефон', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+7 (___) ___-__-__',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, введите номер телефона';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Мессенджер', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messengerController,
              decoration: InputDecoration(
                hintText: 'Telegram, WhatsApp, Viber и т.д.',
                prefixIcon: const Icon(Icons.chat_outlined),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, укажите мессенджер';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.programColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Отправить заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
