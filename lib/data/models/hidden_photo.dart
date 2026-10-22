class HiddenPhoto {
  final String id;
  final String encryptedPath;
  final String originalName;
  final DateTime dateAdded;
  final int fileSize;
  final int? width;
  final int? height;

  const HiddenPhoto({
    required this.id,
    required this.encryptedPath,
    required this.originalName,
    required this.dateAdded,
    required this.fileSize,
    this.width,
    this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encrypted_path': encryptedPath,
      'original_name': originalName,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'file_size': fileSize,
      'width': width,
      'height': height,
    };
  }

  factory HiddenPhoto.fromMap(Map<String, dynamic> map) {
    return HiddenPhoto(
      id: map['id'] as String,
      encryptedPath: map['encrypted_path'] as String,
      originalName: map['original_name'] as String,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
      fileSize: map['file_size'] as int,
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }

  HiddenPhoto copyWith({
    String? id,
    String? encryptedPath,
    String? originalName,
    DateTime? dateAdded,
    int? fileSize,
    int? width,
    int? height,
  }) {
    return HiddenPhoto(
      id: id ?? this.id,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      originalName: originalName ?? this.originalName,
      dateAdded: dateAdded ?? this.dateAdded,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
