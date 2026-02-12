class Accompaniment {
  final String id;
  final String accompanimentGroupId;
  final String name;
  final double extraCharge;
  final bool isAvailable;
  final int displayOrder;
  final DateTime? createdAt;

  Accompaniment({
    required this.id,
    required this.accompanimentGroupId,
    required this.name,
    required this.extraCharge,
    required this.isAvailable,
    required this.displayOrder,
    this.createdAt,
  });

  factory Accompaniment.fromJson(Map<String, dynamic> json) {
    return Accompaniment(
      id: json['id'] ?? '',
      accompanimentGroupId: json['accompanimentGroupId'] ?? '',
      name: json['name'] ?? '',
      extraCharge: (json['extraCharge'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accompanimentGroupId': accompanimentGroupId,
      'name': name,
      'extraCharge': extraCharge,
      'isAvailable': isAvailable,
      'displayOrder': displayOrder,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Accompaniment copyWith({
    String? id,
    String? accompanimentGroupId,
    String? name,
    double? extraCharge,
    bool? isAvailable,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Accompaniment(
      id: id ?? this.id,
      accompanimentGroupId: accompanimentGroupId ?? this.accompanimentGroupId,
      name: name ?? this.name,
      extraCharge: extraCharge ?? this.extraCharge,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}