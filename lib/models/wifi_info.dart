class WifiInfo {
  final String ssid;
  final String bssid;
  final int frequency;
  final String band;
  final int signalStrength;
  final String gatewayIp;
  final String localIp;
  final String subnetMask;
  final String broadcastAddress;

  const WifiInfo({
    this.ssid = 'Unknown',
    this.bssid = 'Unknown',
    this.frequency = 0,
    this.band = 'Unknown',
    this.signalStrength = 0,
    this.gatewayIp = 'Unknown',
    this.localIp = 'Unknown',
    this.subnetMask = '255.255.255.0',
    this.broadcastAddress = 'Unknown',
  });

  WifiInfo copyWith({
    String? ssid,
    String? bssid,
    int? frequency,
    String? band,
    int? signalStrength,
    String? gatewayIp,
    String? localIp,
    String? subnetMask,
    String? broadcastAddress,
  }) {
    return WifiInfo(
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      frequency: frequency ?? this.frequency,
      band: band ?? this.band,
      signalStrength: signalStrength ?? this.signalStrength,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      localIp: localIp ?? this.localIp,
      subnetMask: subnetMask ?? this.subnetMask,
      broadcastAddress: broadcastAddress ?? this.broadcastAddress,
    );
  }

  bool get isConnected => ssid != 'Unknown' && ssid.isNotEmpty;

  String get frequencyDisplay => frequency > 0 ? '${frequency} MHz' : 'N/A';

  String get bandColor => band == '5 GHz' ? 'blue' : 'green';

  @override
  String toString() =>
      'WifiInfo(ssid: $ssid, band: $band, freq: $frequency MHz, gateway: $gatewayIp)';
}
