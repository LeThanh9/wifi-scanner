# WiFi Network Scanner

Ứng dụng quét mạng WiFi - phát hiện tất cả thiết bị trên mạng cục bộ.

## Tính năng

- 📡 Phát hiện băng tần WiFi (2.4GHz / 5GHz)
- 🔍 Quét tất cả thiết bị trên mạng
- 📱 Hiển thị IP, MAC, hostname của thiết bị
- 🏭 Tra cứu nhà sản xuất theo MAC address
- 🎨 Giao diện Material Design 3
- 🌙 Hỗ trợ Dark/Light theme

## Cài đặt

Tải APK từ [Releases](../../releases/latest).

## Build

```bash
flutter pub get
flutter build apk --release
```

## Permissions

- ACCESS_WIFI_STATE - Đọc thông tin WiFi
- ACCESS_NETWORK_STATE - Kiểm tra kết nối mạng
- ACCESS_FINE_LOCATION - Truy cập SSID WiFi
- INTERNET - Quét mạng

