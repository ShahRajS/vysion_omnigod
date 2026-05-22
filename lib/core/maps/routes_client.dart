import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:vysion_omnigod/app/config/app_config.dart';
import 'package:vysion_omnigod/core/result.dart';

/// Client to interface with Google Routes, Roads, and Places Proxy APIs.
class RoutesClient {
  /// Creates the routes client.
  RoutesClient({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Configuration provider references.
  final AppConfig config;

  final http.Client _client;

  /// Retrieves the API key depending on current platform.
  String get _apiKey {
    if (Platform.isAndroid) {
      return config.mapsApiKeyAndroid;
    } else if (Platform.isIOS) {
      return config.mapsApiKeyIos;
    }
    return '';
  }

  /// Calculates a walking route from [origin] to [destination].
  Future<Result<Map<String, dynamic>, Exception>> computeRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
      );
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-Fieldmask':
            'routes.duration,routes.distanceMeters,routes.legs.steps,routes.legs.polyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'travelMode': 'WALK',
        'units': 'METRIC',
      });

      final response = await _client.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(data);
      } else {
        return Failure(
          HttpException(
            'Failed to compute route: Status ${response.statusCode} - ${response.body}',
          ),
        );
      }
    } catch (e) {
      return Failure(Exception('Failed to calculate route: $e'));
    }
  }

  /// Snaps a series of [points] to the road network using Roads API.
  Future<Result<List<LatLng>, Exception>> snapToRoads(
    List<LatLng> points,
  ) async {
    try {
      if (points.isEmpty) {
        return const Success([]);
      }

      final pathQuery =
          points.map((p) => '${p.latitude},${p.longitude}').join('|');
      final url = Uri.parse(
        'https://roads.googleapis.com/v1/snapToRoads?path=$pathQuery&interpolate=true&key=$_apiKey',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final snappedPoints = <LatLng>[];

        if (data.containsKey('snappedPoints')) {
          final list = data['snappedPoints'] as List<dynamic>;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final location = item['location'] as Map<String, dynamic>;
              final latitude = location['latitude'] as double;
              final longitude = location['longitude'] as double;
              snappedPoints.add(LatLng(latitude, longitude));
            }
          }
        }

        return Success(snappedPoints);
      } else {
        return Failure(
          HttpException(
            'Failed to snap to roads: Status ${response.statusCode} - ${response.body}',
          ),
        );
      }
    } catch (e) {
      return Failure(Exception('Failed to snap points to roads: $e'));
    }
  }

  /// Searches for places via the restricted backend server proxy.
  Future<Result<List<Map<String, dynamic>>, Exception>> searchPlacesProxy({
    required String query,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('${config.backendBaseUrl}/v1/places/proxy');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({'query': query});

      final response = await _client.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final list = data.map((e) => e as Map<String, dynamic>).toList();
          return Success(list);
        }
        return const Success([]);
      } else {
        return Failure(
          HttpException(
            'Backend Places proxy failure: Status ${response.statusCode} - ${response.body}',
          ),
        );
      }
    } catch (e) {
      return Failure(Exception('Places proxy request failed: $e'));
    }
  }
}

/// Provider for the RoutesClient instance.
final routesClientProvider = Provider<RoutesClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return RoutesClient(config: config);
});
