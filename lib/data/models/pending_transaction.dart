import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class PendingTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String merchant;

  @HiveField(3)
  final String smsContent;

  @HiveField(4)
  final DateTime dateDetected;

  @HiveField(5)
  final String status;

  PendingTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.smsContent,
    required this.dateDetected,
    this.status = 'pending',
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  PendingTransaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? smsContent,
    DateTime? dateDetected,
    String? status,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      smsContent: smsContent ?? this.smsContent,
      dateDetected: dateDetected ?? this.dateDetected,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'smsContent': smsContent,
      'dateDetected': dateDetected.toIso8601String(),
      'status': status,
    };
  }

  factory PendingTransaction.fromMap(Map<String, dynamic> map) {
    return PendingTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      smsContent: map['smsContent'] as String,
      dateDetected: DateTime.parse(map['dateDetected'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

// Manual TypeAdapter for Hive
class PendingTransactionAdapter extends TypeAdapter<PendingTransaction> {
  @override
  final int typeId = 3;

  @override
  PendingTransaction read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return PendingTransaction(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      merchant: fields[2] as String,
      smsContent: fields[3] as String,
      dateDetected: DateTime.parse(fields[4] as String),
      status: fields[5] as String? ?? 'pending',
    );
  }

  @override
  void write(BinaryWriter writer, PendingTransaction obj) {
    writer.writeByte(6);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.amount);
    writer.writeByte(2);
    writer.write(obj.merchant);
    writer.writeByte(3);
    writer.write(obj.smsContent);
    writer.writeByte(4);
    writer.write(obj.dateDetected.toIso8601String());
    writer.writeByte(5);
    writer.write(obj.status);
  }
}
