import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../widgets/centered_app_bar_title.dart';
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}
class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // Список просмотренных историй
  final Set<int> _viewedStories = {};
  final _apiClient = ApiClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8081',
    ),
  );
  late Future<List<NewsItem>> _newsFuture;
  late Future<List<StoryItem>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _apiClient.fetchNews();
    _storiesFuture = _apiClient.fetchStories();
  }

  void _markAsViewed(int index) {
    setState(() {
      _viewedStories.add(index);
    });
  }
  bool _isViewed(int index) {
    return _viewedStories.contains(index);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ЛЕНТА ИСТОРИЙ (STORIES) - ПРЯМОУГОЛЬНИКИ
            SizedBox(
              height: 180,
              child: FutureBuilder<List<StoryItem>>(
                future: _storiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Ошибка загрузки историй: ${snapshot.error}'),
                      ),
                    );
                  }
                  final stories = snapshot.data ?? const <StoryItem>[];
                  if (stories.isEmpty) {
                    return const Center(child: Text('Истории пока отсутствуют'));
                  }
                  final prepared = List<StoryData>.generate(stories.length, (index) {
                    final s = stories[index];
                    return StoryData(
                      title: s.title,
                      content: s.content,
                      color: _storyBorderColor(index),
                      imageUrl: _toAbsoluteUrl(s.imageUrl),
                    );
                  });

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: prepared.length,
                    itemBuilder: (context, index) {
                      return _buildStoryItem(context, index, prepared[index], prepared);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<NewsItem>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Ошибка загрузки новостей: ${snapshot.error}'),
                  );
                }

                final news = snapshot.data ?? const <NewsItem>[];
                if (news.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Новости пока отсутствуют'),
                  );
                }

                return Column(
                  children: news.take(6).map((item) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildNewsCard(item),
                    );
                  }).toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    _toAbsoluteUrl(item.imageUrl),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _newsPlaceholder(),
                  )
                : _newsPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsPlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
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

  // ПРЯМОУГОЛЬНАЯ КАРТОЧКА ИСТОРИИ С ИЗОБРАЖЕНИЕМ
  Widget _buildStoryItem(
      BuildContext context,
      int index,
      StoryData story,
      List<StoryData> stories,
      ) {
    final bool isViewed = _isViewed(index);
    return GestureDetector(
      onTap: () async {
        await _openStoryViewer(context, index, stories);
        _markAsViewed(index);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // ПРЯМОУГОЛЬНИК С СКРУГЛЕННЫМИ УГЛАМИ
            Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isViewed ? Colors.grey : story.color,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    // ИЗОБРАЖЕНИЕ ИСТОРИИ
                    Image.network(
                      story.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Если изображение не найдено
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    // Градиент снизу для текста
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Название истории
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ОТКРЫТЬ ПРОСМОТР ИСТОРИЙ
  Future<void> _openStoryViewer(
      BuildContext context,
      int initialIndex,
      List<StoryData> stories,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          initialIndex: initialIndex,
          stories: stories,
        ),
      ),
    );
  }

  Color _storyBorderColor(int index) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return palette[index % palette.length];
  }
}
// МОДЕЛЬ ДАННЫХ ИСТОРИИ
class StoryData {
  final String title;
  final String content;
  final Color color;
  final String imageUrl;
  StoryData({
    required this.title,
    required this.content,
    required this.color,
    required this.imageUrl,
  });
}
// ЭКРАН ПРОСМОТРА ИСТОРИЙ
class StoryViewerScreen extends StatefulWidget {
  final int initialIndex;
  final List<StoryData> stories;
  const StoryViewerScreen({
    super.key,
    required this.initialIndex,
    required this.stories,
  });
  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}
class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  Timer? _timer;
  double _progress = 0.0;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startTimer();
  }
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  // ЗАПУСТИТЬ ТАЙМЕР 5 СЕКУНД
  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.05 / 5; // 5 секунд = 100%
        if (_progress >= 1.0) {
          _progress = 0.0;
          _nextStory();
        }
      });
    });
  }
  // СЛЕДУЮЩАЯ ИСТОРИЯ
  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }
  // ПРЕДЫДУЩАЯ ИСТОРИЯ
  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          // Левая половина - предыдущая история
          if (tapPosition < screenWidth / 2) {
            _previousStory();
          }
          // Правая половина - следующая история
          else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // КОНТЕНТ ИСТОРИЙ
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),
            // ПРОГРЕСС БАР СВЕРХУ — одна полоска на текущую историю
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ЗАГОЛОВОК И КНОПКА ЗАКРЫТЬ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/application_logo/logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[800],
                                ),
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.stories[_currentIndex].title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Кнопка «Подробнее» внизу — прозрачно-матовая
            Positioned(
              bottom: 40, left: 16, right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.white.withOpacity(0.2),
                    child: InkWell(
                      onTap: () {
                        _timer?.cancel();
                        final story = widget.stories[_currentIndex];
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                              child: Container(
                                color: Colors.white.withOpacity(0.30),
                                padding: const EdgeInsets.all(24),
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(story.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 12),
                                  Text(story.content, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5)),
                                  const SizedBox(height: 20),
                                  SizedBox(width: double.infinity, child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                        child: const Text('Закрыть'),
                                      ),
                                    ),
                                  )),
                                ]),
                              ),
                            ),
                          ),
                        ).then((_) => _startTimer());
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text('Подробнее', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // КОНТЕНТ ОДНОЙ ИСТОРИИ С ИЗОБРАЖЕНИЕМ (без текста контента)
  Widget _buildStoryContent(StoryData story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          story.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.black);
          },
        ),
        Container(color: Colors.black.withOpacity(0.15)),
      ],
    );
  }
}
