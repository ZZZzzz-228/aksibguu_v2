import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';

class StudentPortfolioScreen extends StatefulWidget {
  const StudentPortfolioScreen({super.key});

  @override
  State<StudentPortfolioScreen> createState() => _StudentPortfolioScreenState();
}

class _StudentPortfolioScreenState extends State<StudentPortfolioScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<StudentPortfolioItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchStudentPortfolio();
  }

  void _reload() {
    setState(() {
      _future = _api.fetchStudentPortfolio();
    });
  }

  Future<void> _addItem() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Описание')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'Ссылка')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok != true) return;
    await _api.createStudentPortfolioItem(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      projectUrl: urlController.text.trim(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моё портфолио')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<StudentPortfolioItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const <StudentPortfolioItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('Портфолио пока пусто'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _api.deleteStudentPortfolioItem(item.id);
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
