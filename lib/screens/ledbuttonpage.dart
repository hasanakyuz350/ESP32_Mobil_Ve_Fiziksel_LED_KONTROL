import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/log_service.dart';

class LedButtonPage extends StatefulWidget {
  final String deviceId;
  const LedButtonPage({super.key, this.deviceId = 'esp32c6-001'});

  @override
  State<LedButtonPage> createState() => _LedButtonPageState();
}

class _LedButtonPageState extends State<LedButtonPage> {
  final _db = FirebaseDatabase.instance;
  final _logs = LogService();

  late final DatabaseReference _telemetryRef;
  late final DatabaseReference _cmdRef;
  late final DatabaseReference _eventsRef;

  StreamSubscription<DatabaseEvent>? _telemetrySub;
  StreamSubscription<DatabaseEvent>? _eventsAddedSub;

  bool _isOn = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _telemetryRef = _db.ref('devices/${widget.deviceId}/telemetry/isOn');
    _cmdRef = _db.ref('devices/${widget.deviceId}/cmd');
    _eventsRef = _db.ref('devices/${widget.deviceId}/events');
    _telemetrySub = _telemetryRef.onValue.listen((ev) {
      final v = ev.snapshot.value;
      final newOn = (v is bool) ? v : (v is num ? v != 0 : false);
      if (mounted) setState(() => _isOn = newOn);
    });
    _eventsAddedSub = _eventsRef.onChildAdded.listen((ev) async {
      final raw = ev.snapshot.value;
      if (raw is! Map) return;
      final map = Map<Object?, Object?>.from(raw);

      if (map['consumed'] == true) return;

      final by = map['by']?.toString().toLowerCase();
      final v = map['isOn'];
      bool? isOn;
      if (v is bool) isOn = v;
      if (v is num) isOn = v != 0;

      if (by == 'device' && isOn != null) {
        await _logs.write(
          deviceId: widget.deviceId,
          action: isOn ? 'on' : 'off',
          source: 'BUTON',
          page: 'LedButtonPage',
        );
        await _eventsRef.child(ev.snapshot.key!).update({
          'consumed': true,
          'processedAt': ServerValue.timestamp,
        });
      }
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _eventsAddedSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleFromApp() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final next = !_isOn;
      await _cmdRef.set({
        'isOn': next,
        'by': 'mobile',
        'ts': ServerValue.timestamp,
      });
      await _logs.write(
        deviceId: widget.deviceId,
        action: next ? 'on' : 'off',
        source: 'MOBİL',
        page: 'LedButtonPage',
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _isOn ? 'SÖNDÜR' : 'YAK';
    final bulbColor = _isOn ? Colors.amber : Colors.white;
    final bulbIcon = Icons.lightbulb;

    return Scaffold(
      appBar: AppBar(title: Text('KONTROL')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bulbIcon, color: bulbColor, size: 72),

            const SizedBox(height: 8),
            Text(
              'Durum: ${_isOn ? "YANIK" : "SÖNÜK"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),
            FilledButton(
              onPressed: _syncing ? null : _toggleFromApp,
              child: _syncing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
