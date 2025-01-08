import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

final _channel = MethodChannel('flutter_image_saver');

/// Save image data to file
Future<String> saveImage(
  Uint8List data,
  String filename,
) async {
  final file = XFile.fromData(data, name: filename);
  String path = filename;
  if (!file.path.startsWith('/')) {
    if (UniversalPlatform.isDesktop) {
      path = '${(await getDownloadsDirectory())?.path}/$path';
    } else if (UniversalPlatform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo android = await deviceInfo.androidInfo;

      if (android.version.sdkInt < 33) {
        if (await Permission.storage.request().isGranted) {
          path = '${await _channel.invokeMethod('getPicturesDirectory')}/$path';
        } else if (await Permission.storage.request().isPermanentlyDenied) {
          openAppSettings();
        }
      } else {
        if (!await Permission.photos.request().isGranted) {
          path = '${await _channel.invokeMethod('getPicturesDirectory')}/$path';
        } else if (await Permission.photos.request().isPermanentlyDenied) {
          openAppSettings();
        }
      }
    }
  }
  if (UniversalPlatform.isIOS) {
    path = '';
    await _channel.invokeMethod('saveImage', data);
  } else {
    await file.saveTo(path);
  }
  if (UniversalPlatform.isAndroid) {
    _channel.invokeMethod('scanFile', path.replaceAll('/$filename', ''));
  }
  return path;
}
