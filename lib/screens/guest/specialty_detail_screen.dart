import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'document_submission_screen.dart';

class SpecialtyDetailScreen extends StatelessWidget {
  final Specialty specialty;
  const SpecialtyDetailScreen({super.key, required this.specialty});
  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true, backgroundColor: specialty.color,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(background: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [specialty.color, specialty.color.withOpacity(0.72)])),
            child: Stack(fit: StackFit.expand, children: [
              aboutCollegeImageFromPath(
                baseUrl,
                specialty.imagePath,
                fit: BoxFit.cover,
                errorFallback: const SizedBox(),
              ),
              Container(color: Colors.black.withOpacity(0.28)),
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
