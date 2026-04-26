import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

/// Placeholder screen for the Hosts feature.
class HostsScreen extends StatelessWidget {
  const HostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.dns_outlined,
        title: 'Network Hosts',
        subtitle: 'Monitored hosts and their status will appear here.',
      ),
    );
  }
}
