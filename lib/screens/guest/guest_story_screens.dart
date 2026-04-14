import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'about_college_headers.dart';

class StoryViewerScreen extends StatefulWidget {
  final int initialIndex;
  final List<StoryData> stories;
  const StoryViewerScreen({super.key, required this.initialIndex, required this.stories});
  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}
class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  Timer? _timer;
  double _progress = 0.0;
  bool _isPaused = false;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startTimer();
  }
  @override
  void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }
  void _startTimer() {
    _timer?.cancel(); _progress = 0.0;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 0.05 / 5;
        if (_progress >= 1.0) { _progress = 0.0; _nextStory(); }
      });
    });
  }
  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 0.05 / 5;
        if (_progress >= 1.0) { _progress = 0.0; _nextStory(); }
      });
    });
  }
  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() { _currentIndex++; _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); });
      _startTimer();
    } else { Navigator.pop(context); }
  }
  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() { _currentIndex--; _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); });
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
          final screenHeight = MediaQuery.of(context).size.height;
          // Нижние 25% экрана — зона кнопки «Подробнее», не переключаем
          if (details.globalPosition.dy > screenHeight * 0.75) return;
          if (details.globalPosition.dx < screenWidth / 2) { _previousStory(); } else { _nextStory(); }
        },
        onLongPressStart: (_) {
          setState(() => _isPaused = true);
          _timer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _resumeTimer();
        },
        child: Stack(children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => _buildStoryContent(widget.stories[index]),
          ),
          SafeArea(child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: List.generate(widget.stories.length, (i) {
                double value = i < _currentIndex ? 1.0 : (i == _currentIndex ? _progress : 0.0);
                return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 3,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(3)),
                    child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: value, child: Container(height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)))))));
              })),
            ),
            Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 8), child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)))),
          ])),
          // Кнопка «Подробнее» внизу
          Positioned(
            bottom: 40, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventsFeedScreen(
                          stories: widget.stories,
                          initialIndex: _currentIndex,
                        ),
                      ),
                    ).then((_) => _startTimer());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Подробнее', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),),),
        ]),
      ),
    );
  }
  Widget _buildStoryContent(StoryData story) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Stack(fit: StackFit.expand, children: [
      aboutCollegeImageFromPath(
        baseUrl,
        story.imagePath,
        fit: BoxFit.cover,
        errorFallback: Container(color: Colors.black),
      ),
      Container(color: Colors.black.withOpacity(0.55)),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 90, 16, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black)])),
        const SizedBox(height: 10),
        Text(story.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black)])),
        const Spacer(),
        // Дата, время и место на самой истории
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(story.date, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(story.time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(child: Text(story.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
      ]))),
    ]);
  }
}

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<StoryData> stories;
  final int initialIndex;

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  late final ScrollController _scrollController;
  late int _selectedIndex;
  bool _showScrolledTitle = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExt = _scrollController.position.maxScrollExtent;
      final targetOffset = (_selectedIndex * 340.0).clamp(0.0, maxExt);
      _scrollController.jumpTo(targetOffset);
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showScrolledTitle) {
      setState(() => _showScrolledTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: AboutCollegePushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: 'Мероприятия',
              ),
            ),
          ];
        },
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
          final story = widget.stories[index];
          final isSelected = index == _selectedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedIndex = index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          aboutCollegeImageFromPath(
                            baseUrl,
                            story.imagePath,
                            fit: BoxFit.cover,
                            errorFallback: Container(color: Colors.grey.shade200),
                          ),
                          Container(color: Colors.black.withOpacity(0.15)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(child: Text(story.date, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(child: Text(story.time, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                story.location,
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          story.content,
                          maxLines: isSelected ? 999 : 2,
                          overflow: isSelected ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          const Text('Программа', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.15)),
                            ),
                            child: Text(
                              story.schedule,
                              style: const TextStyle(fontSize: 13, height: 1.55),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            isSelected ? 'Выбрано' : 'Нажмите, чтобы открыть',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF4A90E2) : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}
