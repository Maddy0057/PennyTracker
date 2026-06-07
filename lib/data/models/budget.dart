import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double monthlyLimit;

  @HiveField(2)
  final double currentSpent;

  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  Budget({
    required this.id,
    required this.monthlyLimit,
    this.currentSpent = 0,
    required this.month,
    required this.year,
  });

  double get remaining => monthlyLimit - currentSpent;

  /// Returns the percentage of budget used (0-1 range, can exceed 1)
  double get percentageUsed =>
      monthlyLimit > 0 ? currentSpent / monthlyLimit : 0;

  /// Health status based on percentage used
  BudgetHealthStatus get healthStatus {
    if (monthlyLimit <= 0) return BudgetHealthStatus.noBudget;
    if (currentSpent > monthlyLimit) return BudgetHealthStatus.exceeded;
    if (percentageUsed >= 0.9) return BudgetHealthStatus.critical;
    if (percentageUsed >= 0.75) return BudgetHealthStatus.warning;
    if (percentageUsed >= 0.5) return BudgetHealthStatus.normal;
    return BudgetHealthStatus.healthy;
  }

  bool get isExceeded => currentSpent > monthlyLimit;
  bool get isWarning => percentageUsed >= 0.8 && !isExceeded;

  /// The amount over budget (positive if over, 0 otherwise)
  double get overBudgetBy => isExceeded ? currentSpent - monthlyLimit : 0;

  Budget copyWith({
    String? id,
    double? monthlyLimit,
    double? currentSpent,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpent: currentSpent ?? this.currentSpent,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthlyLimit': monthlyLimit,
      'currentSpent': currentSpent,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      currentSpent: (map['currentSpent'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}

/// Represents the health status of a budget based on usage percentage.
enum BudgetHealthStatus {
  /// 0-50% used
  healthy,

  /// 50-75% used
  normal,

  /// 75-90% used
  warning,

  /// 90-100% used
  critical,

  /// >100% used
  exceeded,

  /// No budget set
  noBudget,
}

// Manual TypeAdapter for Hive
class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 2;

  @override
  Budget read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Budget(
      id: fields[0] as String,
      monthlyLimit: (fields[1] as num).toDouble(),
      currentSpent: (fields[2] as num).toDouble(),
      month: fields[3] as int,
      year: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.monthlyLimit);
    writer.writeByte(2);
    writer.write(obj.currentSpent);
    writer.writeByte(3);
    writer.write(obj.month);
    writer.writeByte(4);
    writer.write(obj.year);
  }
}
