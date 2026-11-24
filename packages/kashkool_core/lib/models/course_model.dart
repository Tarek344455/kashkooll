/// Curriculum tree: Grade -> Subject -> Unit -> Lecture/Live/PDF.

class CourseModel {
  final String courseId;
  final String grade;
  final String subject;
  final String unit;
  final String lectureId;
  final String title;
  final String description;
  final String mediaType;
  final String? drmKeyId;
  final int durationMinutes;
  final bool isLocked;

  const CourseModel({
    required this.courseId,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.lectureId,
    required this.title,
    required this.description,
    required this.mediaType,
    this.drmKeyId,
    required this.durationMinutes,
    required this.isLocked,
  });

  CourseModel copyWith({
    String? courseId,
    String? grade,
    String? subject,
    String? unit,
    String? lectureId,
    String? title,
    String? description,
    String? mediaType,
    String? drmKeyId,
    int? durationMinutes,
    bool? isLocked,
  }) => CourseModel(
    courseId: courseId ?? this.courseId,
    grade: grade ?? this.grade,
    subject: subject ?? this.subject,
    unit: unit ?? this.unit,
    lectureId: lectureId ?? this.lectureId,
    title: title ?? this.title,
    description: description ?? this.description,
    mediaType: mediaType ?? this.mediaType,
    drmKeyId: drmKeyId ?? this.drmKeyId,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    isLocked: isLocked ?? this.isLocked,
  );

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'grade': grade,
      'subject': subject,
      'unit': unit,
      'lectureId': lectureId,
      'title': title,
      'description': description,
      'mediaType': mediaType,
      'drmKeyId': drmKeyId,
      'durationMinutes': durationMinutes,
      'isLocked': isLocked,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['courseId'] as String,
      grade: map['grade'] as String,
      subject: map['subject'] as String,
      unit: map['unit'] as String,
      lectureId: map['lectureId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      mediaType: map['mediaType'] as String,
      drmKeyId: map['drmKeyId'] as String?,
      durationMinutes: map['durationMinutes'] as int,
      isLocked: map['isLocked'] as bool,
    );
  }

  @override
  String toString() => '$grade - $subject / $unit - $title';
}
