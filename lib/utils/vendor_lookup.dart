import '../models/network_device.dart';

class VendorLookup {
  // Common MAC address prefixes (OUI) to vendor mapping
  static const Map<String, String> _vendorPrefixes = {
    '00:50:56': 'VMware',
    '00:0C:29': 'VMware',
    '00:1A:11': 'Google',
    '3C:5A:B4': 'Google',
    'F4:F5:D8': 'Google',
    'A4:77:33': 'Google',
    '54:60:09': 'Google',
    '00:1E:C2': 'Apple',
    '00:25:00': 'Apple',
    '00:26:BB': 'Apple',
    '3C:15:C2': 'Apple',
    'A8:51:AB': 'Apple',
    'AC:BC:32': 'Apple',
    'D0:03:4B': 'Apple',
    'F0:DB:F8': 'Apple',
    '78:7B:8A': 'Apple',
    'B8:27:EB': 'Raspberry Pi',
    'DC:A6:32': 'Raspberry Pi',
    'E4:5F:01': 'Raspberry Pi',
    '00:15:5D': 'Microsoft',
    '00:50:F2': 'Microsoft',
    '28:18:78': 'Microsoft',
    '7C:1E:52': 'Microsoft',
    '60:45:BD': 'Microsoft',
    '00:E0:4C': 'Realtek',
    '00:04:4B': 'Nvidia',
    '48:B0:2D': 'Nvidia',
    '00:1B:21': 'Intel',
    '00:1E:65': 'Intel',
    '00:1F:3B': 'Intel',
    '3C:97:0E': 'Intel',
    '68:05:CA': 'Intel',
    'A4:C4:94': 'Intel',
    '08:00:27': 'Oracle VirtualBox',
    '00:17:88': 'Philips Hue',
    '00:1D:C9': 'Huawei',
    '00:25:9E': 'Huawei',
    '00:46:4B': 'Huawei',
    '20:F1:7C': 'Huawei',
    '48:46:FB': 'Huawei',
    '70:72:0D': 'Huawei',
    '00:09:41': 'HP',
    '00:1A:4B': 'HP',
    '00:1E:0B': 'HP',
    '3C:D9:2B': 'HP',
    '00:16:3E': 'Xen',
    '00:1C:42': 'Parallels',
    '00:26:5A': 'D-Link',
    '1C:7E:E5': 'D-Link',
    '28:10:7B': 'D-Link',
    'C8:D3:A3': 'D-Link',
    '00:14:6C': 'TP-Link',
    '00:27:19': 'TP-Link',
    '50:C7:BF': 'TP-Link',
    '54:C8:0F': 'TP-Link',
    'EC:08:6B': 'TP-Link',
    'E8:48:B8': 'TP-Link',
    '10:FE:ED': 'TP-Link',
    '00:24:01': 'Netgear',
    '00:26:F2': 'Netgear',
    '20:0C:C8': 'Netgear',
    'C0:3F:0E': 'Netgear',
    'E4:F4:C6': 'Netgear',
    '00:1D:7E': 'Linksys',
    '00:25:9C': 'Cisco/Linksys',
    '20:AA:4B': 'Cisco/Linksys',
    '00:18:0A': 'Cisco',
    '00:24:50': 'Cisco',
    'F8:C2:88': 'Samsung',
    '00:16:32': 'Samsung',
    '00:21:19': 'Samsung',
    '30:CD:A7': 'Samsung',
    '5C:3A:45': 'Samsung',
    '84:25:DB': 'Samsung',
    'A8:06:00': 'Samsung',
    '78:02:F8': 'Xiaomi',
    '9C:99:A0': 'Xiaomi',
    '64:B4:73': 'Xiaomi',
    '28:6C:07': 'Xiaomi',
    'FC:64:BA': 'Xiaomi',
    '50:64:2B': 'Amazon',
    '68:54:FD': 'Amazon',
    'A0:02:DC': 'Amazon',
    'F0:D2:F1': 'Amazon',
    '00:BB:3A': 'Amazon',
    '00:04:20': 'Sony',
    '00:13:A9': 'Sony',
    '00:1A:80': 'Sony',
    'AC:9B:0A': 'Sony',
    'FC:0F:E6': 'Sony',
    '00:24:E4': 'LG',
    '10:68:3F': 'LG',
    'A8:23:FE': 'LG',
    'CC:2D:83': 'LG',
    '00:04:F3': 'ASUS',
    '00:1F:C6': 'ASUS',
    '2C:4D:54': 'ASUS',
    '60:45:CB': 'ASUS',
    'F0:79:59': 'ASUS',
  };

  static String getVendor(String macAddress) {
    if (macAddress == 'Unknown' || macAddress.isEmpty) return 'Unknown';
    
    final prefix = macAddress.toUpperCase().substring(0, 8);
    return _vendorPrefixes[prefix] ?? 'Unknown';
  }

  static DeviceType guessDeviceType(String vendor) {
    final v = vendor.toLowerCase();
    
    if (v.contains('tp-link') || v.contains('netgear') || v.contains('linksys') ||
        v.contains('d-link') || v.contains('cisco') || v.contains('asus') ||
        v.contains('huawei')) {
      return DeviceType.router;
    }
    if (v.contains('apple') || v.contains('samsung') || v.contains('xiaomi') ||
        v.contains('sony') || v.contains('lg') || v.contains('huawei')) {
      return DeviceType.phone;
    }
    if (v.contains('intel') || v.contains('microsoft') || v.contains('hp') ||
        v.contains('realtek') || v.contains('nvidia')) {
      return DeviceType.computer;
    }
    if (v.contains('amazon') || v.contains('google')) {
      return DeviceType.iot;
    }
    if (v.contains('philips')) {
      return DeviceType.iot;
    }
    if (v.contains('raspberry')) {
      return DeviceType.server;
    }
    if (v.contains('vmware') || v.contains('virtualbox') || 
        v.contains('parallels') || v.contains('xen')) {
      return DeviceType.server;
    }
    
    return DeviceType.unknown;
  }
}

