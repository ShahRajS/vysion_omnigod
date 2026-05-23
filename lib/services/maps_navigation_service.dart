import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:vysion_omnigod/app/config/app_config.dart';

class TurnStep {
  TurnStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.startLocation,
  });

  final String instruction;
  final String maneuver;
  final int distanceMeters;
  final LatLng startLocation;
}

class MapsNavigationService {
  MapsNavigationService({required this.apiKey, required this.backendBaseUrl});

  final String apiKey;
  final String backendBaseUrl;
  final _tts = FlutterTts();

  final _positionController = StreamController<Position>.broadcast();
  final _stepsNotifier = ValueNotifier<List<TurnStep>>([]);
  final _stepIndexNotifier = ValueNotifier<int>(0);
  final _isNavigatingNotifier = ValueNotifier<bool>(false);
  final _polylineNotifier = ValueNotifier<List<LatLng>>([]);
  final _destinationNotifier = ValueNotifier<LatLng?>(null);

  StreamSubscription<Position>? _positionSub;

  Stream<Position> get positionStream => _positionController.stream;
  ValueNotifier<List<TurnStep>> get stepsNotifier => _stepsNotifier;
  ValueNotifier<int> get stepIndexNotifier => _stepIndexNotifier;
  ValueNotifier<bool> get isNavigatingNotifier => _isNavigatingNotifier;
  ValueNotifier<List<LatLng>> get polylineNotifier => _polylineNotifier;
  ValueNotifier<LatLng?> get destinationNotifier => _destinationNotifier;

  List<TurnStep> get steps => _stepsNotifier.value;
  int get currentStepIndex => _stepIndexNotifier.value;
  LatLng? get destination => _destinationNotifier.value;
  bool get isNavigating => _isNavigatingNotifier.value;

  TurnStep? get currentStep {
    final s = steps;
    final i = currentStepIndex;
    if (i < s.length) return s[i];
    return null;
  }

  Future<bool> startNavigation(String destinationQuery) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);

    final destLatLng = await _geocodeQuery(destinationQuery);
    if (destLatLng == null) return false;

    _destinationNotifier.value = destLatLng;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return false;

    final currentPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    final origin = LatLng(currentPos.latitude, currentPos.longitude);

    final routeOk = await _fetchDirections(origin, destLatLng);
    if (!routeOk) return false;

    _isNavigatingNotifier.value = true;

    if (steps.isNotEmpty) {
      await _tts.speak(steps.first.instruction);
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);

    return true;
  }

  void _onPositionUpdate(Position position) {
    _positionController.add(position);

    final idx = _stepIndexNotifier.value;
    if (idx >= steps.length) return;

    final stepLoc = steps[idx].startLocation;
    final dist = _distanceMeters(
      position.latitude,
      position.longitude,
      stepLoc.latitude,
      stepLoc.longitude,
    );

    if (dist < 15 && idx + 1 < steps.length) {
      _stepIndexNotifier.value = idx + 1;
      _tts.speak(steps[idx + 1].instruction);
    }

    if (destination != null) {
      final destDist = _distanceMeters(
        position.latitude,
        position.longitude,
        destination!.latitude,
        destination!.longitude,
      );
      if (destDist < 15) {
        _tts.speak('You have arrived at your destination.');
        stopNavigation();
      }
    }
  }

  Future<bool> _fetchDirections(LatLng origin, LatLng dest) async {
    try {
      final Uri url;
      if (kIsWeb) {
        url = Uri.parse('$backendBaseUrl/v1/maps/directions').replace(
          queryParameters: {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${dest.latitude},${dest.longitude}',
            'mode': 'walking',
          },
        );
      } else {
        url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${dest.latitude},${dest.longitude}'
          '&mode=walking'
          '&key=$apiKey',
        );
      }

      final response = await http.get(url);
      developer.log('Directions status: ${response.statusCode}');
      if (response.statusCode != 200) {
        developer.log('Directions body: ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        developer.log('Directions: no routes in response: $data');
        return false;
      }

      final route = routes[0] as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      final leg = legs[0] as Map<String, dynamic>;
      final apiSteps = leg['steps'] as List<dynamic>;

      final parsedSteps = <TurnStep>[];
      for (final step in apiSteps) {
        final s = step as Map<String, dynamic>;
        final instruction = _stripHtml(
          s['html_instructions'] as String? ?? '',
        );
        final maneuver = s['maneuver'] as String? ?? 'straight';
        final distance = s['distance'] as Map<String, dynamic>;
        final distMeters = distance['value'] as int;
        final startLoc = s['start_location'] as Map<String, dynamic>;

        parsedSteps.add(
          TurnStep(
            instruction: instruction,
            maneuver: maneuver,
            distanceMeters: distMeters,
            startLocation: LatLng(
              (startLoc['lat'] as num).toDouble(),
              (startLoc['lng'] as num).toDouble(),
            ),
          ),
        );
      }

      _stepsNotifier.value = parsedSteps;
      _stepIndexNotifier.value = 0;

      final polyline =
          route['overview_polyline'] as Map<String, dynamic>;
      final encoded = polyline['points'] as String;
      _polylineNotifier.value = _decodePolyline(encoded);

      return true;
    } catch (e) {
      developer.log('Directions API failed', error: e);
      return false;
    }
  }

  Future<LatLng?> _geocodeQuery(String query) async {
    try {
      final Uri url;
      if (kIsWeb) {
        url = Uri.parse('$backendBaseUrl/v1/maps/geocode').replace(
          queryParameters: {'address': query},
        );
      } else {
        url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(query)}'
          '&key=$apiKey',
        );
      }

      final response = await http.get(url);
      developer.log('Geocoding status: ${response.statusCode}');
      developer.log('Geocoding body: ${response.body}');
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final loc = (results[0] as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>;
      final latLng = loc['location'] as Map<String, dynamic>;
      return LatLng(
        (latLng['lat'] as num).toDouble(),
        (latLng['lng'] as num).toDouble(),
      );
    } catch (e) {
      developer.log('Geocoding failed', error: e);
      return null;
    }
  }

  Future<void> stopNavigation() async {
    _isNavigatingNotifier.value = false;
    _positionSub?.cancel();
    _positionSub = null;
    _stepsNotifier.value = [];
    _stepIndexNotifier.value = 0;
    _polylineNotifier.value = [];
    _destinationNotifier.value = null;
    await _tts.stop();
  }

  void dispose() {
    stopNavigation();
    _positionController.close();
    _stepsNotifier.dispose();
    _stepIndexNotifier.dispose();
    _isNavigatingNotifier.dispose();
    _polylineNotifier.dispose();
    _destinationNotifier.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    if (kIsWeb) return true;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]*>'), ' ').replaceAll('  ', ' ').trim();
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

  String get mapsApiKey => apiKey;

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

final mapsNavigationServiceProvider = Provider<MapsNavigationService>((ref) {
  final config = ref.watch(appConfigProvider);
  final apiKey = kIsWeb
      ? config.mapsApiKeyAndroid
      : (Platform.isAndroid ? config.mapsApiKeyAndroid : config.mapsApiKeyIos);
  final service = MapsNavigationService(
    apiKey: apiKey,
    backendBaseUrl: config.backendBaseUrl,
  );
  ref.onDispose(service.dispose);
  return service;
});
