import 'dart:io';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/wifi_info.dart';

class WifiService {
  static const _platform = MethodChannel('com.wifiscanner.app/network');
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<WifiInfo> getWifiInfo() async {
    String ssid = 'Unknown';
    String bssid = 'Unknown';
    int frequency = 0;
    String band = 'Unknown';
    int signalStrength = 0;
    String gatewayIp = 'Unknown';
    String localIp = 'Unknown';
    String subnetMask = '255.255.255.0';
    String networkType = 'wifi';

    // 1. Try native platform channel first (handles Android LinkProperties & WifiManager)
    try {
      final details = await _platform.invokeMethod('getNetworkDetails');
      if (details is Map) {
        final rawSsid = details['ssid'] as String?;
        if (rawSsid != null && rawSsid.isNotEmpty && rawSsid != '<unknown ssid>') {
          ssid = rawSsid;
        }

        final rawBssid = details['bssid'] as String?;
        if (rawBssid != null && rawBssid.isNotEmpty) {
          bssid = rawBssid;
        }

        final rawGw = details['gateway'] as String?;
        if (rawGw != null && rawGw.isNotEmpty && rawGw != '0.0.0.0') {
          gatewayIp = rawGw;
        }

        final rawIp = details['localIp'] as String?;
        if (rawIp != null && rawIp.isNotEmpty && rawIp != '0.0.0.0') {
          localIp = rawIp;
        }

        final rawMask = details['netmask'] as String?;
        if (rawMask != null && rawMask.isNotEmpty && rawMask != '0.0.0.0') {
          subnetMask = rawMask;
        }

        frequency = (details['frequency'] as num?)?.toInt() ?? 0;
        signalStrength = (details['rssi'] as num?)?.toInt() ?? 0;
        networkType = (details['networkType'] as String?) ?? 'wifi';
      }
    } catch (_) {}

    // 2. Fallback to network_info_plus for missing fields
    if (ssid == 'Unknown' || ssid.isEmpty) {
      try {
        final name = await _networkInfo.getWifiName();
        if (name != null && name.isNotEmpty && name != '<unknown ssid>') {
          ssid = name.replaceAll('"', '');
        }
      } catch (_) {}
    }

    if (bssid == 'Unknown' || bssid.isEmpty) {
      try {
        final b = await _networkInfo.getWifiBSSID();
        if (b != null && b.isNotEmpty) bssid = b;
      } catch (_) {}
    }

    if (gatewayIp == 'Unknown' || gatewayIp.isEmpty) {
      try {
        final gw = await _networkInfo.getWifiGatewayIP();
        if (gw != null && gw.isNotEmpty && gw != '0.0.0.0') {
          gatewayIp = gw;
        }
      } catch (_) {}
    }

    if (localIp == 'Unknown' || localIp.isEmpty) {
      try {
        final ip = await _networkInfo.getWifiIP();
        if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
          localIp = ip;
        }
      } catch (_) {}
    }

    // 3. Fallback to Dart's NetworkInterface.list() if local IP is still missing
    if (localIp == 'Unknown' || localIp.isEmpty) {
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              localIp = addr.address;
              break;
            }
          }
          if (localIp != 'Unknown' && localIp.isNotEmpty) break;
        }
      } catch (_) {}
    }

    // 4. Fallback gateway from localIp if gateway is still unknown
    if ((gatewayIp == 'Unknown' || gatewayIp.isEmpty) && localIp != 'Unknown') {
      final parts = localIp.split('.');
      if (parts.length == 4) {
        gatewayIp = '${parts[0]}.${parts[1]}.${parts[2]}.1';
      }
    }

    // 5. Band determination from frequency
    if (frequency > 0) {
      if (frequency < 3000) {
        band = '2.4 GHz';
      } else if (frequency >= 5000 && frequency < 5900) {
        band = '5 GHz';
      } else if (frequency >= 5900) {
        band = '6 GHz';
      } else {
        band = '${(frequency / 1000).toStringAsFixed(1)} GHz';
      }
    } else {
      band = 'Wi-Fi / LAN';
    }

    // 6. Broadcast address calculation
    String broadcastAddress = 'Unknown';
    if (localIp != 'Unknown' && subnetMask != 'Unknown') {
      try {
        final ipParts = localIp.split('.').map(int.parse).toList();
        final maskParts = subnetMask.split('.').map(int.parse).toList();
        if (ipParts.length == 4 && maskParts.length == 4) {
          final broadcastParts = List.generate(4, (i) => ipParts[i] | (~maskParts[i] & 0xFF));
          broadcastAddress = broadcastParts.join('.');
        }
      } catch (_) {
        broadcastAddress = 'Unknown';
      }
    }

    return WifiInfo(
      ssid: ssid,
      bssid: bssid,
      frequency: frequency,
      band: band,
      signalStrength: signalStrength,
      gatewayIp: gatewayIp,
      localIp: localIp,
      subnetMask: subnetMask,
      broadcastAddress: broadcastAddress,
      networkType: networkType,
    );
  }
}
