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
  bool _permissionsGranted = false;

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
    final locationStatus = await Permission.locationWhenInUse.request();
    setState(() {
      _permissionsGranted = locationStatus.isGranted;
    });
    
    if (_permissionsGranted) {
      ref.invalidate(wifiInfoProvider);
    }
  }

  void _startScan() {
    if (!_permissionsGranted) {
      _requestPermissions();
      return;
    }
    _scanAnimController.repeat();
    ref.read(scannerProvider.notifier).startScan().then((_) {
      _scanAnimController.stop();
      _scanAnimController.reset();
    });
    ref.invalidate(wifiInfoProvider);
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
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'WiFi Scanner',
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
                icon: const Icon(Icons.brightness_6),
                onPressed: widget.onToggleTheme,
                tooltip: 'Toggle Theme',
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
                    child: Text('Error loading WiFi info: $e'),
                  ),
                ),
              ),
            ),
          ),

          // Scan Progress
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
                          'Scanning... ${scanState.scannedCount}/${scanState.totalCount}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${scanState.devices.length} found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
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

          // Device Count Header
          if (!scanState.isScanning && scanState.devices.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Icon(Icons.devices, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${scanState.devices.length} Devices Found',
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_find,
                      size: 80,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap the scan button to\ndiscover devices',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error State
          if (scanState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            scanState.error!,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanState.isScanning ? _stopScan : _startScan,
        icon: scanState.isScanning
            ? const Icon(Icons.stop)
            : RotationTransition(
                turns: _scanAnimController,
                child: const Icon(Icons.radar),
              ),
        label: Text(scanState.isScanning ? 'Stop' : 'Scan Network'),
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

