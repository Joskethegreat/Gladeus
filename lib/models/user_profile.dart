enum Gender { male, female, other, preferNotToSay }

extension GenderLabel on Gender {
  String get label => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
    Gender.other => 'Other',
    Gender.preferNotToSay => 'Prefer not to say',
  };
}

class UserProfile {
  final String name;
  final Gender? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;

  const UserProfile({
    this.name = '',
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender?.name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: (json['name'] as String?) ?? '',
    gender: json['gender'] == null ? null : Gender.values.byName(json['gender'] as String),
    age: json['age'] as int?,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
  );
}
