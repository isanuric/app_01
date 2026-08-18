import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class TimeService {
  const TimeService();

  Future<DateTime> fetchDateTime() async {
    final position = await _fetchPosition();
    final response = await http.get(
      Uri.https('timeapi.io', '/api/Time/current/coordinate', {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load current time from the API.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DateTime.parse(data['dateTime'] as String);
  }

  Future<Position> _fetchPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied.');
    }

    return Geolocator.getCurrentPosition();
  }
}
