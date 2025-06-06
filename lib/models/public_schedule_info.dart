class PublicScheduleInfo {
  final String id;
  final String name;
  final String description;
  final String file;

  PublicScheduleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.file,
  });

  factory PublicScheduleInfo.fromJson(Map<String, dynamic> json) {
    return PublicScheduleInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      file: json['file'],
    );
  }
}
