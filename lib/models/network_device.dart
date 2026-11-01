class NetworkDevice {
  final String ipAddress;
  final String macAddress;
  final String hostname;
  final String vendor;
  final DeviceType deviceType;
  final int pingTimeMs;
  final bool isGateway;

  const NetworkDevice({
    required this.ipAddress,
    this.macAddress = 'Unknown',
    this.hostname = 'Unknown',
    this.vendor = 'Unknown',
    this.deviceType = DeviceType.unknown,
    this.pingTimeMs = -1,
    this.isGateway = false,
  });

  NetworkDevice copyWith({
    String? ipAddress,
    String? macAddress,
    String? hostname,
    String? vendor,
    DeviceType? deviceType,
    int? pingTimeMs,
    bool? isGateway,
  }) {
    return NetworkDevice(
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      hostname: hostname ?? this.hostname,
      vendor: vendor ?? this.vendor,
      deviceType: deviceType ?? this.deviceType,
      pingTimeMs: pingTimeMs ?? this.pingTimeMs,
      isGateway: isGateway ?? this.isGateway,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkDevice &&
          runtimeType == other.runtimeType &&
          ipAddress == other.ipAddress;

  @override
  int get hashCode => ipAddress.hashCode;

  @override
  String toString() =>
      'NetworkDevice(ip: $ipAddress, mac: $macAddress, host: $hostname, vendor: $vendor)';
}

enum DeviceType {
  router,
  phone,
  computer,
  tablet,
  printer,
  tv,
  iot,
  server,
  camera,
  unknown;

  String get displayName {
    switch (this) {
      case DeviceType.router:
        return 'Router / Gateway';
      case DeviceType.phone:
        return 'Phone';
      case DeviceType.computer:
        return 'Computer';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.printer:
        return 'Printer';
      case DeviceType.tv:
        return 'Smart TV';
      case DeviceType.iot:
        return 'IoT Device';
      case DeviceType.server:
        return 'Server';
      case DeviceType.camera:
        return 'Camera';
      case DeviceType.unknown:
        return 'Unknown Device';
    }
  }
}
