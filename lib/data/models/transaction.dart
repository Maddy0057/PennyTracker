import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String type; // DEBIT or CREDIT

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String merchant;

  @HiveField(6)
  final String paymentMethod;

  @HiveField(7)
  final String source; // Manual, PhonePe, GooglePay, Paytm, Bank Statement

  @HiveField(8)
  final String referenceId; // Transaction ID or UTR

  @HiveField(9)
  final String? note;

  @HiveField(10)
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    this.type = 'DEBIT',
    required this.category,
    required this.merchant,
    this.paymentMethod = 'UPI',
    this.source = 'Manual',
    this.referenceId = '',
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TransactionModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? type,
    String? category,
    String? merchant,
    String? paymentMethod,
    String? source,
    String? referenceId,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      source: source ?? this.source,
      referenceId: referenceId ?? this.referenceId,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
      'category': category,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
      'source': source,
      'referenceId': referenceId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String? ?? 'DEBIT',
      category: map['category'] as String,
      merchant: map['merchant'] as String,
      paymentMethod: map['paymentMethod'] as String? ?? 'UPI',
      source: map['source'] as String? ?? 'Manual',
      referenceId: map['referenceId'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Whether this transaction is a debit (expense)
  bool get isDebit => type == 'DEBIT';

  /// Whether this transaction is a credit (income)
  bool get isCredit => type == 'CREDIT';

  /// Signed amount: negative for debit, positive for credit
  double get signedAmount => isDebit ? -amount : amount;
}

// Manual TypeAdapter for Hive
// Uses typeId 4 to avoid conflict with old Expense adapter (typeId 0)
// This allows data migration from old Expense format to new TransactionModel format
class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 4;

  @override
  TransactionModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return TransactionModel(
      id: fields[0] as String,
      date: DateTime.parse(fields[1] as String),
      amount: (fields[2] as num).toDouble(),
      type: (fields[3] as String?) ?? 'DEBIT',
      category: fields[4] as String,
      merchant: fields[5] as String,
      paymentMethod: (fields[6] as String?) ?? 'UPI',
      source: (fields[7] as String?) ?? 'Manual',
      referenceId: (fields[8] as String?) ?? '',
      note: fields[9] as String?,
      createdAt: fields[10] != null
          ? DateTime.parse(fields[10] as String)
          : DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.date.toIso8601String());
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.type);
    writer.writeByte(4);
    writer.write(obj.category);
    writer.writeByte(5);
    writer.write(obj.merchant);
    writer.writeByte(6);
    writer.write(obj.paymentMethod);
    writer.writeByte(7);
    writer.write(obj.source);
    writer.writeByte(8);
    writer.write(obj.referenceId);
    writer.writeByte(9);
    writer.write(obj.note);
    writer.writeByte(10);
    writer.write(obj.createdAt.toIso8601String());
  }
}
