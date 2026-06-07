import 'package:hive/hive.dart';
import 'transaction.dart';

/// Legacy adapter for reading old Expense data stored with Hive typeId 0.
///
/// This adapter exists solely for backward-compatible data migration.
/// Old Expense had fields: (0) id, (1) amount, (2) category, (3) merchant,
/// (4) note, (5) paymentMethod, (6) dateCreated, (7) dateModified.
///
/// We read the old data and convert it to the new TransactionModel format.
/// Legacy adapter for reading old Expense data stored with Hive typeId 0.
/// Returns a Map containing the raw field data for migration.
class LegacyExpenseAdapter extends TypeAdapter<dynamic> {
  @override
  final int typeId = 0;

  @override
  dynamic read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return fields;
  }

  @override
  void write(BinaryWriter writer, dynamic obj) {
    // This adapter is read-only for migration
    writer.writeByte(0);
  }
}
