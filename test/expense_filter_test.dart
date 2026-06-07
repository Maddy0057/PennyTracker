import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/presentation/providers/expense_provider.dart';

void main() {
  group('TransactionFilterState', () {
    test('defaults to date desc with no category', () {
      const state = TransactionFilterState();

      expect(state.sortField, SortField.date);
      expect(state.sortDirection, SortDirection.desc);
      expect(state.selectedCategory, isNull);
    });

    test('copyWith overrides sortField', () {
      const state = TransactionFilterState();
      final modified = state.copyWith(sortField: SortField.amount);

      expect(modified.sortField, SortField.amount);
      expect(modified.sortDirection, SortDirection.desc); // unchanged
    });

    test('copyWith overrides selectedCategory', () {
      const state = TransactionFilterState();
      final modified = state.copyWith(selectedCategory: 'Food');

      expect(modified.selectedCategory, 'Food');
    });

    test('copyWith clearCategory sets selectedCategory to null', () {
      final state = TransactionFilterState(selectedCategory: 'Food');
      final modified = state.copyWith(clearCategory: true);

      expect(modified.selectedCategory, isNull);
    });
  });

  group('TransactionFilterNotifier', () {
    test('initial state has defaults', () {
      final notifier = TransactionFilterNotifier();

      expect(notifier.state.sortField, SortField.date);
      expect(notifier.state.sortDirection, SortDirection.desc);
      expect(notifier.state.selectedCategory, isNull);
    });

    test('setSortField toggles direction for same field', () {
      final notifier = TransactionFilterNotifier();

      // First toggle: date desc -> date asc
      notifier.setSortField(SortField.date);
      expect(notifier.state.sortField, SortField.date);
      expect(notifier.state.sortDirection, SortDirection.asc);

      // Second toggle: date asc -> date desc
      notifier.setSortField(SortField.date);
      expect(notifier.state.sortField, SortField.date);
      expect(notifier.state.sortDirection, SortDirection.desc);
    });

    test('setSortField defaults to desc for new field', () {
      final notifier = TransactionFilterNotifier();

      notifier.setSortField(SortField.amount);

      expect(notifier.state.sortField, SortField.amount);
      expect(notifier.state.sortDirection, SortDirection.desc);
    });

    test('setSortField toggles date then switches to amount with desc', () {
      final notifier = TransactionFilterNotifier();

      // Toggle date to asc
      notifier.setSortField(SortField.date);
      expect(notifier.state.sortDirection, SortDirection.asc);

      // Switch to amount — should reset to desc
      notifier.setSortField(SortField.amount);
      expect(notifier.state.sortField, SortField.amount);
      expect(notifier.state.sortDirection, SortDirection.desc);
    });

    test('toggle amounts multiple times', () {
      final notifier = TransactionFilterNotifier();

      notifier.setSortField(SortField.amount); // amount desc
      notifier.setSortField(SortField.amount); // amount asc
      notifier.setSortField(SortField.amount); // amount desc
      notifier.setSortField(SortField.amount); // amount asc

      expect(notifier.state.sortField, SortField.amount);
      expect(notifier.state.sortDirection, SortDirection.asc);
    });

    test('setCategory updates selectedCategory', () {
      final notifier = TransactionFilterNotifier();

      notifier.setCategory('Transport');
      expect(notifier.state.selectedCategory, 'Transport');
    });

    test('setCategory overwrites previous category', () {
      final notifier = TransactionFilterNotifier();

      notifier.setCategory('Food');
      notifier.setCategory('Shopping');
      expect(notifier.state.selectedCategory, 'Shopping');
    });

    test('setCategory with null preserves previous category', () {
      final notifier = TransactionFilterNotifier();

      notifier.setCategory('Food');
      notifier.setCategory(null);
      // copyWith(null ?? existing) preserves old value
      expect(notifier.state.selectedCategory, 'Food');
    });

    test('clearCategory sets selectedCategory to null', () {
      final notifier = TransactionFilterNotifier();

      notifier.setCategory('Food');
      notifier.clearCategory();
      expect(notifier.state.selectedCategory, isNull);
    });

    test('sort and filter interaction: switching sort preserves category', () {
      final notifier = TransactionFilterNotifier();

      notifier.setCategory('Entertainment');
      notifier.setSortField(SortField.merchant);

      expect(notifier.state.selectedCategory, 'Entertainment');
      expect(notifier.state.sortField, SortField.merchant);
    });
  });

  group('SortField and SortDirection enums', () {
    test('SortField has 4 values', () {
      expect(SortField.values.length, 4);
      expect(
        SortField.values,
        containsAll([
          SortField.date,
          SortField.amount,
          SortField.merchant,
          SortField.category,
        ]),
      );
    });

    test('SortDirection has 2 values', () {
      expect(SortDirection.values.length, 2);
      expect(
        SortDirection.values,
        containsAll([SortDirection.asc, SortDirection.desc]),
      );
    });
  });
}
