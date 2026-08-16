import 'dart:convert';

import 'package:http/http.dart' as http;

class TimeService {
  const TimeService();

  static const _timeZone = 'Europe/Berlin';

  Future<DateTime> fetchDateTime() async {
    final response = await http.get(
      Uri.https('timeapi.io', '/api/Time/current/zone', {
        'timeZone': _timeZone,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Zeit konnte nicht geladen werden.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DateTime.parse(data['dateTime'] as String);
  }
}
