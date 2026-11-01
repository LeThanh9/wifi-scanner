package com.wifiscanner.app

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wifiscanner.app/network"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWifiFrequency" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        val frequency = wifiInfo.frequency
                        val rssi = wifiInfo.rssi

                        val response = HashMap<String, Any>()
                        response["frequency"] = frequency
                        response["rssi"] = rssi
                        response["linkSpeed"] = wifiInfo.linkSpeed
                        
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("WIFI_ERROR", "Failed to get WiFi frequency: ${e.message}", null)
                    }
                }
                "getArpTable" -> {
                    try {
                        val arpTable = HashMap<String, String>()
                        val br = BufferedReader(FileReader("/proc/net/arp"))
                        var line: String?
                        
                        // Skip header line
                        br.readLine()
                        
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
                        
                        result.success(arpTable)
                    } catch (e: Exception) {
                        result.error("ARP_ERROR", "Failed to read ARP table: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

