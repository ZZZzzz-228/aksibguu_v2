import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'education_detail_screen.dart';

class ApplicantSpecialtyCarouselCard extends StatelessWidget {
  final Specialty specialty;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  const ApplicantSpecialtyCarouselCard({required this.specialty, required this.isFavorite, required this.onToggleFavorite, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Stack(children: [
          Container(
            decoration: BoxDecoration(color: specialty.color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: specialty.color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [
                // Фоновая картинка специальности
                Positioned.fill(
                  child: aboutCollegeImageFromPath(
                    baseUrl,
                    specialty.imagePath,
                    fit: BoxFit.cover,
                    errorFallback: Container(color: specialty.color),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.28)),
                ),
                Padding(
                  // Правый отступ увеличен, чтобы код НЕ заходил под звёздочку
                  padding: const EdgeInsets.fromLTRB(18, 18, 60, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(specialty.icon, color: Colors.white, size: 26)),
                        const SizedBox(width: 10),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(specialty.code, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                      ]),
                      const Spacer(),
                      Text(specialty.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(specialty.duration, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.school, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Expanded(child: Text(specialty.form, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleFavorite, borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.35))),
                  child: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? const Color(0xFFFFD54F) : Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class ApplicantEducationCarouselCard extends StatelessWidget {
  final EducationProgram program;
  const ApplicantEducationCarouselCard({required this.program});
  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationDetailScreen(program: program))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 52,
                height: 52,
                child: aboutCollegeImageFromPath(
                  baseUrl,
                  program.imagePath,
                  fit: BoxFit.cover,
                  errorFallback: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: program.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(program.icon, color: program.color, size: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(program.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 4),
              Text(program.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              const SizedBox(height: 4),
              Text(program.targetAudience, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: program.color.withOpacity(0.8), fontStyle: FontStyle.italic)),
              const Spacer(),
              Row(children: [
                Icon(Icons.timer_outlined, size: 14, color: program.color),
                const SizedBox(width: 4),
                Text(program.duration, style: TextStyle(fontSize: 12, color: program.color, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Подробнее →', style: TextStyle(fontSize: 11, color: program.color, fontWeight: FontWeight.w600)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

class ApplicantSpecialtyListCard extends StatelessWidget {
  const ApplicantSpecialtyListCard({
    required this.specialty,
    required this.baseUrl,
    required this.onTap,
  });

  final Specialty specialty;
  final String baseUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        aboutCollegeImageFromPath(
                          baseUrl,
                          specialty.imagePath,
                          fit: BoxFit.cover,
                          errorFallback: ColoredBox(color: specialty.color.withOpacity(0.35)),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            specialty.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: specialty.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              specialty.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: specialty.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  specialty.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  specialty.form,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ApplicantEducationListCard extends StatelessWidget {
  const ApplicantEducationListCard({
    required this.program,
    required this.baseUrl,
    required this.onTap,
  });

  final EducationProgram program;
  final String baseUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = educationProgramTypeLabel(program.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        aboutCollegeImageFromPath(
                          baseUrl,
                          program.imagePath,
                          fit: BoxFit.cover,
                          errorFallback: ColoredBox(color: program.color.withOpacity(0.35)),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            program.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: program.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: program.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  program.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_list_bulleted, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  program.format,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
