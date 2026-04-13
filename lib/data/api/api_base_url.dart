import 'dart:io';

import 'package:flutter/foundation.dart';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  if (kIsWeb) {
    return 'http://localhost:8081';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8081';
  }

  if (Platform.isIOS) {
    return 'http://192.168.0.15:8081';
  }

  return 'http://127.0.0.1:8081';
}
