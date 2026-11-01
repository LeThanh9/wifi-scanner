import 'package:flutter/material.dart';
import '../models/network_device.dart';

class DeviceCard extends StatelessWidget {
  final NetworkDevice device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

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

    final hasHostname = device.hostname != 'Unknown' && device.hostname.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Device Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: device.isGateway
                      ? colorScheme.primaryContainer
                      : device.isCurrentDevice
                          ? Colors.teal.withOpacity(0.2)
                          : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDeviceIcon(),
                  color: device.isGateway
                      ? colorScheme.onPrimaryContainer
                      : device.isCurrentDevice
                          ? Colors.teal
                          : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),

              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasHostname ? device.hostname : device.ipAddress,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.isGateway) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Router',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ] else if (device.isCurrentDevice) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'This Device',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasHostname ? '${device.ipAddress} • ${device.macAddress}' : device.macAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    if (device.vendor != 'Unknown' && device.vendor != 'This Device')
                      Text(
                        device.vendor,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // Ping time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (device.pingTimeMs >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: device.pingTimeMs < 20
                            ? Colors.green.withOpacity(0.15)
                            : device.pingTimeMs < 80
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${device.pingTimeMs}ms',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: device.pingTimeMs < 20
                              ? Colors.green
                              : device.pingTimeMs < 80
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
