import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/scanner_provider.dart';
import '../widgets/wifi_info_card.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _requestPermissions();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await [
        Permission.locationWhenInUse,
        Permission.nearbyWifiDevices,
      ].request();
    } catch (_) {}
    if (mounted) {
      ref.invalidate(wifiInfoProvider);
    }
  }

  void _startScan() {
    _scanAnimController.repeat();
    ref.invalidate(wifiInfoProvider);
    ref.read(scannerProvider.notifier).startScan().then((_) {
      if (mounted) {
        _scanAnimController.stop();
        _scanAnimController.reset();
      }
    });
  }

  void _stopScan() {
    ref.read(scannerProvider.notifier).stopScan();
    _scanAnimController.stop();
    _scanAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);
    final wifiInfoAsync = ref.watch(wifiInfoProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(wifiInfoProvider);
          _startScan();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Quét Mạng WiFi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(wifiInfoProvider);
                    if (!scanState.isScanning) _startScan();
                  },
                  tooltip: 'Làm mới',
                ),
                IconButton(
                  icon: const Icon(Icons.brightness_6),
                  onPressed: widget.onToggleTheme,
                  tooltip: 'Chế độ Sáng / Tối',
                ),
              ],
            ),

            // WiFi Info Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: wifiInfoAsync.when(
                  data: (wifiInfo) => WifiInfoCard(wifiInfo: wifiInfo),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Lỗi tải thông tin mạng: $e'),
                    ),
                  ),
                ),
              ),
            ),

            // Scan Progress Bar
            if (scanState.isScanning)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đang quét... ${scanState.scannedCount}/${scanState.totalCount} IPs (${(scanState.progress * 100).toInt()}%)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${scanState.devices.length} tìm thấy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: scanState.progress,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Discovered Header
            if (!scanState.isScanning && scanState.devices.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Icon(Icons.devices, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Đã tìm thấy ${scanState.devices.length} thiết bị',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Device List
            if (scanState.devices.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final device = scanState.devices[index];
                    return DeviceCard(
                      device: device,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeviceDetailScreen(device: device),
                          ),
                        );
                      },
                    );
                  },
                  childCount: scanState.devices.length,
                ),
              ),

            // Empty State
            if (!scanState.isScanning && scanState.devices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radar,
                          size: 72,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sẵn sàng quét mọi mạng',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hỗ trợ Wi-Fi 2.4GHz, 5GHz, 6GHz, Hotspot di động và mạng LAN nội bộ.\nBấm nút bên dưới để bắt đầu quét!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 90),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanState.isScanning ? _stopScan : _startScan,
        icon: scanState.isScanning
            ? const Icon(Icons.stop)
            : RotationTransition(
                turns: _scanAnimController,
                child: const Icon(Icons.radar),
              ),
        label: Text(scanState.isScanning ? 'Dừng quét' : 'Quét Toàn Mạng'),
        backgroundColor: scanState.isScanning
            ? colorScheme.error
            : colorScheme.primaryContainer,
        foregroundColor: scanState.isScanning
            ? colorScheme.onError
            : colorScheme.onPrimaryContainer,
      ),
    );
  }
}
