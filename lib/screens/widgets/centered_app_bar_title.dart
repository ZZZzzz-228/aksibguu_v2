import 'package:flutter/material.dart';
class CenteredAppBarTitle extends StatelessWidget {
  const CenteredAppBarTitle({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ЛОГОТИП ИЗ ASSETS
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/application_logo/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Если изображение не найдено, показываем placeholder
                return Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey, size: 20),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ЦЕНТР',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                  height: 1,
                ),
              ),
              Text(
                'КАРЬЕРЫ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                  height: 1,
                ),
              ),
              Text(
                'АК СИБГУ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF4A90E2),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
