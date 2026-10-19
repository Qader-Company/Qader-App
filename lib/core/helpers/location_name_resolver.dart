import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

/// Best-effort area lookup; unavailable geocoding must not block nearby tasks.
class LocationNameResolver {
  static Future<String?> resolve(
    double latitude,
    double longitude,
    String localeIdentifier,
  ) async {
    try {
      final name = await _lookup(
        latitude,
        longitude,
        localeIdentifier,
      ).timeout(const Duration(seconds: 5));
      if (kDebugMode) {
        debugPrint(
          name == null
              ? '[LocationName] No area name returned by the device geocoder.'
              : '[LocationName] Area name resolved successfully.',
        );
      }
      return name;
    } catch (error) {
      if (kDebugMode) {
        final reason = switch (error) {
          MissingPluginException() =>
            'Plugin unavailable. Stop and rebuild the app.',
          TimeoutException() => 'Lookup timed out after 5 seconds.',
          PlatformException(:final code) => 'Device geocoder error: $code',
          _ => 'Lookup failed (${error.runtimeType}).',
        };
        debugPrint('[LocationName] $reason');
      }
      return null;
    }
  }

  static Future<String?> _lookup(
    double latitude,
    double longitude,
    String localeIdentifier,
  ) async {
    await setLocaleIdentifier(localeIdentifier);
    final places = await placemarkFromCoordinates(latitude, longitude);
    for (final place in places) {
      final parts = <String>{};
      // Prefer the district and city, rather than a building number/street.
      for (final value in [place.subLocality, place.locality]) {
        if (value != null && value.trim().isNotEmpty) parts.add(value.trim());
      }
      if (parts.isEmpty) {
        for (final value in [
          place.subAdministrativeArea,
          place.administrativeArea,
        ]) {
          if (value != null && value.trim().isNotEmpty) {
            parts.add(value.trim());
            break;
          }
        }
      }
      if (parts.isNotEmpty) {
        return parts.join(localeIdentifier.startsWith('ar') ? '، ' : ', ');
      }
    }
    return null;
  }
}
