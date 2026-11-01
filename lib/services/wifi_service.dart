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

    try {
      ssid = await _networkInfo.getWifiName() ?? 'Unknown';
      // Remove quotes from SSID if present
      ssid = ssid.replaceAll('"', '');
    } catch (e) {
      ssid = 'Unknown';
    }

    try {
      bssid = await _networkInfo.getWifiBSSID() ?? 'Unknown';
    } catch (e) {
      bssid = 'Unknown';
    }

    try {
      gatewayIp = await _networkInfo.getWifiGatewayIP() ?? 'Unknown';
    } catch (e) {
      gatewayIp = 'Unknown';
    }

    try {
      localIp = await _networkInfo.getWifiIP() ?? 'Unknown';
    } catch (e) {
      localIp = 'Unknown';
    }

    try {
      subnetMask = await _networkInfo.getWifiSubmask() ?? '255.255.255.0';
    } catch (e) {
      subnetMask = '255.255.255.0';
    }

    // Get WiFi frequency via platform channel
    try {
      final result = await _platform.invokeMethod('getWifiFrequency');
      if (result is Map) {
        frequency = result['frequency'] ?? 0;
        signalStrength = result['rssi'] ?? 0;
      }
    } catch (e) {
      frequency = 0;
    }

    // Determine band from frequency
    if (frequency > 0) {
      if (frequency < 3000) {
        band = '2.4 GHz';
      } else if (frequency >= 5000) {
        band = '5 GHz';
      } else {
        band = '${(frequency / 1000).toStringAsFixed(1)} GHz';
      }
    }

    // Calculate broadcast address
    String broadcastAddress = 'Unknown';
    if (localIp != 'Unknown' && subnetMask != 'Unknown') {
      try {
        final ipParts = localIp.split('.').map(int.parse).toList();
        final maskParts = subnetMask.split('.').map(int.parse).toList();
        final broadcastParts = List.generate(4, (i) => ipParts[i] | (~maskParts[i] & 0xFF));
        broadcastAddress = broadcastParts.join('.');
      } catch (e) {
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
    );
  }
}

