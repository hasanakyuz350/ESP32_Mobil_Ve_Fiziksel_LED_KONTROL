import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore log model
/// action: "on" | "off"
/// source: "mobile" | "device"
class LogEntry {
  final String action;
  final String source;
  final String? deviceId;
  final DateTime? at; // Firestore timestamp (read)
  final String? page; // optional
  final String? platform; // optional

  const LogEntry({
    required this.action,
    required this.source,
    this.deviceId,
    this.at,
    this.page,
    this.platform,
  });

  Map<String, dynamic> toMap() => {
    'action': action,
    'source': source,
    'deviceId': deviceId,
    'page': page,
    'platform': platform,
    'at': FieldValue.serverTimestamp(),
  };

  factory LogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['at'];
    return LogEntry(
      action: (d['action'] ?? '').toString(),
      source: (d['source'] ?? '').toString(),
      deviceId: d['deviceId']?.toString(),
      page: d['page']?.toString(),
      platform: d['platform']?.toString(),
      at: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
