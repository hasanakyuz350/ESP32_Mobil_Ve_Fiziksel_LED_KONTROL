import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log_entry.dart';

class NotificationsPage extends StatelessWidget {
  final String deviceId;
  const NotificationsPage({super.key, this.deviceId = 'esp32c6-001'});

  Stream<List<LogEntry>> _watchLogs() {
    final col = FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .orderBy('at', descending: true)
        .limit(200);
    return col.snapshots().map(
      (qs) => qs.docs.map((d) => LogEntry.fromDoc(d)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loglar (Firestore)')),
      body: StreamBuilder<List<LogEntry>>(
        stream: _watchLogs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Henüz log yok'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              final isOn = e.action.toLowerCase() == 'on';
              final t = e.at != null ? _fmt(e.at!) : '-';
              final dot = Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOn ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              );

              return ListTile(
                leading: dot,
                title: Text(isOn ? 'LED YAK' : 'LED SÖNDÜR'),
                subtitle: Text('Kaynak: ${e.source} • $t'),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = dt.toLocal();
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }
}
