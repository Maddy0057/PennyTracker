import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/category.dart';

ExpenseCategory createCategory({
  String id = 'cat-1',
  String name = 'Food & Dining',
  String icon = 'restaurant',
  int color = 0xFFEF4444,
  String type = 'expense',
}) {
  return ExpenseCategory(
    id: id,
    name: name,
    icon: icon,
    color: color,
    type: type,
  );
}

void main() {
  group('ExpenseCategory model - constructor', () {
    test('defaults type to expense', () {
      final category = ExpenseCategory(
        id: 'cat-1',
        name: 'Test',
        icon: 'test',
        color: 0xFF000000,
      );

      expect(category.type, 'expense');
    });

    test('accepts income type', () {
      final category = createCategory(type: 'income');
      expect(category.type, 'income');
    });
  });

  group('ExpenseCategory model - copyWith', () {
    test('preserves all fields when no args', () {
      final original = createCategory();
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.name, original.name);
      expect(copied.icon, original.icon);
      expect(copied.color, original.color);
      expect(copied.type, original.type);
    });

    test('overrides specified fields', () {
      final original = createCategory();
      final copied = original.copyWith(
        name: 'Transportation',
        icon: 'bus',
        color: 0xFF06B6D4,
      );

      expect(copied.name, 'Transportation');
      expect(copied.icon, 'bus');
      expect(copied.color, 0xFF06B6D4);
      expect(copied.id, original.id);
      expect(copied.type, original.type);
    });

    test('can change type to income', () {
      final original = createCategory(type: 'expense');
      final copied = original.copyWith(type: 'income');

      expect(copied.type, 'income');
    });
  });

  group('ExpenseCategory model - serialization', () {
    test('toMap returns correct map', () {
      final category = createCategory(
        id: 'cat-food',
        name: 'Food & Dining',
        icon: 'restaurant',
        color: 0xFFEF4444,
        type: 'expense',
      );

      final map = category.toMap();

      expect(map['id'], 'cat-food');
      expect(map['name'], 'Food & Dining');
      expect(map['icon'], 'restaurant');
      expect(map['color'], 0xFFEF4444);
      expect(map['type'], 'expense');
    });

    test('fromMap reconstructs category correctly', () {
      final map = {
        'id': 'cat-transport',
        'name': 'Transportation',
        'icon': 'directions_bus',
        'color': 0xFF06B6D4,
        'type': 'expense',
      };

      final category = ExpenseCategory.fromMap(map);

      expect(category.id, 'cat-transport');
      expect(category.name, 'Transportation');
      expect(category.icon, 'directions_bus');
      expect(category.color, 0xFF06B6D4);
      expect(category.type, 'expense');
    });

    test('fromMap defaults type to expense when null', () {
      final map = {
        'id': 'cat-test',
        'name': 'Test',
        'icon': 'test',
        'color': 0xFF000000,
        'type': null,
      };

      final category = ExpenseCategory.fromMap(map);

      expect(category.type, 'expense');
    });

    test('toMap and fromMap round-trip', () {
      final original = createCategory(
        id: 'cat-roundtrip',
        name: 'Entertainment',
        icon: 'movie',
        color: 0xFF8B5CF6,
        type: 'expense',
      );

      final map = original.toMap();
      final restored = ExpenseCategory.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.type, original.type);
    });
  });

  group('ExpenseCategory model - edge cases', () {
    test('color can be any int value', () {
      final category = createCategory(color: 0);
      expect(category.color, 0);
    });

    test('icon can be empty string', () {
      final category = createCategory(icon: '');
      expect(category.icon, '');
    });

    test('name can contain special characters', () {
      final category = createCategory(name: 'Health & Wellness!');
      expect(category.name, 'Health & Wellness!');
    });
  });
}
