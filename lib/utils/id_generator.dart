import 'dart:math';
import 'package:intl/intl.dart';

class IdGenerator {
  static String generateAppointmentId() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'APT-$date-$suffix';
  }
}
