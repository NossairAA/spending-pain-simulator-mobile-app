import '../models/user_profile.dart';
import '../models/purchase_history.dart';

/// All spending calculations matching the web app's results-view.tsx logic
class SpendingCalculations {
  /// Calculate time cost in minutes: (price / hourlyWage) * 60
  static double timeInMinutes(double price, double hourlyWage) {
    if (hourlyWage <= 0) return 0;
    return (price / hourlyWage) * 60;
  }

  /// Emergency buffer days eaten: price / (monthlyExpenses / 30)
  static double emergencyBufferDays(double price, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return 0;
    return price / (monthlyExpenses / 30);
  }

  /// Fraction of monthly expenses
  static double monthsOfExpenses(double price, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return 0;
    return price / monthlyExpenses;
  }

  /// Weeks of groceries: price / (monthlyExpenses * 0.15 / 4)
  static double weeksOfGroceries(double price, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return 0;
    return price / (monthlyExpenses * 0.15 / 4);
  }

  /// Days of utilities: price / 7
  static double daysOfUtilities(double price) {
    return price / 7;
  }

  /// Workday fraction: timeMinutes / (8 * 60)
  static double workdayFraction(double timeMinutes) {
    return timeMinutes / (8 * 60);
  }

  /// Build all calculations for a purchase
  static PurchaseCalculations calculate(double price, UserProfile profile) {
    final timeMins = timeInMinutes(price, profile.hourlyWage);
    return PurchaseCalculations(
      timeInMinutes: timeMins,
      emergencyBufferDays: emergencyBufferDays(price, profile.monthlyExpenses),
      monthsOfExpenses: monthsOfExpenses(price, profile.monthlyExpenses),
      weeksOfGroceries: weeksOfGroceries(price, profile.monthlyExpenses),
      daysOfUtilities: daysOfUtilities(price),
      workdayFraction: workdayFraction(timeMins),
    );
  }

  /// Format time from minutes — matches web app's formatTime()
  static String formatTime(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();

    const workDayHours = 8;
    const workDaysInYear = 220;

    if (hours < 24) {
      if (hours == 0) return '${mins}m';
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }

    final totalWorkDays = hours ~/ workDayHours;
    final remainingHours = hours % workDayHours;

    if (totalWorkDays >= workDaysInYear) {
      final years = totalWorkDays ~/ workDaysInYear;
      final daysRemaining = totalWorkDays % workDaysInYear;
      return '${years}y ${daysRemaining}d';
    }

    return '${totalWorkDays}d ${remainingHours}h';
  }

  /// Context text for time cost — matches web app's results-view.tsx
  static String timeContext(double timeMins) {
    final fraction = timeMins / (8 * 60);
    final pct = (fraction * 100).round();

    if (fraction < 0.25) {
      return 'A quick coffee break of your life';
    } else if (fraction < 0.5) {
      return 'A solid chunk of your morning';
    } else if (fraction < 1.0) {
      return "That's $pct% of a full workday";
    } else {
      final days = (fraction).toStringAsFixed(1);
      return "That's $days full workdays of your life";
    }
  }

  /// Get the "time ago" string for a date
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final diffMins = diff.inMinutes;
    final diffHours = diff.inHours;
    final diffDays = diff.inDays;

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return '$diffMins min ago';
    if (diffHours < 24) return '${diffHours}h ago';
    if (diffDays < 7) return '${diffDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
