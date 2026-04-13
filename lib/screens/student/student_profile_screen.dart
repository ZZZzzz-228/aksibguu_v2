import 'package:flutter/material.dart';
import '../guest/guest_main_screen.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import 'student_portfolio_screen.dart';
import 'student_resume_screen.dart';
import '../widgets/centered_app_bar_title.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<StudentProfileItem?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _api.fetchStudentProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Новый AppBar
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар и информация о студенте
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<StudentProfileItem?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  );
                }
                if (profile == null) {
                  return const Text('Профиль студента не заполнен');
                }
                return Column(
                  children: [
                    Text(
                      profile.fullName.isEmpty ? 'Студент' : profile.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.groupTitle.isEmpty ? 'Группа не назначена' : 'Группа: ${profile.groupTitle}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    if (profile.curatorName.isNotEmpty)
                      Text(
                        'Куратор: ${profile.curatorName}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Кнопки профиля
            _buildProfileButton(
              context,
              'Моё портфолио',
              Icons.folder_open,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentPortfolioScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildProfileButton(
              context,
              'Создание резюме',
              Icons.description,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentResumeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildProfileButton(
              context,
              'Выйти',
              Icons.logout,
                  () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GuestMainScreen(),
                  ),
                );
              },
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap, {
        bool isLogout = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : Colors.black87,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
