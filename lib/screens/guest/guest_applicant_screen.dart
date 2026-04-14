import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/cache/guest_applicant_content_cache.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class GuestApplicantScreen extends StatefulWidget {
  const GuestApplicantScreen({super.key});

  @override
  State<GuestApplicantScreen> createState() => _GuestApplicantScreenState();
}

class _GuestApplicantScreenState extends State<GuestApplicantScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<PageContentItem?> _pageFuture;
  late Future<List<SpecialtyItem>> _specialtiesFuture;
  late Future<List<PartnerItem>> _partnersFuture;
  List<SpecialtyItem> _cachedSpecialties = const [];

  Future<void> _loadCachedSpecialties() async {
    final cachedSpecialties = await GuestApplicantContentCache.readSpecialties();
    if (!mounted) return;
    if (cachedSpecialties != null && cachedSpecialties.isNotEmpty) {
      setState(() {
        _cachedSpecialties = cachedSpecialties;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCachedSpecialties());
    _pageFuture = _api.fetchPageBySlug('about-college');
    _specialtiesFuture = _api.fetchSpecialties();
    _partnersFuture = _api.fetchPartners();
  }

  Future<void> _onRefresh() async {
    final page = _api.fetchPageBySlug('about-college');
    final specs = _api.fetchSpecialties();
    final parts = _api.fetchPartners();
    setState(() {
      _pageFuture = page;
      _specialtiesFuture = specs;
      _partnersFuture = parts;
    });
    await Future.wait<void>([page, specs, parts]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Абитуриентам')),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<PageContentItem?>(
              future: _pageFuture,
              builder: (context, snapshot) {
                final page = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(page?.title ?? 'О колледже', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(page?.lead ?? ''),
                        const SizedBox(height: 8),
                        Text(page?.body ?? ''),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('Специальности', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            FutureBuilder<List<SpecialtyItem>>(
              future: _specialtiesFuture,
              builder: (context, snapshot) {
                final items = snapshot.data ?? _cachedSpecialties;
                if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Специальности пока не загружены.'),
                  );
                }
                return Column(
                  children: items
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${e.code} — ${e.title}'),
                            subtitle: Text(e.description),
                          ))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('Партнеры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            FutureBuilder<List<PartnerItem>>(
              future: _partnersFuture,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <PartnerItem>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  children: items
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.name),
                            subtitle: Text(e.description),
                          ))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
