import 'package:cloud_firestore/cloud_firestore.dart';

/// Purchase history data model — matches web app's PurchaseHistory interface
class PurchaseHistory {
  final String? id;
  final double price;
  final String label;
  final String category;
  final String decision; // "undecided" | "bought" | "skipped"
  final DateTime timestamp;
  final int? timeOfDay;
  final PurchaseCalculations calculations;

  const PurchaseHistory({
    this.id,
    required this.price,
    required this.label,
    required this.category,
    required this.decision,
    required this.timestamp,
    this.timeOfDay,
    required this.calculations,
  });

  factory PurchaseHistory.fromMap(Map<String, dynamic> map, {String? id}) {
    return PurchaseHistory(
      id: id ?? map['id'] as String?,
      price: (map['price'] as num).toDouble(),
      label: map['label'] as String? ?? 'this purchase',
      category: map['category'] as String? ?? 'other',
      decision: map['decision'] as String? ?? 'undecided',
      timestamp: _parseTimestamp(map['timestamp']),
      timeOfDay: map['timeOfDay'] as int?,
      calculations: PurchaseCalculations.fromMap(
        map['calculations'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Parse timestamp from any format (Firestore Timestamp, int, String)
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'label': label,
      'category': category,
      'decision': decision,
      'timestamp': Timestamp.fromDate(timestamp),
      'timeOfDay': timeOfDay ?? timestamp.hour,
      'calculations': calculations.toMap(),
    };
  }

  PurchaseHistory copyWith({String? decision}) {
    return PurchaseHistory(
      id: id,
      price: price,
      label: label,
      category: category,
      decision: decision ?? this.decision,
      timestamp: timestamp,
      timeOfDay: timeOfDay,
      calculations: calculations,
    );
  }
}

class PurchaseCalculations {
  final double timeInMinutes;
  final double emergencyBufferDays;
  final double monthsOfExpenses;
  final double weeksOfGroceries;
  final double daysOfUtilities;
  final double workdayFraction;

  const PurchaseCalculations({
    required this.timeInMinutes,
    required this.emergencyBufferDays,
    required this.monthsOfExpenses,
    required this.weeksOfGroceries,
    required this.daysOfUtilities,
    required this.workdayFraction,
  });

  factory PurchaseCalculations.fromMap(Map<String, dynamic> map) {
    return PurchaseCalculations(
      timeInMinutes: (map['timeInMinutes'] as num?)?.toDouble() ?? 0,
      emergencyBufferDays:
          (map['emergencyBufferDays'] as num?)?.toDouble() ??
          (map['emergencyDays'] as num?)?.toDouble() ??
          0,
      monthsOfExpenses: (map['monthsOfExpenses'] as num?)?.toDouble() ?? 0,
      weeksOfGroceries:
          (map['weeksOfGroceries'] as num?)?.toDouble() ??
          (map['groceryWeeks'] as num?)?.toDouble() ??
          0,
      daysOfUtilities: (map['daysOfUtilities'] as num?)?.toDouble() ?? 0,
      workdayFraction: (map['workdayFraction'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeInMinutes': timeInMinutes,
      'emergencyBufferDays': emergencyBufferDays,
      'emergencyDays': emergencyBufferDays, // web-compatible alias
      'monthsOfExpenses': monthsOfExpenses,
      'weeksOfGroceries': weeksOfGroceries,
      'groceryWeeks': weeksOfGroceries, // web-compatible alias
      'daysOfUtilities': daysOfUtilities,
      'workdayFraction': workdayFraction,
    };
  }
}
