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
  
  // Callback for scan progress
  Function(int scanned, int total)? onProgress;
  Function(NetworkDevice device)? onDeviceFound;
  
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<String?> get gatewayIp async {
    try {
      final gateway = await _networkInfo.getWifiGatewayIP();
      return gateway;
    } catch (e) {
      return null;
    }
  }

  Future<String?> get localIp async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      return null;
    }
  }

  Future<String?> get wifiSubmask async {
    try {
      return await _networkInfo.getWifiSubmask();
    } catch (e) {
      return '255.255.255.0';
    }
  }

  Future<Map<String, String>> _getArpTable() async {
    try {
      final result = await _platform.invokeMethod('getArpTable');
      if (result is Map) {
        return Map<String, String>.from(result);
      }
    } catch (e) {
      // Platform channel not available, try alternative
    }
    return {};
  }

  List<String> _generateIpRange(String gateway) {
    final parts = gateway.split('.');
    if (parts.length != 4) return [];
    
    final baseIp = '${parts[0]}.${parts[1]}.${parts[2]}';
    final ips = <String>[];
    
    for (int i = 1; i <= 254; i++) {
      ips.add('$baseIp.$i');
    }
    return ips;
  }

  Future<NetworkDevice?> _pingHost(String ip, String gateway) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 2);
      final result = await ping.stream.first;
      
      if (result.response != null) {
        final pingTime = result.response?.time?.inMilliseconds ?? -1;
        return NetworkDevice(
          ipAddress: ip,
          pingTimeMs: pingTime,
          isGateway: ip == gateway,
          deviceType: ip == gateway ? DeviceType.router : DeviceType.unknown,
        );
      }
    } catch (e) {
      // Host not reachable
    }
    return null;
  }

  Future<List<NetworkDevice>> scan() async {
    if (_isScanning) return [];
    _isScanning = true;
    
    final devices = <NetworkDevice>[];
    final gateway = await gatewayIp;
    
    if (gateway == null) {
      _isScanning = false;
      return devices;
    }
    
    final ips = _generateIpRange(gateway);
    final total = ips.length;
    int scanned = 0;
    
    // Scan in batches of 20 concurrent pings
    const batchSize = 20;
    for (int i = 0; i < ips.length; i += batchSize) {
      if (!_isScanning) break;
      
      final batch = ips.skip(i).take(batchSize);
      final futures = batch.map((ip) => _pingHost(ip, gateway));
      final results = await Future.wait(futures);
      
      for (final device in results) {
        if (device != null) {
          devices.add(device);
          onDeviceFound?.call(device);
        }
      }
      
      scanned += batch.length;
      onProgress?.call(scanned, total);
    }
    
    // Get ARP table for MAC addresses
    final arpTable = await _getArpTable();
    
    // Enrich devices with MAC and vendor info
    final enrichedDevices = devices.map((device) {
      final mac = arpTable[device.ipAddress] ?? 'Unknown';
      final vendor = mac != 'Unknown' ? VendorLookup.getVendor(mac) : 'Unknown';
      final deviceType = device.isGateway 
          ? DeviceType.router 
          : VendorLookup.guessDeviceType(vendor);
      
      return device.copyWith(
        macAddress: mac,
        vendor: vendor,
        deviceType: deviceType,
      );
    }).toList();
    
    // Sort: gateway first, then by IP
    enrichedDevices.sort((a, b) {
      if (a.isGateway) return -1;
      if (b.isGateway) return 1;
      return a.ipAddress.compareTo(b.ipAddress);
    });
    
    _isScanning = false;
    return enrichedDevices;
  }

  void stopScan() {
    _isScanning = false;
  }
}

