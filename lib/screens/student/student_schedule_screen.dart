import 'package:flutter/material.dart';
import '../widgets/centered_app_bar_title.dart'; // ✅ Добавлен импорт
import '../../widgets/haptic_refresh_indicator.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Новый AppBar с твоим общим виджетом
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A90E2),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A90E2),
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Расписание звонков',
            ),
            Tab(
              icon: Icon(Icons.groups),
              text: 'Расписание групп',
            ),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBellSchedule(),
          _buildGroupSchedule(),
        ],
      ),
    );
  }

  Widget _buildBellSchedule() {
    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Расписание звонков',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A90E2),
            ),
          ),
          const SizedBox(height: 16),
          _buildScheduleItem('1', '1 Лента', '08:30 - 10:05'),
          _buildScheduleItem('2', '2 Лента', '10:15 - 11:50'),
          _buildScheduleItem('3', '3 Лента', '12:30 - 14:05'),
          _buildScheduleItem('4', '4 Лента', '14:15 - 15:50'),
          _buildScheduleItem('5', '5 Лента', '16:00 - 17:25'),
          _buildScheduleItem('6', '6 Лента', '17:55 - 19:20'),

          const SizedBox(height: 24),
          const Text(
            'Суббота',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A90E2),
            ),
          ),
          const SizedBox(height: 16),
          _buildScheduleItem('1', '1 Лента', '8:30 - 10:05'),
          _buildScheduleItem('2', '2 Лента', '10:15 - 11:50'),
          _buildScheduleItem('3', '3 Лента', '12:00 - 13:35'),
          _buildScheduleItem('4', '4 Лента', '13:45 - 15:20'),
        ],
      ),
      ),
    );
  }

  Widget _buildScheduleItem(String number, String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSchedule() {
    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('1 Курс'),
              _buildFilterChip('2 Курс'),
              _buildFilterChip('3 Курс'),
              _buildFilterChip('4 Курс'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('ИСП'),
              _buildFilterChip('ТОАД'),
              _buildFilterChip('ИСК'),
              _buildFilterChip('ССА'),
              _buildFilterChip('ИБТС'),
              _buildFilterChip('ММР'),
              _buildFilterChip('СЭГ'),
              _buildFilterChip('ЭБУ'),
              _buildFilterChip('ИСП'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Группа ИСП',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '2 курс',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Понедельник',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLessonCard(
            '08:30-10:05',
            'ауд. 509',
            'Архитектура аппаратных средств',
            'Мамыкин С.Е.',
          ),
          _buildLessonCard(
            '10:15-11:50',
            'ауд. 411',
            'Основы алгоритмизации',
            'Гвоздиевская О.С.',
          ),
          _buildLessonCard(
            '12:30-14:05',
            'ауд. 410',
            'Информационных систем и программирования',
            'Мустыгина Е.С.',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLessonCard(
      String time,
      String room,
      String subject,
      String teacher,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                room,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacher,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
