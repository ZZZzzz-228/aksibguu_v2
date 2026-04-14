import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/centered_app_bar_title.dart';

/// Шапка главного экрана абитуриента: при скролле «Центр карьеры» исчезает, по центру — «Главная».
class AboutCollegeFrostedHeader extends StatelessWidget {
  const AboutCollegeFrostedHeader({super.key, required this.showCenterTitle});

  final bool showCenterTitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showCenterTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
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
                    child: const Text('Главная', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
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

/// Шапка вложенных экранов (мероприятия, все специальности): до скролла — назад и опционально бренд или постоянный [scrolledTitle]; после — матовый фон.
class AboutCollegePushedHeader extends StatelessWidget {
  const AboutCollegePushedHeader({
    super.key,
    required this.showScrolledTitle,
    required this.onBack,
    required this.scrolledTitle,
    this.showBranding = true,
    this.alwaysShowTitle = false,
  });

  final bool showScrolledTitle;
  final VoidCallback onBack;
  final String scrolledTitle;
  final bool showBranding;
  /// Если true — [scrolledTitle] всегда в шапке (например «Все специальности»); матовый слой по-прежнему только при прокрутке.
  final bool alwaysShowTitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showScrolledTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: onBack,
                    tooltip: 'Назад',
                  ),
                  Expanded(
                    child: alwaysShowTitle
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                scrolledTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: showScrolledTitle ? 0 : 1,
                                child: showBranding ? const CenteredAppBarTitle() : const SizedBox.shrink(),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: showScrolledTitle ? 1 : 0,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 220),
                                  offset: showScrolledTitle ? Offset.zero : const Offset(0, -0.15),
                                  child: Text(
                                    scrolledTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
