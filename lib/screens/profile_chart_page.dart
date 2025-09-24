import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProfileChartPage extends StatelessWidget {
  final String deviceId;
  final String? onlyPage;

  const ProfileChartPage({super.key, required this.deviceId, this.onlyPage});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    if (onlyPage != null && onlyPage!.isNotEmpty) {
      q = q.where('page', isEqualTo: onlyPage);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım Grafiği (ON / OFF)')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];

          int onCount = 0;
          int offCount = 0;

          for (final d in docs) {
            final action = (d.data()['action'] ?? '').toString().toLowerCase();
            if (action == 'on') onCount++;
            if (action == 'off') offCount++;
          }

          final total = (onCount + offCount);
          if (total == 0) {
            return const Center(child: Text('Henüz hiç log yok.'));
          }

          final onPct = (onCount / total) * 100;
          final offPct = (offCount / total) * 100;

          final sections = <PieChartSectionData>[
            PieChartSectionData(
              value: onCount.toDouble(),
              color: Colors.green,
              radius: 80,
              title: '${onPct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: offCount.toDouble(),
              color: Colors.red,
              radius: 80,
              title: '${offPct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: Colors.green, label: 'ON', value: onCount),
                    const SizedBox(width: 16),
                    _Legend(color: Colors.red, label: 'OFF', value: offCount),
                  ],
                ),
                const SizedBox(height: 24),

                AspectRatio(
                  aspectRatio: 1.2,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Toplam: $total log'
                  '${onlyPage != null ? "  •  Sayfa: $onlyPage" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label: $value'),
      ],
    );
  }
}
