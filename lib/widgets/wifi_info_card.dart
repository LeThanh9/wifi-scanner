import 'package:flutter/material.dart';
import '../models/wifi_info.dart';

class WifiInfoCard extends StatelessWidget {
  final WifiInfo wifiInfo;

  const WifiInfoCard({super.key, required this.wifiInfo});

  List<Color> _getGradientColors() {
    if (wifiInfo.band.contains('5')) {
      return [Colors.blue.shade500, Colors.indigo.shade700];
    }
    if (wifiInfo.band.contains('6')) {
      return [Colors.purple.shade500, Colors.deepPurple.shade700];
    }
    if (wifiInfo.band.contains('2.4')) {
      return [Colors.teal.shade500, Colors.green.shade700];
    }
    return [Colors.blueGrey.shade600, Colors.blueGrey.shade800];
  }

  Color _getBadgeColor() {
    if (wifiInfo.band.contains('5')) return Colors.blue.shade700;
    if (wifiInfo.band.contains('6')) return Colors.purple.shade700;
    if (wifiInfo.band.contains('2.4')) return Colors.teal.shade700;
    return Colors.blueGrey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = _getGradientColors();

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
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                        wifiInfo.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wifiInfo.bssid != 'Unknown' && wifiInfo.bssid.isNotEmpty
                            ? 'BSSID: ${wifiInfo.bssid}'
                            : (wifiInfo.isConnected ? 'Network Connected' : 'Not Connected'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Band Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    wifiInfo.bandDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                    'Tần số (Freq)',
                    wifiInfo.frequencyDisplay,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.signal_cellular_alt,
                    'Tín hiệu (Signal)',
                    wifiInfo.signalStrength != 0 ? '${wifiInfo.signalStrength} dBm' : 'Tốt',
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
                    'Gateway / Router',
                    wifiInfo.gatewayIp,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.phone_android,
                    'IP máy này',
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
                    'Subnet Mask',
                    wifiInfo.subnetMask,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.category,
                    'Loại mạng',
                    wifiInfo.networkType.toUpperCase(),
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
