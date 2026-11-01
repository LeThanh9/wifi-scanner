import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_device.dart';
import '../models/wifi_info.dart';
import '../services/network_scanner.dart';
import '../services/wifi_service.dart';

// WiFi Info Provider
final wifiServiceProvider = Provider((ref) => WifiService());

final wifiInfoProvider = FutureProvider<WifiInfo>((ref) async {
  final wifiService = ref.read(wifiServiceProvider);
  return wifiService.getWifiInfo();
});

// Scanner State
class ScannerState {
  final List<NetworkDevice> devices;
  final bool isScanning;
  final int scannedCount;
  final int totalCount;
  final String? error;

  const ScannerState({
    this.devices = const [],
    this.isScanning = false,
    this.scannedCount = 0,
    this.totalCount = 254,
    this.error,
  });

  ScannerState copyWith({
    List<NetworkDevice>? devices,
    bool? isScanning,
    int? scannedCount,
    int? totalCount,
    String? error,
  }) {
    return ScannerState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      scannedCount: scannedCount ?? this.scannedCount,
      totalCount: totalCount ?? this.totalCount,
      error: error,
    );
  }

  double get progress => totalCount > 0 ? scannedCount / totalCount : 0;
}

// Scanner Notifier
class ScannerNotifier extends StateNotifier<ScannerState> {
  final NetworkScanner _scanner = NetworkScanner();

  ScannerNotifier() : super(const ScannerState());

  Future<void> startScan() async {
    if (state.isScanning) return;

    state = const ScannerState(isScanning: true);
    final foundDevices = <NetworkDevice>[];

    _scanner.onProgress = (scanned, total) {
      state = state.copyWith(scannedCount: scanned, totalCount: total);
    };

    _scanner.onDeviceFound = (device) {
      foundDevices.add(device);
      state = state.copyWith(devices: List.from(foundDevices));
    };

    try {
      final devices = await _scanner.scan();
      state = ScannerState(
        devices: devices,
        isScanning: false,
        scannedCount: 254,
        totalCount: 254,
      );
    } catch (e) {
      state = ScannerState(
        devices: foundDevices,
        isScanning: false,
        error: e.toString(),
      );
    }
  }

  void stopScan() {
    _scanner.stopScan();
    state = state.copyWith(isScanning: false);
  }
}

final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier();
});
