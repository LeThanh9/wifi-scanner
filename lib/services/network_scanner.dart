import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import '../models/network_device.dart';
import '../utils/vendor_lookup.dart';

class NetworkScanner {
  static const _platform = MethodChannel('com.wifiscanner.app/network');
  final NetworkInfo _networkInfo = NetworkInfo();

  Function(int scanned, int total)? onProgress;
  Function(NetworkDevice device)? onDeviceFound;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<String?> get gatewayIp async {
    try {
      final details = await _platform.invokeMethod('getNetworkDetails');
      if (details is Map) {
        final gw = details['gateway'] as String?;
        if (gw != null && gw.isNotEmpty && gw != '0.0.0.0') return gw;
      }
    } catch (_) {}

    try {
      final gw = await _networkInfo.getWifiGatewayIP();
      if (gw != null && gw.isNotEmpty && gw != '0.0.0.0') return gw;
    } catch (_) {}

    // Fallback: derive from local IP
    final ip = await localIp;
    if (ip != null) {
      final parts = ip.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.1';
      }
    }
    return null;
  }

  Future<String?> get localIp async {
    try {
      final details = await _platform.invokeMethod('getNetworkDetails');
      if (details is Map) {
        final ip = details['localIp'] as String?;
        if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') return ip;
      }
    } catch (_) {}

    try {
      final ip = await _networkInfo.getWifiIP();
      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') return ip;
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, String>> _getArpTable() async {
    try {
      final result = await _platform.invokeMethod('getArpTable');
      if (result is Map) {
        return Map<String, String>.from(result);
      }
    } catch (_) {}
    return {};
  }

  List<String> _generateIpRange(String baseIp) {
    final parts = baseIp.split('.');
    if (parts.length != 4) return [];
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    return List.generate(254, (i) => '$prefix.${i + 1}');
  }

  Future<NetworkDevice?> _probeHost(String ip, String gateway, String myIp) async {
    // 1. Current Device
    if (ip == myIp) {
      return NetworkDevice(
        ipAddress: ip,
        hostname: 'This Device (Your Phone)',
        isGateway: ip == gateway,
        isCurrentDevice: true,
        pingTimeMs: 0,
        deviceType: DeviceType.phone,
      );
    }

    final isGw = (ip == gateway);
    int pingTime = -1;
    bool isAlive = false;

    // Common probe ports (router, web, file sharing, ssh, cast, apple)
    final probePorts = isGw
        ? [53, 80, 443, 8080]
        : [80, 443, 445, 53, 8080, 139, 22, 8008, 62078, 5000];

    final stopwatch = Stopwatch()..start();

    // 2. TCP Probe
    for (final port in probePorts) {
      if (!_isScanning) break;
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 140),
        );
        stopwatch.stop();
        pingTime = stopwatch.elapsedMilliseconds;
        socket.destroy();
        isAlive = true;
        break;
      } on SocketException catch (e) {
        // TCP RST packet means the host OS is ALIVE and actively refused connection
        final msg = e.message.toLowerCase();
        final osErr = e.osError?.errorCode ?? 0;
        if (msg.contains('refused') ||
            msg.contains('reset') ||
            osErr == 111 ||
            osErr == 10061 ||
            osErr == 104) {
          stopwatch.stop();
          pingTime = stopwatch.elapsedMilliseconds;
          isAlive = true;
          break;
        }
      } catch (_) {}
    }

    // 3. Fallback: ICMP Ping
    if (!isAlive && _isScanning) {
      try {
        final ping = Ping(ip, count: 1, timeout: 1);
        final res = await ping.stream.first.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => PingData(),
        );
        if (res.response != null) {
          isAlive = true;
          pingTime = res.response?.time?.inMilliseconds ?? pingTime;
        }
      } catch (_) {}
    }

    // 4. Gateway fallback (gateway is always considered alive on its IP)
    if (isGw && !isAlive) {
      isAlive = true;
      pingTime = 1;
    }

    if (!isAlive) return null;

    // 5. Hostname resolution
    String hostname = isGw ? 'Router / Gateway' : 'Unknown';
    if (!isGw) {
      try {
        final addr = InternetAddress(ip);
        final reverse = await addr.reverse().timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => addr,
        );
        if (reverse.host != ip && reverse.host.isNotEmpty) {
          hostname = reverse.host;
        }
      } catch (_) {}
    }

    return NetworkDevice(
      ipAddress: ip,
      hostname: hostname,
      pingTimeMs: pingTime,
      isGateway: isGw,
      deviceType: isGw ? DeviceType.router : DeviceType.unknown,
    );
  }

  Future<List<NetworkDevice>> scan() async {
    if (_isScanning) return [];
    _isScanning = true;

    final foundDevices = <NetworkDevice>[];

    // Determine target IP range
    final gw = await gatewayIp;
    final myIp = await localIp;

    final referenceIp = gw ?? myIp ?? '192.168.1.1';
    final targetGw = gw ?? '${referenceIp.split('.')[0]}.${referenceIp.split('.')[1]}.${referenceIp.split('.')[2]}.1';
    final targetMyIp = myIp ?? '';

    final ips = _generateIpRange(referenceIp);
    final total = ips.length;
    int scanned = 0;

    // Scan in concurrent batches of 30
    const batchSize = 30;
    for (int i = 0; i < ips.length; i += batchSize) {
      if (!_isScanning) break;

      final batch = ips.skip(i).take(batchSize);
      final futures = batch.map((ip) => _probeHost(ip, targetGw, targetMyIp));
      final results = await Future.wait(futures);

      for (final device in results) {
        if (device != null) {
          // Avoid duplicate additions
          if (!foundDevices.any((d) => d.ipAddress == device.ipAddress)) {
            foundDevices.add(device);
            onDeviceFound?.call(device);
          }
        }
      }

      scanned += batch.length;
      onProgress?.call(scanned, total);
    }

    // Read ARP table for MAC & Vendor lookup
    final arpTable = await _getArpTable();

    // Enrich devices with MAC, vendor, and device type
    final enrichedDevices = foundDevices.map((device) {
      final mac = arpTable[device.ipAddress] ?? (device.isCurrentDevice ? 'This Device' : 'Unknown');
      final vendor = (mac != 'Unknown' && mac != 'This Device')
          ? VendorLookup.getVendor(mac)
          : (device.isCurrentDevice ? 'This Device' : 'Unknown');

      var type = device.deviceType;
      if (device.isGateway) {
        type = DeviceType.router;
      } else if (device.isCurrentDevice) {
        type = DeviceType.phone;
      } else if (vendor != 'Unknown') {
        type = VendorLookup.guessDeviceType(vendor);
      }

      return device.copyWith(
        macAddress: mac,
        vendor: vendor,
        deviceType: type,
      );
    }).toList();

    // Sort: Gateway first, Current Device second, then by numerical IP
    enrichedDevices.sort((a, b) {
      if (a.isGateway && !b.isGateway) return -1;
      if (!a.isGateway && b.isGateway) return 1;
      if (a.isCurrentDevice && !b.isCurrentDevice) return -1;
      if (!a.isCurrentDevice && b.isCurrentDevice) return 1;

      final aParts = a.ipAddress.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final bParts = b.ipAddress.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      for (int i = 0; i < 4; i++) {
        final aVal = i < aParts.length ? aParts[i] : 0;
        final bVal = i < bParts.length ? bParts[i] : 0;
        if (aVal != bVal) return aVal.compareTo(bVal);
      }
      return a.ipAddress.compareTo(b.ipAddress);
    });

    _isScanning = false;
    return enrichedDevices;
  }

  void stopScan() {
    _isScanning = false;
  }
}
