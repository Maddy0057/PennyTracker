import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ExpenseCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final int color;

  @HiveField(4)
  final String type; // 'expense' or 'income'

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = 'expense',
  });

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    String? type,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color, 'type': type};
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      type: (map['type'] as String?) ?? 'expense',
    );
  }
}

// Manual TypeAdapter for Hive
class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 1;

  @override
  ExpenseCategory read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ExpenseCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      color: fields[3] as int,
      type: (fields[4] as String?) ?? 'expense',
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.icon);
    writer.writeByte(3);
    writer.write(obj.color);
    writer.writeByte(4);
    writer.write(obj.type);
  }
}
