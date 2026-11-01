package com.wifiscanner.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileReader
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wifiscanner.app/network"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkDetails" -> {
                    try {
                        val response = HashMap<String, Any?>()
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                        val connManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager

                        var frequency = 0
                        var rssi = 0
                        var linkSpeed = 0
                        var ssid = ""
                        var bssid = ""
                        var gateway = ""
                        var localIp = ""
                        var netmask = "255.255.255.0"
                        var networkType = "unknown"

                        // 1. WifiManager info
                        wifiManager?.let { wm ->
                            val info = wm.connectionInfo
                            if (info != null) {
                                frequency = info.frequency
                                rssi = info.rssi
                                linkSpeed = info.linkSpeed
                                val rawSsid = info.ssid
                                if (rawSsid != null && rawSsid != "<unknown ssid>") {
                                    ssid = rawSsid.replace("\"", "")
                                }
                                val rawBssid = info.bssid
                                if (rawBssid != null && rawBssid != "02:00:00:00:00:00") {
                                    bssid = rawBssid
                                }
                            }

                            val dhcp = wm.dhcpInfo
                            if (dhcp != null) {
                                if (dhcp.gateway != 0) {
                                    gateway = intToIp(dhcp.gateway)
                                }
                                if (dhcp.ipAddress != 0) {
                                    localIp = intToIp(dhcp.ipAddress)
                                }
                                if (dhcp.netmask != 0) {
                                    netmask = intToIp(dhcp.netmask)
                                }
                            }
                        }

                        // 2. ConnectivityManager / LinkProperties
                        connManager?.let { cm ->
                            val activeNet = cm.activeNetwork
                            if (activeNet != null) {
                                val caps = cm.getNetworkCapabilities(activeNet)
                                if (caps != null) {
                                    networkType = when {
                                        caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                                        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                                        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                                        caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                                        else -> "other"
                                    }
                                }

                                val linkProps = cm.getLinkProperties(activeNet)
                                if (linkProps != null) {
                                    for (route in linkProps.routes) {
                                        if (route.isDefaultRoute && route.gateway is Inet4Address) {
                                            val gw = route.gateway?.hostAddress
                                            if (!gw.isNullOrEmpty() && gw != "0.0.0.0") {
                                                gateway = gw
                                            }
                                        }
                                    }

                                    for (linkAddr in linkProps.linkAddresses) {
                                        val addr = linkAddr.address
                                        if (addr is Inet4Address && !addr.isLoopbackAddress) {
                                            val ipStr = addr.hostAddress
                                            if (!ipStr.isNullOrEmpty() && (localIp.isEmpty() || localIp == "0.0.0.0")) {
                                                localIp = ipStr
                                            }
                                            val prefix = linkAddr.prefixLength
                                            if (prefix in 1..32) {
                                                netmask = prefixToNetmask(prefix)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Fallback: NetworkInterface
                        if (localIp.isEmpty() || localIp == "0.0.0.0") {
                            try {
                                val ifaces = NetworkInterface.getNetworkInterfaces()
                                while (ifaces.hasMoreElements()) {
                                    val iface = ifaces.nextElement()
                                    val addrs = iface.inetAddresses
                                    while (addrs.hasMoreElements()) {
                                        val addr = addrs.nextElement()
                                        if (!addr.isLoopbackAddress && addr is Inet4Address) {
                                            val h = addr.hostAddress
                                            if (!h.isNullOrEmpty()) {
                                                localIp = h
                                                break
                                            }
                                        }
                                    }
                                    if (localIp.isNotEmpty()) break
                                }
                            } catch (_: Exception) {}
                        }

                        // 4. Fallback gateway from localIp
                        if ((gateway.isEmpty() || gateway == "0.0.0.0") && localIp.isNotEmpty()) {
                            val parts = localIp.split(".")
                            if (parts.size == 4) {
                                gateway = "${parts[0]}.${parts[1]}.${parts[2]}.1"
                            }
                        }

                        response["frequency"] = frequency
                        response["rssi"] = rssi
                        response["linkSpeed"] = linkSpeed
                        response["ssid"] = ssid
                        response["bssid"] = bssid
                        response["gateway"] = gateway
                        response["localIp"] = localIp
                        response["netmask"] = netmask
                        response["networkType"] = networkType

                        result.success(response)
                    } catch (e: Exception) {
                        result.error("NET_ERROR", e.message ?: "Unknown error", null)
                    }
                }
                "getWifiFrequency" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                        val wifiInfo = wifiManager?.connectionInfo
                        val response = HashMap<String, Any>()
                        response["frequency"] = wifiInfo?.frequency ?: 0
                        response["rssi"] = wifiInfo?.rssi ?: 0
                        response["linkSpeed"] = wifiInfo?.linkSpeed ?: 0
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("WIFI_ERROR", e.message ?: "Error", null)
                    }
                }
                "getArpTable" -> {
                    val arpTable = HashMap<String, String>()
                    try {
                        val br = BufferedReader(FileReader("/proc/net/arp"))
                        var line: String?
                        br.readLine() // skip header
                        while (br.readLine().also { line = it } != null) {
                            val parts = line!!.trim().split("\\s+".toRegex())
                            if (parts.size >= 4) {
                                val ip = parts[0]
                                val mac = parts[3]
                                if (mac != "00:00:00:00:00:00") {
                                    arpTable[ip] = mac.uppercase()
                                }
                            }
                        }
                        br.close()
                    } catch (_: Exception) {}
                    result.success(arpTable)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun intToIp(i: Int): String {
        return "${i and 0xFF}.${(i shr 8) and 0xFF}.${(i shr 16) and 0xFF}.${(i shr 24) and 0xFF}"
    }

    private fun prefixToNetmask(prefix: Int): String {
        val mask = (0xffffffffL shl (32 - prefix)) and 0xffffffffL
        return "${(mask shr 24) and 0xff}.${(mask shr 16) and 0xff}.${(mask shr 8) and 0xff}.${mask and 0xff}"
    }
}
