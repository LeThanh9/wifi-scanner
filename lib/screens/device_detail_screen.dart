import 'package:flutter/material.dart';
import '../models/network_device.dart';

class DeviceDetailScreen extends StatelessWidget {
  final NetworkDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  IconData _getDeviceIcon() {
    switch (device.deviceType) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.phone:
        return Icons.phone_android;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.tablet:
        return Icons.tablet_android;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.iot:
        return Icons.sensors;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.hostname != 'Unknown' ? device.hostname : device.ipAddress),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Device Icon Hero
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                ),
              ),
              child: Icon(
                _getDeviceIcon(),
                size: 50,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              device.deviceType.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (device.isGateway)
              Chip(
                label: const Text('Gateway'),
                avatar: const Icon(Icons.star, size: 18),
                backgroundColor: colorScheme.primaryContainer,
              ),
            const SizedBox(height: 24),

            // Info Cards
            _buildInfoCard(context, 'IP Address', device.ipAddress, Icons.language),
            _buildInfoCard(context, 'MAC Address', device.macAddress, Icons.fingerprint),
            _buildInfoCard(context, 'Hostname', device.hostname, Icons.dns),
            _buildInfoCard(context, 'Vendor', device.vendor, Icons.business),
            _buildInfoCard(
              context,
              'Ping Time',
              device.pingTimeMs >= 0 ? '${device.pingTimeMs} ms' : 'N/A',
              Icons.speed,
            ),
            _buildInfoCard(
              context,
              'Device Type',
              device.deviceType.displayName,
              _getDeviceIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
