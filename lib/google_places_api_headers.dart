import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// HTTP headers required when calling Google Maps Platform REST APIs from a
/// mobile app with application-restricted API keys.
///
/// See: https://developers.google.com/maps/api-security-best-practices
class GooglePlacesApiHeaders {
  GooglePlacesApiHeaders._();

  static PackageInfo? _packageInfo;

  /// Loads [PackageInfo] once. Safe to call multiple times.
  static Future<void> ensureInitialized() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
  }

  /// SHA-1 signing cert for [X-Android-Cert]: uppercase hex, no colons.
  static String normalizeSha1Cert(String sha1) {
    return sha1.replaceAll(':', '').replaceAll(' ', '').toUpperCase();
  }

  /// Builds platform headers for Places / Roads / Geocoding REST calls.
  ///
  /// [androidCertSha1] is required on Android when the API key is restricted
  /// to an app signing certificate (release and debug SHA-1 differ).
  static Future<Map<String, String>> build({
    String? androidPackageName,
    String? androidCertSha1,
    String? iosBundleIdentifier,
  }) async {
    if (kIsWeb) {
      return const <String, String>{};
    }

    await ensureInitialized();
    final PackageInfo info = _packageInfo!;

    if (Platform.isIOS) {
      final String bundleId = iosBundleIdentifier ?? info.packageName;
      if (bundleId.isEmpty) {
        return const <String, String>{};
      }
      return <String, String>{'X-Ios-Bundle-Identifier': bundleId};
    }

    if (Platform.isAndroid) {
      final String packageName = androidPackageName ?? info.packageName;
      if (packageName.isEmpty) {
        return const <String, String>{};
      }
      final Map<String, String> headers = <String, String>{
        'X-Android-Package': packageName,
      };
      final String? cert = androidCertSha1?.trim();
      if (cert != null && cert.isNotEmpty) {
        headers['X-Android-Cert'] = normalizeSha1Cert(cert);
      }
      return headers;
    }

    return const <String, String>{};
  }
}
