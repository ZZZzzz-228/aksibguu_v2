import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_headers.dart';
import 'about_college_models.dart';
import 'about_college_cards.dart';
import 'education_detail_screen.dart';

enum AllEducationKindFilter { all, additional, courses }

class AllEducationProgramsScreen extends StatefulWidget {
  const AllEducationProgramsScreen({super.key, required this.programs});

  final List<EducationProgram> programs;

  @override
  State<AllEducationProgramsScreen> createState() => _AllEducationProgramsScreenState();
}

class _AllEducationProgramsScreenState extends State<AllEducationProgramsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showScrolledTitle = false;
  AllEducationKindFilter _kindFilter = AllEducationKindFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 10;
    if (show != _showScrolledTitle) {
      setState(() => _showScrolledTitle = show);
    }
  }

  List<EducationProgram> _visiblePrograms() {
    Iterable<EducationProgram> list = widget.programs;
    switch (_kindFilter) {
      case AllEducationKindFilter.additional:
        list = list.where((p) => p.type == EducationType.additional);
        break;
      case AllEducationKindFilter.courses:
        list = list.where((p) => p.type == EducationType.courses);
        break;
      case AllEducationKindFilter.all:
        break;
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return list.toList(growable: false);
    }
    return list.where((p) {
      final typeLabel = educationProgramTypeLabel(p.type).toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.duration.toLowerCase().contains(q) ||
          p.details.toLowerCase().contains(q) ||
          p.targetAudience.toLowerCase().contains(q) ||
          p.outcome.toLowerCase().contains(q) ||
          p.format.toLowerCase().contains(q) ||
          typeLabel.contains(q);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    final filtered = _visiblePrograms();
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
                scrolledTitle: 'Все обучения',
                alwaysShowTitle: true,
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Поиск по названию, описанию, формату…',
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black45),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _kindFilter == AllEducationKindFilter.all,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = AllEducationKindFilter.all);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == AllEducationKindFilter.all ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Доп. образование'),
                  selected: _kindFilter == AllEducationKindFilter.additional,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = AllEducationKindFilter.additional);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == AllEducationKindFilter.additional ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Курсы'),
                  selected: _kindFilter == AllEducationKindFilter.courses,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _kindFilter = AllEducationKindFilter.courses);
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _kindFilter == AllEducationKindFilter.courses ? const Color(0xFF4A90E2) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    widget.programs.isEmpty
                        ? 'Список программ пуст'
                        : 'Ничего не найдено — смените фильтр или запрос',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...List.generate(filtered.length, (index) {
                final program = filtered[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: ApplicantEducationListCard(
                    program: program,
                    baseUrl: baseUrl,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EducationDetailScreen(program: program),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
