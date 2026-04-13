import 'package:flutter/material.dart';
import 'about_college_screen.dart';
import 'guest_contacts_screen.dart';
import 'guest_profile_screen.dart';
class GuestMainScreen extends StatefulWidget {
  const GuestMainScreen({super.key});
  @override
  State<GuestMainScreen> createState() => _GuestMainScreenState();
}
class _GuestMainScreenState extends State<GuestMainScreen> {
  int _currentIndex = 1;
  final List<Widget> _screens = [
    const GuestContactsScreen(),
    const AboutCollegeScreen(),
    const GuestProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                activeIcon: 'assets/icons/guest/contacts_active.png',
                inactiveIcon: 'assets/icons/guest/contacts.png',
                label: 'Контакты',
              ),
              _buildNavItem(
                index: 1,
                activeIcon: 'assets/icons/guest/applicant_active.png',
                inactiveIcon: 'assets/icons/guest/applicant.png',
                label: 'Абитуриенту',
              ),
              _buildNavItem(
                index: 2,
                activeIcon: 'assets/icons/guest/profile_active.png',
                inactiveIcon: 'assets/icons/guest/profile.png',
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNavItem({
    required int index,
    required String activeIcon,
    required String inactiveIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? activeIcon : inactiveIcon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback на стандартную иконку если изображение не найдено
                return Icon(
                  Icons.image,
                  size: 24,
                  color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
