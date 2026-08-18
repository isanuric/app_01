import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TimeService {
  const TimeService();

  Future<DateTime> fetchDateTime() async {
    final uri = Uri.https('timeapi.io', '/api/Time/current/zone', {
      'timeZone': 'UTC',
    });
    debugPrint('TimeService: fetching $uri');
    try {
      final response = await http.get(uri);
      debugPrint('TimeService: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = DateTime.parse('${data['dateTime']}Z').toLocal();
        debugPrint('TimeService: utc=${data['dateTime']} -> local=$parsed');
        return parsed;
      }
    } catch (e) {
      debugPrint('TimeService: error=$e');
    }

    debugPrint('TimeService: API failed, falling back to device time');
    return DateTime.now();
  }
}
