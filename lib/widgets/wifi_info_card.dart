import 'package:flutter/material.dart';
import '../models/wifi_info.dart';

class WifiInfoCard extends StatelessWidget {
  final WifiInfo wifiInfo;

  const WifiInfoCard({super.key, required this.wifiInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final is5GHz = wifiInfo.band == '5 GHz';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: is5GHz
                          ? [Colors.blue.shade400, Colors.blue.shade700]
                          : [Colors.green.shade400, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wifi, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wifiInfo.isConnected ? wifiInfo.ssid : 'Not Connected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wifiInfo.bssid,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Band Badge
                if (wifiInfo.band != 'Unknown')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: is5GHz ? Colors.blue : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      wifiInfo.band,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.speed,
                    'Frequency',
                    wifiInfo.frequencyDisplay,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.signal_cellular_alt,
                    'Signal',
                    wifiInfo.signalStrength != 0
                        ? '${wifiInfo.signalStrength} dBm'
                        : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.router,
                    'Gateway',
                    wifiInfo.gatewayIp,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.phone_android,
                    'Local IP',
                    wifiInfo.localIp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.grid_view,
                    'Subnet',
                    wifiInfo.subnetMask,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.broadcast_on_personal,
                    'Broadcast',
                    wifiInfo.broadcastAddress,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
