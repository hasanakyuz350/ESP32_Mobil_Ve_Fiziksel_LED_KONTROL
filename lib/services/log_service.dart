import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<void> write({
    required String deviceId,
    required String action, // "on" | "off"
    required String source, // "mobile" | "device"
    String? page,
  }) {
    final col = _fs.collection('devices').doc(deviceId).collection('logs');
    return col.add({
      'action': action,
      'source': source,
      'deviceId': deviceId,
      'page': page,
      'platform': _detectPlatform(),
      'at': FieldValue.serverTimestamp(),
    });
  }

  String _detectPlatform() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'web/unknown';
  }
}
