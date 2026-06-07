import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/budget.dart';

/// Helper to create a budget for testing
Budget createBudget({
  required double monthlyLimit,
  required double currentSpent,
}) {
  return Budget(
    id: 'test-id',
    monthlyLimit: monthlyLimit,
    currentSpent: currentSpent,
    month: 1,
    year: 2026,
  );
}

void main() {
  group('Budget model - health status scenarios', () {
    // ──────────────────────────────────────────────
    // Scenario 1: Healthy (0-50%)
    // ──────────────────────────────────────────────
    test('Scenario 1: Budget ₹1000, Spent ₹400 → 40% Used, Healthy', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 400);

      expect(budget.percentageUsed, closeTo(0.4, 0.001));
      expect(budget.remaining, 600);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, false);
      expect(budget.overBudgetBy, 0);
      expect(budget.healthStatus, BudgetHealthStatus.healthy);
    });

    test(
      'Scenario 1b: Budget ₹1000, Spent ₹500 → 50% Used, Normal (boundary)',
      () {
        final budget = createBudget(monthlyLimit: 1000, currentSpent: 500);

        expect(budget.percentageUsed, closeTo(0.5, 0.001));
        // 50% is the boundary — falls into normal (>= 0.5)
        expect(budget.healthStatus, BudgetHealthStatus.normal);
      },
    );

    // ──────────────────────────────────────────────
    // Scenario 2: Normal (50-75%)
    // ──────────────────────────────────────────────
    test('Scenario 2: Budget ₹1000, Spent ₹600 → 60% Used, Normal', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 600);

      expect(budget.percentageUsed, closeTo(0.6, 0.001));
      expect(budget.remaining, 400);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, false);
      expect(budget.healthStatus, BudgetHealthStatus.normal);
    });

    // ──────────────────────────────────────────────
    // Scenario 3: Warning (75-90%)
    // ──────────────────────────────────────────────
    test('Scenario 3: Budget ₹1000, Spent ₹800 → 80% Used, Warning', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 800);

      expect(budget.percentageUsed, closeTo(0.8, 0.001));
      expect(budget.remaining, 200);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, true);
      expect(budget.healthStatus, BudgetHealthStatus.warning);
    });

    test(
      'Scenario 3b: Budget ₹1000, Spent ₹750 → 75% Used, Warning (boundary)',
      () {
        final budget = createBudget(monthlyLimit: 1000, currentSpent: 750);

        expect(budget.percentageUsed, closeTo(0.75, 0.001));
        expect(budget.healthStatus, BudgetHealthStatus.warning);
      },
    );

    // ──────────────────────────────────────────────
    // Scenario 4: Critical (90-100%)
    // ──────────────────────────────────────────────
    test('Scenario 4: Budget ₹1000, Spent ₹950 → 95% Used, Critical', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 950);

      expect(budget.percentageUsed, closeTo(0.95, 0.001));
      expect(budget.remaining, 50);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, true);
      expect(budget.healthStatus, BudgetHealthStatus.critical);
    });

    test(
      'Scenario 4b: Budget ₹1000, Spent ₹900 → 90% Used, Critical (boundary)',
      () {
        final budget = createBudget(monthlyLimit: 1000, currentSpent: 900);

        expect(budget.percentageUsed, closeTo(0.9, 0.001));
        expect(budget.healthStatus, BudgetHealthStatus.critical);
      },
    );

    // ──────────────────────────────────────────────
    // Scenario 5: Exceeded (>100%)
    // ──────────────────────────────────────────────
    test(
      'Scenario 5: Budget ₹1000, Spent ₹1100 → 110% Used, Exceeded, Over Budget By ₹100',
      () {
        final budget = createBudget(monthlyLimit: 1000, currentSpent: 1100);

        expect(budget.percentageUsed, closeTo(1.1, 0.001));
        expect(budget.remaining, -100);
        expect(budget.isExceeded, true);
        expect(budget.isWarning, false);
        expect(budget.overBudgetBy, 100);
        expect(budget.healthStatus, BudgetHealthStatus.exceeded);
      },
    );
  });

  group('Budget model - edge cases', () {
    test('Zero budget limit (no budget set): percentage used is 0', () {
      final budget = Budget(
        id: 'test-id',
        monthlyLimit: 0,
        currentSpent: 500,
        month: 1,
        year: 2026,
      );

      expect(budget.percentageUsed, 0);
      expect(budget.remaining, -500);
      expect(budget.isExceeded, true);
      expect(budget.healthStatus, BudgetHealthStatus.noBudget);
    });

    test('Zero budget limit with zero spending', () {
      final budget = Budget(
        id: 'test-id',
        monthlyLimit: 0,
        currentSpent: 0,
        month: 1,
        year: 2026,
      );

      expect(budget.percentageUsed, 0);
      expect(budget.healthStatus, BudgetHealthStatus.noBudget);
    });

    test('Exactly at budget limit: 100% used, not exceeded', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 1000);

      expect(budget.percentageUsed, closeTo(1.0, 0.001));
      expect(budget.remaining, 0);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, true); // >= 80%
      expect(budget.healthStatus, BudgetHealthStatus.critical); // >= 90%
      expect(budget.overBudgetBy, 0);
    });

    test('Zero spending on valid budget: 0% used, healthy', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 0);

      expect(budget.percentageUsed, 0);
      expect(budget.remaining, 1000);
      expect(budget.isExceeded, false);
      expect(budget.isWarning, false);
      expect(budget.healthStatus, BudgetHealthStatus.healthy);
      expect(budget.overBudgetBy, 0);
    });

    test('Large overflow: Budget ₹1000, Spent ₹5000 → 500% Used', () {
      final budget = createBudget(monthlyLimit: 1000, currentSpent: 5000);

      expect(budget.percentageUsed, closeTo(5.0, 0.001));
      expect(budget.remaining, -4000);
      expect(budget.isExceeded, true);
      expect(budget.healthStatus, BudgetHealthStatus.exceeded);
      expect(budget.overBudgetBy, 4000);
    });

    test('Very small budget usage: Budget ₹10000, Spent ₹1', () {
      final budget = createBudget(monthlyLimit: 10000, currentSpent: 1);

      expect(budget.percentageUsed, closeTo(0.0001, 0.00001));
      expect(budget.healthStatus, BudgetHealthStatus.healthy);
    });

    test('Boundary at 75%: warning threshold', () {
      // 74.9% → normal, 75% → warning
      final budgetNormal = createBudget(monthlyLimit: 1000, currentSpent: 749);
      final budgetWarning = createBudget(monthlyLimit: 1000, currentSpent: 750);

      expect(budgetNormal.healthStatus, BudgetHealthStatus.normal);
      expect(budgetWarning.healthStatus, BudgetHealthStatus.warning);
    });

    test('Boundary at 90%: critical threshold', () {
      // 89.9% → warning, 90% → critical
      final budgetWarning = createBudget(monthlyLimit: 1000, currentSpent: 899);
      final budgetCritical = createBudget(
        monthlyLimit: 1000,
        currentSpent: 900,
      );

      expect(budgetWarning.healthStatus, BudgetHealthStatus.warning);
      expect(budgetCritical.healthStatus, BudgetHealthStatus.critical);
    });

    test('Boundary at 100%: exceeded threshold', () {
      // 100% → critical (not exceeded since not > 100%), 100.1% → exceeded
      final budgetCritical = createBudget(
        monthlyLimit: 1000,
        currentSpent: 1000,
      );
      final budgetExceeded = createBudget(
        monthlyLimit: 1000,
        currentSpent: 1001,
      );

      expect(budgetCritical.healthStatus, BudgetHealthStatus.critical);
      expect(budgetCritical.isExceeded, false);
      expect(budgetExceeded.healthStatus, BudgetHealthStatus.exceeded);
      expect(budgetExceeded.isExceeded, true);
    });
  });

  group('Budget model - computed getters', () {
    test('isWarning is true when >= 80% and not exceeded', () {
      expect(
        createBudget(monthlyLimit: 1000, currentSpent: 800).isWarning,
        true,
      );
      expect(
        createBudget(monthlyLimit: 1000, currentSpent: 899).isWarning,
        true,
      );
      expect(
        createBudget(monthlyLimit: 1000, currentSpent: 900).isWarning,
        true,
      );
      // But not when exceeded
      expect(
        createBudget(monthlyLimit: 1000, currentSpent: 1001).isWarning,
        false,
      );
    });

    test('remaining decreases as spending increases', () {
      final b1 = createBudget(monthlyLimit: 1000, currentSpent: 0);
      final b2 = createBudget(monthlyLimit: 1000, currentSpent: 500);
      final b3 = createBudget(monthlyLimit: 1000, currentSpent: 1000);
      final b4 = createBudget(monthlyLimit: 1000, currentSpent: 1500);

      expect(b1.remaining, 1000);
      expect(b2.remaining, 500);
      expect(b3.remaining, 0);
      expect(b4.remaining, -500);
    });
  });

  group('Budget model - copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = createBudget(monthlyLimit: 1000, currentSpent: 500);
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.monthlyLimit, original.monthlyLimit);
      expect(copied.currentSpent, original.currentSpent);
      expect(copied.month, original.month);
      expect(copied.year, original.year);
    });

    test('copyWith overrides specified fields', () {
      final original = createBudget(monthlyLimit: 1000, currentSpent: 500);
      final copied = original.copyWith(monthlyLimit: 2000, currentSpent: 800);

      expect(copied.id, original.id);
      expect(copied.monthlyLimit, 2000);
      expect(copied.currentSpent, 800);
    });
  });

  group('Budget model - serialization', () {
    test('toMap and fromMap round-trip', () {
      final original = createBudget(monthlyLimit: 1500, currentSpent: 600);
      final map = original.toMap();
      final restored = Budget.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.monthlyLimit, original.monthlyLimit);
      expect(restored.currentSpent, original.currentSpent);
      expect(restored.month, original.month);
      expect(restored.year, original.year);
    });
  });
}
