import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/api_client.dart';
import '../../data/cache/guest_applicant_content_cache.dart';
import '../../data/cache/guest_stories_cache.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'about_college_headers.dart';
import 'about_college_cards.dart';
import 'all_education_programs_screen.dart';
import 'all_specialties_screen.dart';
import 'specialty_detail_screen.dart';
import 'career_guidance_screen.dart';
import 'college_info_screen.dart';
import 'document_submission_screen.dart';
import 'guest_story_screens.dart';

class AboutCollegeScreen extends StatefulWidget {
  const AboutCollegeScreen({super.key});
  @override
  State<AboutCollegeScreen> createState() => _AboutCollegeScreenState();
}
class _AboutCollegeScreenState extends State<AboutCollegeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showMainTitle = false;
  final Set<int> _viewedStories = {};
  final PageController _specialtyController = PageController(viewportFraction: 0.86, initialPage: 0);
  int _currentSpecialtyPage = 0;
  EducationFilter _educationFilter = EducationFilter.additional;
  final PageController _educationController = PageController(viewportFraction: 0.86, initialPage: 0);
  int _currentEducationPage = 0;
  final ApiClient _api = AppSession.apiClient;
  PageContentItem? _cmsAboutCollege;
  List<Specialty> _specialtiesUi = const [];
  List<Partner> _partnersUi = const [];
  List<EducationProgram> _educationProgramsUi = const [];
  List<StoryData> _storiesUi = const [];

  Future<T?> _safeFetch<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCms() async {
    final cachedSpecialties = await GuestApplicantContentCache.readSpecialties();
    final cachedEducation = await GuestApplicantContentCache.readEducationPrograms();
    if (!mounted) return;
    if ((cachedSpecialties != null && cachedSpecialties.isNotEmpty) ||
        (cachedEducation != null && cachedEducation.isNotEmpty)) {
      setState(() {
        if (cachedSpecialties != null && cachedSpecialties.isNotEmpty) {
          _specialtiesUi = cachedSpecialties.map(_specialtyFromApi).toList(growable: false);
        }
        if (cachedEducation != null && cachedEducation.isNotEmpty) {
          _educationProgramsUi = cachedEducation.map(_educationProgramFromApi).toList(growable: false);
        }
      });
    }

    final cachedStories = await GuestStoriesCache.read();
    if (!mounted) return;
    if (cachedStories != null && cachedStories.isNotEmpty) {
      setState(() {
        _storiesUi = cachedStories.map(_storyFromApi).toList(growable: false);
      });
    }

    final pageFuture = _safeFetch(_api.fetchPageBySlug('about-college'));
    final specialtiesFuture = _safeFetch(_api.fetchSpecialties());
    final educationFuture = _safeFetch(_api.fetchEducationPrograms());
    final storiesFuture = _safeFetch(_api.fetchStories());
    final partnersFuture = _safeFetch(_api.fetchPartners());

    final results = await Future.wait([
      pageFuture,
      specialtiesFuture,
      educationFuture,
      storiesFuture,
      partnersFuture,
    ]);

    final page = results[0] as PageContentItem?;
    final cmsSpecialties = results[1] as List<SpecialtyItem>?;
    final cmsEducation = results[2] as List<EducationProgramItem>?;
    final cmsStories = results[3] as List<StoryItem>?;
    final cmsPartners = results[4] as List<PartnerItem>?;

    if (page != null && mounted) {
      setState(() => _cmsAboutCollege = page);
    }

    if (cmsSpecialties != null && mounted) {
      setState(() {
        _specialtiesUi = cmsSpecialties.map(_specialtyFromApi).toList(growable: false);
      });
      await GuestApplicantContentCache.saveSpecialties(cmsSpecialties);
    }

    if (cmsEducation != null && mounted) {
      setState(() {
        _educationProgramsUi = cmsEducation.map(_educationProgramFromApi).toList(growable: false);
      });
      await GuestApplicantContentCache.saveEducationPrograms(cmsEducation);
    }

    if (cmsStories != null && mounted) {
      setState(() {
        _storiesUi = cmsStories.map(_storyFromApi).toList(growable: false);
      });
      await GuestStoriesCache.save(cmsStories);
    }

    if (cmsPartners != null) {
      const icons = <IconData>[
        Icons.handshake,
        Icons.business,
        Icons.precision_manufacturing,
        Icons.satellite_alt,
        Icons.engineering,
        Icons.public,
      ];
      const colors = <Color>[
        Color(0xFF1A237E),
        Color(0xFF00695C),
        Color(0xFF1565C0),
        Color(0xFF2E7D32),
        Color(0xFFE65100),
        Color(0xFF283593),
      ];

      final mergedPartners = cmsPartners.asMap().entries.map((e) {
        final i = e.key;
        final cms = e.value;
        return Partner(
          name: cms.name.isNotEmpty ? cms.name : 'Партнёр',
          description: cms.description,
          icon: icons[i % icons.length],
          color: colors[i % colors.length],
          url: cms.websiteUrl,
          imagePath: cms.logoUrl.isNotEmpty ? cms.logoUrl : 'assets/images/application_logo/icon42.png',
        );
      }).toList(growable: false);

      if (mounted) {
        setState(() {
          _partnersUi = mergedPartners;
        });
      }
    }
  }
  List<EducationProgram> get _filteredEducationPrograms {
    final type = _educationFilter == EducationFilter.additional ? EducationType.additional : EducationType.courses;
    return _educationProgramsUi.where((p) => p.type == type).toList();
  }
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadCms());
  }
  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showMainTitle) setState(() => _showMainTitle = shouldShow);
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _specialtyController.dispose();
    _educationController.dispose();
    super.dispose();
  }
  bool _isViewed(int index) => _viewedStories.contains(index);
  void _markAsViewed(int index) => setState(() => _viewedStories.add(index));

  Future<void> _onRefresh() async {
    await _loadCms();
  }

  Specialty _specialtyFromApi(SpecialtyItem item) {
    return Specialty(
      id: item.title.isNotEmpty ? item.title : item.code,
      title: item.title.isNotEmpty ? item.title : item.code,
      shortTitle: item.shortTitle.isNotEmpty ? item.shortTitle : item.title,
      code: item.code,
      description: item.description,
      duration: item.durationLabel.isNotEmpty ? item.durationLabel : 'Уточняется',
      form: item.studyFormLabel.isNotEmpty ? item.studyFormLabel : 'Уточняется',
      icon: _iconFromName(item.iconName),
      color: _parseColorHex(item.colorHex) ?? const Color(0xFF1565C0),
      qualification: item.qualificationText.isNotEmpty ? item.qualificationText : 'Уточняется',
      career: item.careerText.isNotEmpty ? item.careerText : 'Уточняется',
      skills: item.skillsText.isNotEmpty ? item.skillsText : 'Уточняется',
      salary: item.salaryText.isNotEmpty ? item.salaryText : 'Уточняется',
      imagePath: item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/images/application_logo/icon42.png',
    );
  }

  EducationProgram _educationProgramFromApi(EducationProgramItem item) {
    final type = item.type == 'courses' ? EducationType.courses : EducationType.additional;
    return EducationProgram(
      type: type,
      title: item.title,
      description: item.description,
      duration: item.durationLabel,
      details: item.details,
      icon: _iconFromName(item.iconName),
      color: _parseColorHex(item.colorHex) ?? const Color(0xFF1565C0),
      targetAudience: item.targetAudience.isNotEmpty ? item.targetAudience : 'Уточняется',
      outcome: item.outcomeText.isNotEmpty ? item.outcomeText : 'Уточняется',
      format: item.formatText.isNotEmpty ? item.formatText : 'Уточняется',
      imagePath: item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/images/application_logo/icon42.png',
    );
  }

  StoryData _storyFromApi(StoryItem item) {
    return StoryData(
      title: item.title,
      content: item.content,
      color: _storyColor(item.sortOrder),
      imagePath: item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/images/application_logo/icon42.png',
      date: 'Дата уточняется',
      time: 'Время уточняется',
      location: 'Место уточняется',
      schedule: item.content,
    );
  }

  Color _storyColor(int seed) {
    const palette = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final index = seed < 0 ? 0 : seed % palette.length;
    return palette[index];
  }

  IconData _iconFromName(String iconName) {
    switch (iconName.trim()) {
      case 'web':
        return Icons.web;
      case 'calculate':
        return Icons.calculate;
      case 'design_services':
        return Icons.design_services;
      case 'lock':
        return Icons.lock;
      case 'functions':
        return Icons.functions;
      case 'menu_book':
        return Icons.menu_book;
      case 'computer':
        return Icons.computer;
      case 'science':
        return Icons.science;
      case 'code':
        return Icons.code;
      case 'security':
        return Icons.security;
      case 'engineering':
        return Icons.engineering;
      case 'school':
      default:
        return Icons.school;
    }
  }

  Color? _parseColorHex(String value) => aboutCollegeParseColorHex(value);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final horizontalPadding = isLargeScreen ? 24.0 : 16.0;
    final storyHeight = isSmallScreen ? 150.0 : (isLargeScreen ? 220.0 : 180.0);
    final buttonHeight = isSmallScreen ? 80.0 : (isLargeScreen ? 120.0 : 100.0);
    final cardHeight = isSmallScreen ? 180.0 : (isLargeScreen ? 240.0 : 200.0);
    final partnerCrossAxisCount = isLargeScreen ? 4 : (isSmallScreen ? 2 : 3);
    final partnerAspectRatio = isSmallScreen ? 0.85 : 0.75;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final buttonIconSize = isSmallScreen ? 26.0 : 32.0;
    final buttonFontSize = isSmallScreen ? 11.0 : 13.0;
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
                  flexibleSpace: AboutCollegeFrostedHeader(showCenterTitle: _showMainTitle),
                ),
              ];
            },
            body: HapticRefreshIndicator(
              color: const Color(0xFF4A90E2),
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
                children: [
                // ── 1) ИСТОРИИ ────────────────────────────────────────────────
                SizedBox(
                  height: storyHeight,
                  child: _storiesUi.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Мероприятия и истории появятся после публикации на сайте.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _storiesUi.length,
                          itemBuilder: (context, index) {
                            return _buildStoryItem(context, index, _storiesUi[index]);
                          },
                        ),
                ),
                const SizedBox(height: 18),
                // ── 2) КНОПКИ ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerGuidanceScreen())),
                        child: Container(
                          height: buttonHeight, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.explore, size: buttonIconSize, color: const Color(0xFF4A90E2)),
                            const SizedBox(height: 8),
                            Text('Профориентация', textAlign: TextAlign.center, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollegeInfoScreen())),
                        child: Container(
                          height: buttonHeight, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.school, size: buttonIconSize, color: const Color(0xFF4A90E2)),
                            const SizedBox(height: 8),
                            Text('О колледже', textAlign: TextAlign.center, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // ── 3) СПЕЦИАЛЬНОСТИ ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Специальности',
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSpecialtiesScreen(
                              specialties: _specialtiesUi,
                            ),
                          ),
                        );
                      },
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoriteSpecialtyStore.instance.favorites,
                  builder: (context, favorites, _) {
                    final list = _specialtiesUi;
                    return Column(
                      children: [
                        SizedBox(
                          height: cardHeight,
                          child: list.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Специальности загружаются с сервера или ещё не опубликованы.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ),
                                )
                              : PageView.builder(
                                  controller: _specialtyController,
                                  padEnds: false,
                                  itemCount: list.length,
                                  onPageChanged: (i) => setState(() => _currentSpecialtyPage = i),
                                  itemBuilder: (context, index) {
                                    final spec = list[index];
                                    return ApplicantSpecialtyCarouselCard(
                                      specialty: spec,
                                      isFavorite: favorites.contains(spec.id),
                                      onToggleFavorite: () => FavoriteSpecialtyStore.instance.toggle(spec.id),
                                      onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialtyDetailScreen(specialty: spec))),
                                    );
                                  },
                                ),
                        ),
                        if (list.isNotEmpty) const SizedBox(height: 10),
                        if (list.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(list.length, (i) {
                              final active = i == _currentSpecialtyPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: active ? 18 : 6, height: 6,
                                decoration: BoxDecoration(color: active ? const Color(0xFF4A90E2) : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                              );
                            }),
                          ),
                        // Кнопка «Подать документы» — появляется когда есть избранные
                        if (favorites.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DocumentSubmissionScreen(initialSpecialties: favorites.toList()),
                              )),
                              icon: const Icon(Icons.description_outlined),
                              label: Text('Подать документы (${favorites.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                // ── 4) ОБУЧЕНИЕ ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Обучение',
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllEducationProgramsScreen(programs: _educationProgramsUi),
                          ),
                        );
                      },
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Доп. образование'),
                      selected: _educationFilter == EducationFilter.additional,
                      onSelected: (v) { if (!v) return; setState(() { _educationFilter = EducationFilter.additional; _currentEducationPage = 0; }); _educationController.jumpToPage(0); },
                      selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                      labelStyle: TextStyle(color: _educationFilter == EducationFilter.additional ? const Color(0xFF4A90E2) : Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Курсы'),
                      selected: _educationFilter == EducationFilter.courses,
                      onSelected: (v) { if (!v) return; setState(() { _educationFilter = EducationFilter.courses; _currentEducationPage = 0; }); _educationController.jumpToPage(0); },
                      selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                      labelStyle: TextStyle(color: _educationFilter == EducationFilter.courses ? const Color(0xFF4A90E2) : Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final list = _filteredEducationPrograms;
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'Программы обучения появятся после публикации на сайте.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return Column(children: [
                    SizedBox(
                      height: cardHeight,
                      child: PageView.builder(
                        controller: _educationController,
                        padEnds: false,
                        itemCount: list.length,
                        onPageChanged: (i) => setState(() => _currentEducationPage = i),
                        itemBuilder: (context, index) => ApplicantEducationCarouselCard(program: list[index]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(list.length, (i) {
                        final active = i == _currentEducationPage;
                        return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3), width: active ? 18 : 6, height: 6, decoration: BoxDecoration(color: active ? const Color(0xFF4A90E2) : Colors.grey[300], borderRadius: BorderRadius.circular(3)));
                      }),
                    ),
                  ]);
                }),
                const SizedBox(height: 28),
                // ── 5) ПАРТНЁРЫ ───────────────────────────────────────────────
                Text('Партнёры', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _partnersUi.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Партнёры будут показаны после публикации на сайте.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: partnerCrossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: partnerAspectRatio),
                        itemCount: _partnersUi.length,
                        itemBuilder: (context, i) => _buildPartnerCard(_partnersUi[i]),
                      ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
  Widget _buildStoryItem(BuildContext context, int index, StoryData story) {
    final bool isViewed = _isViewed(index);
    final baseUrl = AppSession.apiClient.baseUrl;
    final sw = MediaQuery.of(context).size.width;
    final storyItemWidth = sw < 360 ? 100.0 : (sw > 600 ? 150.0 : 120.0);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(initialIndex: index, stories: _storiesUi)));
        _markAsViewed(index);
      },
      child: Container(
        width: storyItemWidth, margin: const EdgeInsets.only(right: 12),
        child: Container(
          width: storyItemWidth, height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isViewed ? Colors.grey : story.color, width: 3)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(fit: StackFit.expand, children: [
              aboutCollegeImageFromPath(
                baseUrl,
                story.imagePath,
                fit: BoxFit.cover,
                errorFallback: Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))),
              ),
              Align(alignment: Alignment.bottomCenter, child: Container(height: 60, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
              Align(alignment: Alignment.bottomLeft, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }
  Widget _buildPartnerCard(Partner p) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return GestureDetector(
      onTap: () async {
        final raw = p.url.trim();
        if (raw.isEmpty) return;
        final uri = Uri.parse(raw);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: aboutCollegeImageFromPath(
                baseUrl,
                p.imagePath,
                fit: BoxFit.cover,
                errorFallback: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: p.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(p.icon, color: p.color, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 4),
          Text(p.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.3)),
        ]),
      ),
    );
  }
}
