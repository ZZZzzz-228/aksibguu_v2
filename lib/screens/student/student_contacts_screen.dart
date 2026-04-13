import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_base_url.dart';
import '../widgets/centered_app_bar_title.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentContactsScreen extends StatefulWidget {
  const StudentContactsScreen({super.key});

  @override
  State<StudentContactsScreen> createState() => _StudentContactsScreenState();
}

class _StudentContactsScreenState extends State<StudentContactsScreen> {
  final _apiClient = ApiClient(
    baseUrl: resolveApiBaseUrl(),
  );

  late Future<List<ContactItem>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _apiClient.fetchContacts();
  }

  Future<void> _onRefresh() async {
    final f = _apiClient.fetchContacts();
    setState(() => _contactsFuture = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(), // ✅ Новый компонент шапки
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFE3F2FD),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'ЦЕНТР КАРЬЕРЫ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Сибирский государственный университет науки и технологий имени академика М.Ф. Решетнёва, аэрокосмический колледж',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<ContactItem>>(
                    future: _contactsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('Ошибка загрузки контактов: ${snapshot.error}'),
                        );
                      }

                      final contacts = snapshot.data ?? const <ContactItem>[];
                      if (contacts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Контакты не найдены'),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: contacts
                            .map(
                              (contact) => _buildContactItem(
                                _iconForType(contact.type),
                                contact.value,
                                const Color(0xFF4A90E2),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 32,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '08:00-17:00',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 32,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '500+ студентов',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 32,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Онлайн поддержка',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF64B5F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // ✅ Фото директора
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/contacts/director_photo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Тимошев Павел Викторович',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Директор Аэрокосмического Колледжа',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse('mailto:ak@sibsau.ru');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ak@sibsau.ru',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A90E2),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse('tel:2919115');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '2919115',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A90E2),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Часы приёма: вторник, четверг с 14:00 до 16:00',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.language;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildContactItem(IconData icon, String text, Color color) {
    return GestureDetector(
      onTap: () async {
        Uri? uri;
        if (icon == Icons.phone) {
          final cleanPhone = text.replaceAll(RegExp(r'[^\d+]'), '');
          uri = Uri.parse('tel:$cleanPhone');
        } else if (icon == Icons.email) {
          uri = Uri.parse('mailto:$text');
        } else if (icon == Icons.language) {
          final url = text.contains('://') ? text : 'https://$text';
          uri = Uri.parse(url);
        }
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
