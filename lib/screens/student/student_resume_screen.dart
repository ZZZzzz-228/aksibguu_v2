import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';

class StudentResumeScreen extends StatefulWidget {
  const StudentResumeScreen({super.key});

  @override
  State<StudentResumeScreen> createState() => _StudentResumeScreenState();
}

class _StudentResumeScreenState extends State<StudentResumeScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<StudentResumeItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchStudentResumes();
  }

  void _reload() {
    setState(() {
      _future = _api.fetchStudentResumes();
    });
  }

  Future<void> _addResume() async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новое резюме'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Кратко о себе')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok != true) return;
    await _api.createStudentResume(
      title: titleController.text.trim(),
      summary: summaryController.text.trim(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои резюме')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addResume,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<StudentResumeItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const <StudentResumeItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('Резюме пока нет'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.summary),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _api.deleteStudentResume(item.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
