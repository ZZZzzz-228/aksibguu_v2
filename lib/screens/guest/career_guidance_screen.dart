import 'package:flutter/material.dart';
import 'document_submission_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Модель вопроса теста
// ─────────────────────────────────────────────────────────────────────────────

class _TestQuestion {
  final String question;
  final List<_TestAnswer> answers;
  const _TestQuestion({required this.question, required this.answers});
}

class _TestAnswer {
  final String text;
  final List<String> specialtyIds;
  const _TestAnswer({required this.text, required this.specialtyIds});
}

// ─────────────────────────────────────────────────────────────────────────────
// 15 вопросов профориентации
// ─────────────────────────────────────────────────────────────────────────────

const List<_TestQuestion> _testQuestions = [
  _TestQuestion(
    question: '1. Какой вид деятельности вам ближе всего?',
    answers: [
      _TestAnswer(text: 'Писать код и создавать программы', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Работать с механизмами и техникой', specialtyIds: ['Технология машиностроения', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Анализировать данные и считать финансы', specialtyIds: ['Экономика и бухгалтерский учет', 'Контроль работы измерительных приборов']),
      _TestAnswer(text: 'Защищать информацию и системы', specialtyIds: ['Обеспечение информационной безопасности телекоммуникационных систем', 'Обеспечение информационной безопасности автоматизированных систем']),
    ],
  ),
  _TestQuestion(
    question: '2. Какой предмет в школе вам нравится больше?',
    answers: [
      _TestAnswer(text: 'Информатика', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Физика', specialtyIds: ['Электро‑ и теплоэнергетика', 'Техническое обслуживание авиационных двигателей']),
      _TestAnswer(text: 'Математика', specialtyIds: ['Экономика и бухгалтерский учет', 'Контроль работы измерительных приборов']),
      _TestAnswer(text: 'Технология (труд)', specialtyIds: ['Сварочное производство', 'Технология машиностроения']),
    ],
  ),
  _TestQuestion(
    question: '3. Как вы предпочитаете решать задачи?',
    answers: [
      _TestAnswer(text: 'Логически, через алгоритмы', specialtyIds: ['Информационные системы и программирование', 'Обеспечение информационной безопасности автоматизированных систем']),
      _TestAnswer(text: 'Руками, собирая и разбирая', specialtyIds: ['Мехатроника и мобильная робототехника (по отраслям)', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Командной работой и обсуждением', specialtyIds: ['Экономика и бухгалтерский учет', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Исследуя и экспериментируя', specialtyIds: ['Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', 'Контроль работы измерительных приборов']),
    ],
  ),
  _TestQuestion(
    question: '4. Какая отрасль вас привлекает?',
    answers: [
      _TestAnswer(text: 'IT и компьютерные технологии', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Авиация и космос', specialtyIds: ['Техническое обслуживание авиационных двигателей', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники']),
      _TestAnswer(text: 'Энергетика и электрика', specialtyIds: ['Электро‑ и теплоэнергетика', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
      _TestAnswer(text: 'Нефть и газ', specialtyIds: ['Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)']),
    ],
  ),
  _TestQuestion(
    question: '5. Что вы делаете в свободное время?',
    answers: [
      _TestAnswer(text: 'Программирую или изучаю технологии', specialtyIds: ['Информационные системы и программирование', 'Обеспечение информационной безопасности телекоммуникационных систем']),
      _TestAnswer(text: 'Конструирую модели или роботов', specialtyIds: ['Мехатроника и мобильная робототехника (по отраслям)', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Читаю про экономику и бизнес', specialtyIds: ['Экономика и бухгалтерский учет']),
      _TestAnswer(text: 'Разбираю электронику и технику', specialtyIds: ['Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)', 'Контроль работы измерительных приборов']),
    ],
  ),
  _TestQuestion(
    question: '6. Какое утверждение описывает вас лучше?',
    answers: [
      _TestAnswer(text: 'Мне важна кибербезопасность и защита данных', specialtyIds: ['Обеспечение информационной безопасности телекоммуникационных систем', 'Обеспечение информационной безопасности автоматизированных систем']),
      _TestAnswer(text: 'Мне нравится работать с электрическими схемами', specialtyIds: ['Электро‑ и теплоэнергетика', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
      _TestAnswer(text: 'Я мечтаю о полётах и ракетах', specialtyIds: ['Техническое обслуживание авиационных двигателей', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники']),
      _TestAnswer(text: 'Мне нравится сварка и металлообработка', specialtyIds: ['Сварочное производство', 'Технология машиностроения']),
    ],
  ),
  _TestQuestion(
    question: '7. Какой инструмент вы бы выбрали для работы?',
    answers: [
      _TestAnswer(text: 'Компьютер и IDE', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Сварочный аппарат', specialtyIds: ['Сварочное производство']),
      _TestAnswer(text: 'Мультиметр и осциллограф', specialtyIds: ['Контроль работы измерительных приборов', 'Электро‑ и теплоэнергетика']),
      _TestAnswer(text: 'Токарный или фрезерный станок', specialtyIds: ['Технология машиностроения', 'Специальные машины и устройства']),
    ],
  ),
  _TestQuestion(
    question: '8. Какой результат работы вас мотивирует?',
    answers: [
      _TestAnswer(text: 'Рабочее приложение или сайт', specialtyIds: ['Информационные системы и программирование']),
      _TestAnswer(text: 'Работающий механизм или робот', specialtyIds: ['Мехатроника и мобильная робототехника (по отраслям)', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Безопасная защищённая сеть', specialtyIds: ['Обеспечение информационной безопасности телекоммуникационных систем', 'Обеспечение информационной безопасности автоматизированных систем']),
      _TestAnswer(text: 'Точные расчёты и отчёты', specialtyIds: ['Экономика и бухгалтерский учет', 'Контроль работы измерительных приборов']),
    ],
  ),
  _TestQuestion(
    question: '9. Что для вас важнее в профессии?',
    answers: [
      _TestAnswer(text: 'Высокая зарплата в IT-сфере', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование', 'Обеспечение информационной безопасности автоматизированных систем']),
      _TestAnswer(text: 'Стабильность в промышленности', specialtyIds: ['Технология машиностроения', 'Сварочное производство', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
      _TestAnswer(text: 'Престиж в авиации и космосе', specialtyIds: ['Техническое обслуживание авиационных двигателей', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники']),
      _TestAnswer(text: 'Востребованность в энергетике', specialtyIds: ['Электро‑ и теплоэнергетика', 'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)']),
    ],
  ),
  _TestQuestion(
    question: '10. Как вы относитесь к работе с сетями и серверами?',
    answers: [
      _TestAnswer(text: 'Это моё — люблю настраивать сети', specialtyIds: ['Сетевое и системное администрирование', 'Обеспечение информационной безопасности телекоммуникационных систем']),
      _TestAnswer(text: 'Предпочитаю программировать', specialtyIds: ['Информационные системы и программирование']),
      _TestAnswer(text: 'Мне ближе работа с реальным оборудованием', specialtyIds: ['Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)', 'Мехатроника и мобильная робототехника (по отраслям)']),
      _TestAnswer(text: 'Не моё — предпочитаю другое', specialtyIds: ['Экономика и бухгалтерский учет', 'Сварочное производство']),
    ],
  ),
  _TestQuestion(
    question: '11. Какой тип задач вам интереснее?',
    answers: [
      _TestAnswer(text: 'Настройка и администрирование систем', specialtyIds: ['Сетевое и системное администрирование', 'Обеспечение информационной безопасности автоматизированных систем']),
      _TestAnswer(text: 'Проектирование и изготовление деталей', specialtyIds: ['Технология машиностроения', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Обслуживание авиационной техники', specialtyIds: ['Техническое обслуживание авиационных двигателей', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники']),
      _TestAnswer(text: 'Работа с трубопроводами и хранилищами', specialtyIds: ['Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)']),
    ],
  ),
  _TestQuestion(
    question: '12. Где бы вы хотели работать?',
    answers: [
      _TestAnswer(text: 'В офисе за компьютером', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование', 'Экономика и бухгалтерский учет']),
      _TestAnswer(text: 'В цехе или на производстве', specialtyIds: ['Сварочное производство', 'Технология машиностроения', 'Специальные машины и устройства']),
      _TestAnswer(text: 'На аэродроме или в ангаре', specialtyIds: ['Техническое обслуживание авиационных двигателей', 'Аэронавигация и эксплуатация авиационной и ракетно‑космической техники']),
      _TestAnswer(text: 'На электростанции или трубопроводе', specialtyIds: ['Электро‑ и теплоэнергетика', 'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)']),
    ],
  ),
  _TestQuestion(
    question: '13. Какое качество у вас развито лучше?',
    answers: [
      _TestAnswer(text: 'Аналитическое мышление', specialtyIds: ['Информационные системы и программирование', 'Обеспечение информационной безопасности автоматизированных систем', 'Экономика и бухгалтерский учет']),
      _TestAnswer(text: 'Точность и аккуратность', specialtyIds: ['Контроль работы измерительных приборов', 'Сварочное производство', 'Технология машиностроения']),
      _TestAnswer(text: 'Техническая смекалка', specialtyIds: ['Мехатроника и мобильная робототехника (по отраслям)', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
      _TestAnswer(text: 'Внимательность к деталям', specialtyIds: ['Обеспечение информационной безопасности телекоммуникационных систем', 'Техническое обслуживание авиационных двигателей']),
    ],
  ),
  _TestQuestion(
    question: '14. Какая технология будущего вам интереснее?',
    answers: [
      _TestAnswer(text: 'Искусственный интеллект и Big Data', specialtyIds: ['Информационные системы и программирование', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Робототехника и автоматизация', specialtyIds: ['Мехатроника и мобильная робототехника (по отраслям)', 'Специальные машины и устройства']),
      _TestAnswer(text: 'Космические технологии', specialtyIds: ['Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', 'Техническое обслуживание авиационных двигателей']),
      _TestAnswer(text: 'Возобновляемая энергетика', specialtyIds: ['Электро‑ и теплоэнергетика', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
    ],
  ),
  _TestQuestion(
    question: '15. Выберите занятие на выходные:',
    answers: [
      _TestAnswer(text: 'Участвовать в хакатоне', specialtyIds: ['Информационные системы и программирование', 'Обеспечение информационной безопасности телекоммуникационных систем', 'Сетевое и системное администрирование']),
      _TestAnswer(text: 'Собрать дрон или модель самолёта', specialtyIds: ['Аэронавигация и эксплуатация авиационной и ракетно‑космической техники', 'Мехатроника и мобильная робототехника (по отраслям)']),
      _TestAnswer(text: 'Починить электрику дома', specialtyIds: ['Электро‑ и теплоэнергетика', 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)']),
      _TestAnswer(text: 'Сделать что-то из металла в мастерской', specialtyIds: ['Сварочное производство', 'Технология машиностроения', 'Специальные машины и устройства']),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Экран профориентации — тест из 15 вопросов (ПО ЦЕНТРУ ЭКРАНА)
// ─────────────────────────────────────────────────────────────────────────────

class CareerGuidanceScreen extends StatefulWidget {
  const CareerGuidanceScreen({super.key});

  @override
  State<CareerGuidanceScreen> createState() => _CareerGuidanceScreenState();
}

class _CareerGuidanceScreenState extends State<CareerGuidanceScreen> {
  int _currentQuestion = 0;
  final Map<String, int> _scores = {};
  bool _testFinished = false;
  String _resultSpecialty = '';

  void _answer(_TestAnswer answer) {
    for (final id in answer.specialtyIds) {
      _scores[id] = (_scores[id] ?? 0) + 1;
    }

    if (_currentQuestion < _testQuestions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      String bestId = '';
      int bestScore = 0;
      _scores.forEach((id, score) {
        if (score > bestScore) {
          bestScore = score;
          bestId = id;
        }
      });
      setState(() {
        _testFinished = true;
        _resultSpecialty = bestId;
      });
    }
  }

  void _restartTest() {
    setState(() {
      _currentQuestion = 0;
      _scores.clear();
      _testFinished = false;
      _resultSpecialty = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_testFinished) return _buildResultScreen(context);
    return _buildQuestionScreen(context);
  }

  // ───── ТЕСТ ПО ЦЕНТРУ ЭКРАНА ─────
  Widget _buildQuestionScreen(BuildContext context) {
    final q = _testQuestions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _testQuestions.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.explore, color: Color(0xFF4A90E2)),
            SizedBox(width: 8),
            Text('Профориентация'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Прогресс
                Row(
                  children: [
                    Text(
                      'Вопрос ${_currentQuestion + 1} из ${_testQuestions.length}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A90E2)),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A90E2)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                ),
                const SizedBox(height: 32),

                // Вопрос
                Text(
                  q.question,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Варианты ответов
                ...q.answers.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _answer(a),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          a.text,
                          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.3),
                        ),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context) {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topThree = sorted.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Результат теста'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: Color(0xFF4A90E2), size: 50),
            ),
            const SizedBox(height: 20),

            const Text(
              'Вам подходит:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            Text(
              _resultSpecialty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),

            if (topThree.length > 1) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ваш рейтинг специальностей:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ...topThree.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final maxScore = topThree.first.value;
                final ratio = maxScore > 0 ? item.value / maxScore : 0.0;
                final colors = [
                  const Color(0xFF4A90E2),
                  const Color(0xFF66BB6A),
                  const Color(0xFFFFA726),
                ];
                final color = colors[index % colors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.key,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentSubmissionScreen(
                        initialSpecialties: [_resultSpecialty],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Подать документы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _restartTest,
                icon: const Icon(Icons.refresh),
                label: const Text('Пройти ещё раз', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90E2),
                  side: const BorderSide(color: Color(0xFF4A90E2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
