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
  final String networkType;

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
    this.networkType = 'wifi',
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
    String? networkType,
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
      networkType: networkType ?? this.networkType,
    );
  }

  bool get isConnected =>
      (ssid != 'Unknown' && ssid.isNotEmpty && ssid != '<unknown ssid>') ||
      (localIp != 'Unknown' && localIp.isNotEmpty && localIp != '0.0.0.0');

  String get displayName {
    if (ssid.isNotEmpty && ssid != 'Unknown' && ssid != '<unknown ssid>') {
      return ssid;
    }
    if (localIp != 'Unknown' && localIp.isNotEmpty && localIp != '0.0.0.0') {
      return 'Connected Network ($localIp)';
    }
    return 'Not Connected';
  }

  String get frequencyDisplay {
    if (frequency <= 0) return 'N/A';
    return '$frequency MHz';
  }

  String get bandDisplay {
    if (band != 'Unknown' && band.isNotEmpty) return band;
    if (frequency > 0) {
      if (frequency < 3000) return '2.4 GHz';
      if (frequency >= 5000 && frequency < 5900) return '5 GHz';
      if (frequency >= 5900) return '6 GHz';
    }
    return 'Wi-Fi / LAN';
  }

  @override
  String toString() =>
      'WifiInfo(name: $displayName, band: $bandDisplay, freq: $frequency MHz, gateway: $gatewayIp, ip: $localIp)';
}
