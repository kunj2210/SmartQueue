class AppConstants {
  static const String appointmentsBox = 'appointments_box';
  static const String queueBox = 'queue_box';
  static const String appointmentsCollection = 'appointments';
  static const String queuesCollection = 'queues';
  static const String usersCollection = 'users';
  static const int maxAppointmentsPerSlot = 3;
  static const int avgServiceTimeMinutes = 15;

  static const List<String> serviceTypes = [
    'General Consultation',
    'Hair Cut & Styling',
    'Document Verification',
    'Lab Test',
    'Dental Checkup',
    'Eye Checkup',
    'Legal Advisory',
    'Financial Consultation',
  ];

  static const List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];
}
