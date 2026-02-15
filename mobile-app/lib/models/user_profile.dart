/// User profile data model — matches web app's UserProfile interface
class UserProfile {
  final double hourlyWage;
  final int workingDaysPerYear;
  final double monthlyExpenses;
  final double? emergencyFundGoal;
  final double? freedomGoal;

  const UserProfile({
    required this.hourlyWage,
    required this.workingDaysPerYear,
    required this.monthlyExpenses,
    this.emergencyFundGoal,
    this.freedomGoal,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      hourlyWage: (map['hourlyWage'] as num).toDouble(),
      workingDaysPerYear: (map['workingDaysPerYear'] as num).toInt(),
      monthlyExpenses: (map['monthlyExpenses'] as num).toDouble(),
      emergencyFundGoal: (map['emergencyFundGoal'] as num?)?.toDouble(),
      freedomGoal: (map['freedomGoal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourlyWage': hourlyWage,
      'workingDaysPerYear': workingDaysPerYear,
      'monthlyExpenses': monthlyExpenses,
      if (emergencyFundGoal != null) 'emergencyFundGoal': emergencyFundGoal,
      if (freedomGoal != null) 'freedomGoal': freedomGoal,
    };
  }

  UserProfile copyWith({
    double? hourlyWage,
    int? workingDaysPerYear,
    double? monthlyExpenses,
    double? emergencyFundGoal,
    double? freedomGoal,
    bool clearEmergencyFund = false,
    bool clearFreedomGoal = false,
  }) {
    return UserProfile(
      hourlyWage: hourlyWage ?? this.hourlyWage,
      workingDaysPerYear: workingDaysPerYear ?? this.workingDaysPerYear,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      emergencyFundGoal: clearEmergencyFund
          ? null
          : (emergencyFundGoal ?? this.emergencyFundGoal),
      freedomGoal: clearFreedomGoal ? null : (freedomGoal ?? this.freedomGoal),
    );
  }
}
