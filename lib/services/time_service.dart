import 'dart:convert';

import 'package:http/http.dart' as http;

class TimeService {
  const TimeService();

  Future<DateTime> fetchDateTime() async {
    final uri = Uri.https('timeapi.io', '/api/Time/current/zone', {
      'timeZone': 'UTC',
    });
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DateTime.parse('${data['dateTime']}Z').toLocal();
      }
    } catch (e) {
      // ignore
    }

    return DateTime.now();
  }
}
