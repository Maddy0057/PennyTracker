import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/main_shell.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/add_expense/add_expense_screen.dart';
import '../presentation/screens/transaction_history/transaction_history_screen.dart';
import '../presentation/screens/expense_detail/expense_detail_screen.dart';
import '../presentation/screens/analytics/analytics_screen.dart';
import '../presentation/screens/merchant_analytics/merchant_analytics_screen.dart';
import '../presentation/screens/budget/budget_screen.dart';
import '../presentation/screens/budget/budget_history_screen.dart';
import '../presentation/screens/categories/categories_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/sms_permission/sms_permission_screen.dart';
import '../presentation/screens/pending_transactions/pending_transactions_screen.dart';
import '../presentation/screens/pdf_import_export/pdf_import_export_screen.dart';
import '../presentation/screens/pdf_import_export/pdf_import_preview_screen.dart';
import '../data/models/transaction.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/overview',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add-expense',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final editTransaction = state.extra as TransactionModel?;
        return AddExpenseScreen(transactionToEdit: editTransaction);
      },
    ),
    GoRoute(
      path: '/add-expense-quick',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddExpenseScreen(
          prefillAmount: extra?['amount'] as double?,
          prefillMerchant: extra?['merchant'] as String?,
          pendingTransactionId: extra?['pendingId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/expense/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExpenseDetailScreen(expenseId: id);
      },
    ),
    GoRoute(
      path: '/merchant-analytics',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MerchantAnalyticsScreen(),
    ),
    GoRoute(
      path: '/budget',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BudgetScreen(),
    ),
    GoRoute(
      path: '/budget-history',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BudgetHistoryScreen(),
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/sms-permission',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SmsPermissionScreen(),
    ),
    GoRoute(
      path: '/pending-transactions',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const PendingTransactionsScreen(),
    ),
    GoRoute(
      path: '/pdf-import-export',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const PdfImportExportScreen(),
    ),
    GoRoute(
      path: '/pdf-import-preview',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final transactions =
            extra?['transactions'] as List<TransactionModel>? ?? [];
        final sourceName = extra?['sourceName'] as String?;
        final fileName = extra?['fileName'] as String?;
        return PdfImportPreviewScreen(
          importedTransactions: transactions,
          sourceName: sourceName,
          fileName: fileName,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3AED), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C3AED).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "The page you're looking for doesn't exist or has been moved.",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/overview'),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text('Go Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/splash'),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Reload'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
