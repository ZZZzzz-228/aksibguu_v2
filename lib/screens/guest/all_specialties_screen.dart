import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_headers.dart';
import 'about_college_models.dart';
import 'about_college_cards.dart';
import 'specialty_detail_screen.dart';

class AllSpecialtiesScreen extends StatefulWidget {
  const AllSpecialtiesScreen({super.key, required this.specialties});

  final List<Specialty> specialties;

  @override
  State<AllSpecialtiesScreen> createState() => _AllSpecialtiesScreenState();
}

class _AllSpecialtiesScreenState extends State<AllSpecialtiesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showScrolledTitle = false;

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

  List<Specialty> _filteredSpecialties() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.specialties;
    bool matches(Specialty s) {
      return s.title.toLowerCase().contains(q) ||
          s.shortTitle.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.form.toLowerCase().contains(q) ||
          s.duration.toLowerCase().contains(q) ||
          s.qualification.toLowerCase().contains(q) ||
          s.career.toLowerCase().contains(q) ||
          s.skills.toLowerCase().contains(q) ||
          s.salary.toLowerCase().contains(q);
    }

    return widget.specialties.where(matches).toList(growable: false);
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
    final filtered = _filteredSpecialties();
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
                scrolledTitle: 'Все специальности',
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
                hintText: 'Поиск по названию, коду, описанию…',
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
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    widget.specialties.isEmpty
                        ? 'Список специальностей пуст'
                        : 'Ничего не найдено — попробуйте другой запрос',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...List.generate(filtered.length, (index) {
                final spec = filtered[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: ApplicantSpecialtyListCard(
                    specialty: spec,
                    baseUrl: baseUrl,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpecialtyDetailScreen(specialty: spec),
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
