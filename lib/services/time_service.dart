class TimeService {
  const TimeService();

  Future<DateTime> fetchDateTime() async => DateTime.now();
}