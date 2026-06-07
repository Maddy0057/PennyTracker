import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import 'widgets/filter_sort_bar.dart';
import 'widgets/expense_list_item.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(searchedTransactionsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt_off : Icons.filter_alt_outlined,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Filter & Sort Bar
          if (_showFilters) const FilterSortBar(),

          // Transaction Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${expenses.length} transactions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/add-expense'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No matching transactions'
                              : 'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Tap + to add your first expense',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        if (searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-expense'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Transaction'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return ExpenseListItem(transaction: expenses[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
