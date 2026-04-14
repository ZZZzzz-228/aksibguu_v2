import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'enrollment_form_screen.dart';

class EducationDetailScreen extends StatelessWidget {
  final EducationProgram program;
  const EducationDetailScreen({super.key, required this.program});
  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), title: Text(program.title), backgroundColor: program.color, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 80,
                height: 80,
                child: aboutCollegeImageFromPath(
                  baseUrl,
                  program.imagePath,
                  fit: BoxFit.cover,
                  errorFallback: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: program.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Icon(program.icon, color: program.color, size: 44),
                  ),
                ),
              ),
            ),
          ),
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
