import '../../domain/entities/class_entry.dart';

class ClassEntryModel extends ClassEntry {
  const ClassEntryModel({
    required super.id,
    required super.subject,
    required super.startTime,
    required super.endTime,
    required super.room,
    required super.teacher,
    super.weekType,
    super.dateEvents,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'teacher': teacher,
        if (weekType != null) 'weekType': weekType,
        if (dateEvents != null) 'dateEvents': dateEvents,
      };

  factory ClassEntryModel.fromMap(Map<String, dynamic> map) => ClassEntryModel(
        id: map['id'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        startTime: map['startTime'] as String? ?? '',
        endTime: map['endTime'] as String? ?? '',
        room: map['room'] as String? ?? '',
        teacher: map['teacher'] as String? ?? '',
        weekType: map['weekType'] as String?,
        dateEvents: map['dateEvents'] != null
            ? Map<String, dynamic>.from(map['dateEvents'] as Map)
            : null,
      );
}
