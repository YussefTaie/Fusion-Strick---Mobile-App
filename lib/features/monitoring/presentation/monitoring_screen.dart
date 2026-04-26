import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

/// Placeholder screen for the Monitoring feature.
class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.monitor_heart_outlined,
        title: 'Traffic Monitoring',
        subtitle: 'Top flows and network metrics will appear here.',
      ),
    );
  }
}
