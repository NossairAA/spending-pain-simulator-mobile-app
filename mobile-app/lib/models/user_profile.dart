/// User profile data model — matches web app's UserProfile interface
class UserProfile {
  final double hourlyWage;
  final int workingDaysPerYear;
  final double monthlyExpenses;
  final double? emergencyFundGoal;
  final double? freedomGoal;
  final String? avatarPreset;
  final String? avatarImageBase64;

  const UserProfile({
    required this.hourlyWage,
    required this.workingDaysPerYear,
    required this.monthlyExpenses,
    this.emergencyFundGoal,
    this.freedomGoal,
    this.avatarPreset,
    this.avatarImageBase64,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      hourlyWage: (map['hourlyWage'] as num).toDouble(),
      workingDaysPerYear: (map['workingDaysPerYear'] as num).toInt(),
      monthlyExpenses: (map['monthlyExpenses'] as num).toDouble(),
      emergencyFundGoal: (map['emergencyFundGoal'] as num?)?.toDouble(),
      freedomGoal: (map['freedomGoal'] as num?)?.toDouble(),
      avatarPreset: map['avatarPreset'] as String?,
      avatarImageBase64: map['avatarImageBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourlyWage': hourlyWage,
      'workingDaysPerYear': workingDaysPerYear,
      'monthlyExpenses': monthlyExpenses,
      if (emergencyFundGoal != null) 'emergencyFundGoal': emergencyFundGoal,
      if (freedomGoal != null) 'freedomGoal': freedomGoal,
      if (avatarPreset != null) 'avatarPreset': avatarPreset,
      if (avatarImageBase64 != null) 'avatarImageBase64': avatarImageBase64,
    };
  }

  UserProfile copyWith({
    double? hourlyWage,
    int? workingDaysPerYear,
    double? monthlyExpenses,
    double? emergencyFundGoal,
    double? freedomGoal,
    String? avatarPreset,
    String? avatarImageBase64,
    bool clearEmergencyFund = false,
    bool clearFreedomGoal = false,
    bool clearAvatarPreset = false,
    bool clearAvatarImage = false,
  }) {
    return UserProfile(
      hourlyWage: hourlyWage ?? this.hourlyWage,
      workingDaysPerYear: workingDaysPerYear ?? this.workingDaysPerYear,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      emergencyFundGoal: clearEmergencyFund
          ? null
          : (emergencyFundGoal ?? this.emergencyFundGoal),
      freedomGoal: clearFreedomGoal ? null : (freedomGoal ?? this.freedomGoal),
      avatarPreset: clearAvatarPreset ? null : (avatarPreset ?? this.avatarPreset),
      avatarImageBase64: clearAvatarImage
          ? null
          : (avatarImageBase64 ?? this.avatarImageBase64),
    );
  }
}
