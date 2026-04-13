import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';

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

  @override
  void initState() {
    super.initState();
    _pageFuture = _api.fetchPageBySlug('about-college');
    _specialtiesFuture = _api.fetchSpecialties();
    _partnersFuture = _api.fetchPartners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Абитуриентам')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _pageFuture = _api.fetchPageBySlug('about-college');
            _specialtiesFuture = _api.fetchSpecialties();
            _partnersFuture = _api.fetchPartners();
          });
        },
        child: ListView(
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
                final items = snapshot.data ?? const <SpecialtyItem>[];
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
