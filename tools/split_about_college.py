from pathlib import Path

root = Path(__file__).resolve().parent.parent / "lib" / "screens" / "guest"
src = root / "about_college_screen.dart"
lines = src.read_text(encoding="utf-8").splitlines(keepends=True)


def sl(a: int, b: int) -> str:
    return "".join(lines[a - 1 : b])


def main() -> None:
    hdr_guest = """import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_headers.dart';
import 'about_college_models.dart';
import 'about_college_cards.dart';
import 'specialty_detail_screen.dart';

"""
    s = sl(782, 929)
    s = s.replace("_FrostedPushedHeader", "AboutCollegePushedHeader")
    s = s.replace("_AllSpecialtiesRectCard", "ApplicantSpecialtyListCard")
    (root / "all_specialties_screen.dart").write_text(hdr_guest + s, encoding="utf-8")

    hdr_ed = """import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_headers.dart';
import 'about_college_models.dart';
import 'about_college_cards.dart';
import 'education_detail_screen.dart';

"""
    s = sl(1073, 1278)
    s = s.replace("enum _AllEducationKindFilter", "enum AllEducationKindFilter")
    s = s.replace("_AllEducationKindFilter", "AllEducationKindFilter")
    s = s.replace("_FrostedPushedHeader", "AboutCollegePushedHeader")
    s = s.replace("_AllEducationRectCard", "ApplicantEducationListCard")
    s = s.replace("_educationProgramTypeLabel", "educationProgramTypeLabel")
    (root / "all_education_programs_screen.dart").write_text(hdr_ed + s, encoding="utf-8")

    hdr_det = """import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'enrollment_form_screen.dart';

"""
    s = sl(1626, 1720).replace("_imageFromPath", "aboutCollegeImageFromPath")
    (root / "education_detail_screen.dart").write_text(hdr_det + s, encoding="utf-8")

    hdr_spec = """import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'document_submission_screen.dart';

"""
    s = sl(1724, 1854).replace("_imageFromPath", "aboutCollegeImageFromPath")
    (root / "specialty_detail_screen.dart").write_text(hdr_spec + s, encoding="utf-8")

    hdr_story = """import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'about_college_headers.dart';

"""
    s = sl(1858, 2235)
    s = s.replace("_imageFromPath", "aboutCollegeImageFromPath")
    s = s.replace("_FrostedPushedHeader", "AboutCollegePushedHeader")
    (root / "guest_story_screens.dart").write_text(hdr_story + s, encoding="utf-8")

    hdr_enr = """import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';

"""
    s = sl(2342, 2548)
    (root / "enrollment_form_screen.dart").write_text(hdr_enr + s, encoding="utf-8")

    main_hdr = """import 'dart:async';
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

"""
    main = sl(161, 780)
    for a, b in (
        ("_FrostedHeader", "AboutCollegeFrostedHeader"),
        ("_imageFromPath", "aboutCollegeImageFromPath"),
        ("_parseColorHexString", "aboutCollegeParseColorHex"),
        ("_SpecialtyCard", "ApplicantSpecialtyCarouselCard"),
        ("_EducationCard", "ApplicantEducationCarouselCard"),
    ):
        main = main.replace(a, b)
    (root / "about_college_screen.dart").write_text(main_hdr + main, encoding="utf-8")

    print("ok")


if __name__ == "__main__":
    main()
