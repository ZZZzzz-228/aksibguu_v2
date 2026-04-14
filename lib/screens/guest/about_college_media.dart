import 'package:flutter/material.dart';

String aboutCollegeAbsoluteUrl(String baseUrl, String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  if (value.startsWith('/')) {
    return '$base$value';
  }
  return '$base/$value';
}

Widget aboutCollegeImageFromPath(
  String baseUrl,
  String path, {
  required BoxFit fit,
  Widget? errorFallback,
}) {
  final p = path.trim();
  if (p.isEmpty) {
    return errorFallback ?? const SizedBox.shrink();
  }
  if (p.startsWith('assets/')) {
    return Image.asset(
      p,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
    );
  }
  return Image.network(
    aboutCollegeAbsoluteUrl(baseUrl, p),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
  );
}

Color? aboutCollegeParseColorHex(String value) {
  var hex = value.trim();
  if (hex.isEmpty) return null;
  if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final parsed = int.tryParse(full, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
