import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import 'document_submission_screen.dart';

String _normTitle(String s) {
  var t = s.trim().toLowerCase();
  t = t
      .replaceAll('\u2011', '-')
      .replaceAll('\u2010', '-')
      .replaceAll('‑', '-')
      .replaceAll('–', '-');
  return t.replaceAll(RegExp(r'\s+'), ' ');
}

String? _matchApiTitle(String ref, List<SpecialtyItem> items) {
  final n = _normTitle(ref);
  for (final it in items) {
    if (_normTitle(it.title) == n) return it.title;
  }
  return null;
}

class CareerGuidanceScreen extends StatefulWidget {
  const CareerGuidanceScreen({super.key});

  @override
  State<CareerGuidanceScreen> createState() => _CareerGuidanceScreenState();
}

class _CareerGuidanceScreenState extends State<CareerGuidanceScreen> {
  List<CareerTestQuestion> _questions = const [];
  List<SpecialtyItem> _specialties = const [];
  bool _loading = true;
  String? _error;

  int _currentQuestion = 0;
  final Map<String, int> _scores = {};
  bool _testFinished = false;
  String _resultSpecialty = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = AppSession.apiClient;
    try {
      final results = await Future.wait([
        api.fetchCareerTest(),
        api.fetchSpecialties(),
      ]);
      final payload = results[0] as CareerTestPayload;
      final specs = results[1] as List<SpecialtyItem>;
      if (!mounted) return;
      setState(() {
        _questions = payload.questions;
        _specialties = specs;
        _loading = false;
        _error = _questions.isEmpty ? 'Тест временно недоступен.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить тест. Проверьте соединение.';
      });
    }
  }

  void _answer(CareerTestAnswer answer) {
    for (final ref in answer.specialtyTitles) {
      final key = _matchApiTitle(ref, _specialties) ?? ref;
      _scores[key] = (_scores[key] ?? 0) + 1;
    }

    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      String bestId = '';
      var bestScore = 0;
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Профориентация'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Профориентация'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Нет вопросов.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ),
        ),
      );
    }
    if (_testFinished) return _buildResultScreen(context);
    return _buildQuestionScreen(context);
  }

  Widget _buildQuestionScreen(BuildContext context) {
    final q = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

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
                Row(
                  children: [
                    Text(
                      'Вопрос ${_currentQuestion + 1} из ${_questions.length}',
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
                Text(
                  q.question,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 24),
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
