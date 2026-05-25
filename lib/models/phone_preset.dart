// 기종 프리셋 모델
class PhonePreset {
  final String id;
  final String name; // 기기명 (예: 갤럭시 S25)
  final String? manufacturer; // "삼성" / "애플" / "기타"
  final int? defaultJagupPrice; // 자급제 기본가 (자동 학습됨)
  final String? releaseDate; // "2025-02" 형식

  const PhonePreset({
    required this.id,
    required this.name,
    this.manufacturer,
    this.defaultJagupPrice,
    this.releaseDate,
  });

  PhonePreset copyWith({
    String? id,
    String? name,
    String? manufacturer,
    int? defaultJagupPrice,
    String? releaseDate,
    bool clearDefaultJagupPrice = false,
    bool clearManufacturer = false,
    bool clearReleaseDate = false,
  }) {
    return PhonePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: clearManufacturer ? null : (manufacturer ?? this.manufacturer),
      defaultJagupPrice: clearDefaultJagupPrice
          ? null
          : (defaultJagupPrice ?? this.defaultJagupPrice),
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'manufacturer': manufacturer,
        'defaultJagupPrice': defaultJagupPrice,
        'releaseDate': releaseDate,
      };

  factory PhonePreset.fromJson(Map<String, dynamic> json) => PhonePreset(
        id: json['id'] as String,
        name: json['name'] as String,
        manufacturer: json['manufacturer'] as String?,
        defaultJagupPrice: json['defaultJagupPrice'] as int?,
        releaseDate: json['releaseDate'] as String?,
      );
}
