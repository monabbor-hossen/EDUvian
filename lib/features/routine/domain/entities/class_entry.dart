class ClassEntry {
  final String id;
  final String subject;
  final String startTime; // "HH:mm" 24-hour
  final String endTime;   // "HH:mm" 24-hour
  final String room;
  final String teacher;
  /// null = every week, 'A' = odd weeks only, 'B' = even weeks only
  final String? weekType;
  /// specific events for specific dates (key: "yyyy-MM-dd", value: Map or String)
  final Map<String, dynamic>? dateEvents;

  const ClassEntry({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacher,
    this.weekType,
    this.dateEvents,
  });

  /// True if this class should be shown in the current week.
  bool get isThisWeek => isThisWeekFor(DateTime.now());

  bool isThisWeekFor(DateTime date) {
    if (weekType == null) return true;
    return weekType == weekTypeFor(date);
  }

  String? getEventText(String dateStr) {
    if (dateEvents == null || !dateEvents!.containsKey(dateStr)) return null;
    final val = dateEvents![dateStr];
    if (val is String) return val;
    if (val is Map) return val['text'] as String?;
    return null;
  }

  String? getEventStartTime(String dateStr) {
    if (dateEvents == null || !dateEvents!.containsKey(dateStr)) return null;
    final val = dateEvents![dateStr];
    if (val is Map) return val['startTime'] as String?;
    return null;
  }

  String? getEventEndTime(String dateStr) {
    if (dateEvents == null || !dateEvents!.containsKey(dateStr)) return null;
    final val = dateEvents![dateStr];
    if (val is Map) return val['endTime'] as String?;
    return null;
  }

  String? getEventRoom(String dateStr) {
    if (dateEvents == null || !dateEvents!.containsKey(dateStr)) return null;
    final val = dateEvents![dateStr];
    if (val is Map) return val['room'] as String?;
    return null;
  }

  ClassEntry copyWith({
    String? id,
    String? subject,
    String? startTime,
    String? endTime,
    String? room,
    String? teacher,
    Object? weekType = _sentinel,
    Object? dateEvents = _sentinel,
  }) => ClassEntry(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    room: room ?? this.room,
    teacher: teacher ?? this.teacher,
    weekType: weekType == _sentinel ? this.weekType : weekType as String?,
    dateEvents: dateEvents == _sentinel ? this.dateEvents : dateEvents as Map<String, dynamic>?,
  );

  static const Object _sentinel = Object();

  /// True if current time falls within this class period.
  bool get isOngoing {
    final s = _toMinutes(startTime);
    final e = _toMinutes(endTime);
    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    return s != null && e != null && now >= s && now < e;
  }

  /// Minutes since midnight for sorting by start time.
  int get startMinutes => _toMinutes(startTime) ?? 0;

  static int? _toMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  // ISO week and weekType logic moved to a static core logic in Domain
  static int isoWeekFor(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    return ((days + startOfYear.weekday - 1) ~/ 7) + 1;
  }

  static String weekTypeFor(DateTime date) => isoWeekFor(date).isOdd ? 'A' : 'B';
}
