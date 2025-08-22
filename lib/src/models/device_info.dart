import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Contains device and application information
class DeviceInfo {
  /// Device model
  final String? deviceModel;
  
  /// Operating system
  final String? operatingSystem;
  
  /// OS version
  final String? osVersion;
  
  /// App name
  final String? appName;
  
  /// App version
  final String? appVersion;
  
  /// App build number
  final String? buildNumber;
  
  /// Package name
  final String? packageName;
  
  /// Device identifier
  final String? deviceId;
  
  /// Available memory (in MB)
  final int? availableMemory;
  
  /// Device manufacturer
  final String? manufacturer;
  
  /// Screen size
  final String? screenSize;

  const DeviceInfo({
    this.deviceModel,
    this.operatingSystem,
    this.osVersion,
    this.appName,
    this.appVersion,
    this.buildNumber,
    this.packageName,
    this.deviceId,
    this.availableMemory,
    this.manufacturer,
    this.screenSize,
  });

  /// Collects device and app information
  static Future<DeviceInfo> collect() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String? deviceModel;
      String? operatingSystem;
      String? osVersion;
      String? deviceId;
      String? manufacturer;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceModel = androidInfo.model;
        operatingSystem = 'Android';
        osVersion = androidInfo.version.release;
        deviceId = androidInfo.id;
        manufacturer = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.model;
        operatingSystem = 'iOS';
        osVersion = iosInfo.systemVersion;
        deviceId = iosInfo.identifierForVendor;
        manufacturer = 'Apple';
      } else if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceModel = webInfo.browserName.name;
        operatingSystem = webInfo.platform ?? 'Web';
        osVersion = webInfo.appVersion;
        deviceId = webInfo.vendor;
        manufacturer = webInfo.vendor;
      }

      return DeviceInfo(
        deviceModel: deviceModel,
        operatingSystem: operatingSystem,
        osVersion: osVersion,
        appName: packageInfo.appName,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        packageName: packageInfo.packageName,
        deviceId: deviceId,
        manufacturer: manufacturer,
      );
    } catch (e) {
      // Return empty device info if collection fails
      return const DeviceInfo();
    }
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'osVersion': osVersion,
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'packageName': packageName,
      'deviceId': deviceId,
      'availableMemory': availableMemory,
      'manufacturer': manufacturer,
      'screenSize': screenSize,
    };
  }

  /// Creates DeviceInfo from JSON map
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceModel: json['deviceModel'],
      operatingSystem: json['operatingSystem'],
      osVersion: json['osVersion'],
      appName: json['appName'],
      appVersion: json['appVersion'],
      buildNumber: json['buildNumber'],
      packageName: json['packageName'],
      deviceId: json['deviceId'],
      availableMemory: json['availableMemory'],
      manufacturer: json['manufacturer'],
      screenSize: json['screenSize'],
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(model: $deviceModel, os: $operatingSystem $osVersion, '
           'app: $appName $appVersion, manufacturer: $manufacturer)';
  }
}
