import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/api/api_base_url.dart';
import '../../data/cache/guest_staff_cache.dart';
import '../widgets/centered_app_bar_title.dart';
class GuestContactsScreen extends StatefulWidget {
  const GuestContactsScreen({super.key});
  @override
  State<GuestContactsScreen> createState() => _GuestContactsScreenState();
}
class _GuestContactsScreenState extends State<GuestContactsScreen> {
  final ScrollController _scrollController = ScrollController();
  final _apiClient = ApiClient(
    baseUrl: resolveApiBaseUrl(),
  );
  bool _showMainTitle = false;

  /// Пока true и список пуст — показываем индикатор первой загрузки.
  bool _staffInitialLoading = true;
  List<StaffMemberItem> _staffList = [];
  bool _staffFromCacheOnly = false;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final cached = await GuestStaffCache.read();
    if (!mounted) return;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _staffList = cached;
        _staffInitialLoading = false;
        _staffFromCacheOnly = false;
        _staffError = null;
      });
    }
    try {
      final fresh = await _apiClient.fetchStaff();
      await GuestStaffCache.save(fresh);
      if (!mounted) return;
      setState(() {
        _staffList = fresh;
        _staffInitialLoading = false;
        _staffFromCacheOnly = false;
        _staffError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _staffInitialLoading = false;
        if (_staffList.isEmpty) {
          _staffError = e.toString();
          _staffFromCacheOnly = false;
        } else {
          _staffError = null;
          _staffFromCacheOnly = true;
        }
      });
    }
  }
  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showMainTitle) setState(() => _showMainTitle = shouldShow);
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true, floating: false, snap: false,
                  elevation: 0, scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 74,
                  flexibleSpace: _FrostedContactsHeader(showCenterTitle: _showMainTitle),
                ),
              ];
            },
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Основная информационная карточка
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildContactItem(
                            Icons.phone,
                            '+7 (391) 264-06-59',
                            const Color(0xFF4A90E2),
                          ),
                          _buildContactItem(
                            Icons.phone,
                            '+7 (391) 264-57-35',
                            const Color(0xFF4A90E2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildContactItem(
                            Icons.phone,
                            '+7 (391) 264-15-88',
                            const Color(0xFF4A90E2),
                          ),
                          _buildContactItem(
                            Icons.email,
                            'ak@sibsau.ru',
                            const Color(0xFF4A90E2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildContactItem(
                            Icons.language,
                            'sibsau.ru',
                            const Color(0xFF4A90E2),
                          ),
                          _buildContactItem(
                            Icons.language,
                            'abiturient.sibsau.ru',
                            const Color(0xFF4A90E2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Иконки с информацией
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: const [
                              Icon(Icons.access_time, size: 32, color: Colors.black87),
                              SizedBox(height: 8),
                              Text(
                                '08:00-17:00',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: const [
                              Icon(Icons.people, size: 32, color: Colors.black87),
                              SizedBox(height: 8),
                              Text(
                                '500+ студентов',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: const [
                              Icon(Icons.chat_bubble_outline, size: 32, color: Colors.black87),
                              SizedBox(height: 8),
                              Text(
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
                _buildStaffSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection() {
    if (_staffInitialLoading && _staffList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_staffError != null && _staffList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Ошибка загрузки сотрудников: $_staffError'),
      );
    }
    if (_staffList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Список сотрудников пока пуст. Подключитесь к интернету один раз, чтобы подтянуть данные.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_staffFromCacheOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Нет сети — показаны сохранённые карточки. Фото подгрузятся при следующем подключении.',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...List.generate(_staffList.length, (index) {
          final staff = _staffList[index];
          const gradients = [
            [Color(0xFF4A90E2), Color(0xFF64B5F6)],
            [Color(0xFF42A5F5), Color(0xFF90CAF9)],
            [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
            [Color(0xFFAB47BC), Color(0xFFCE93D8)],
          ];
          final gradientColors = gradients[index % gradients.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStaffCard(
              name: staff.fullName,
              position: staff.positionTitle,
              email: staff.email,
              phone: staff.phone,
              hours: staff.officeHours,
              photoUrl: staff.photoUrl,
              gradientColors: gradientColors,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStaffCard({
    required String name,
    required String position,
    required String email,
    required String phone,
    required String hours,
    required String photoUrl,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Фото сотрудника
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: _buildStaffPhoto(photoUrl),
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
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: gradientColors[0],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('mailto:$email');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, size: 16, color: gradientColors[0]),
                      const SizedBox(width: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: gradientColors[0],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                    final uri = Uri.parse('tel:$cleanPhone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 16, color: gradientColors[0]),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: gradientColors[0],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hours,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPhoto(String photoUrl) {
    final fallback = Image.asset(
      'assets/images/application_logo/icon42.png',
      fit: BoxFit.cover,
    );
    if (photoUrl.trim().isEmpty) {
      return fallback;
    }
    final absolute = _toAbsoluteUrl(photoUrl.trim());
    return Image.network(
      absolute,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  String _toAbsoluteUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = _apiClient.baseUrl.endsWith('/')
        ? _apiClient.baseUrl.substring(0, _apiClient.baseUrl.length - 1)
        : _apiClient.baseUrl;
    if (value.startsWith('/')) {
      return '$base$value';
    }
    return '$base/$value';
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
// ─────────────────────────────────────────────────────────────────────────────
// Frosted header для страницы Контакты:
// при скролле иконка и «Центр карьеры» исчезают, появляется «Контакты»
// ─────────────────────────────────────────────────────────────────────────────
class _FrostedContactsHeader extends StatelessWidget {
  final bool showCenterTitle;
  const _FrostedContactsHeader({required this.showCenterTitle});
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Матовый фон — появляется плавно
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showCenterTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          // «Центр карьеры» — исчезает при скролле
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 0 : 1,
                  child: const CenteredAppBarTitle(),
                ),
              ),
            ),
          ),
          // «Контакты» — плавно появляется по центру при скролле
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    offset: showCenterTitle ? Offset.zero : const Offset(0, -0.15),
                    child: const Text('Контакты', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
