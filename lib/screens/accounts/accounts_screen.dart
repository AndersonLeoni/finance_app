import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ExpenseService _service = ExpenseService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final _uuid = const Uuid();

  List<Expense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadExpenses();
    setState(() {
      _expenses = data;
      _loading = false;
    });
  }

  Future<void> _payInstallment(Expense expense) async {
    await _service.payInstallment(expense.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parcela ${expense.currentInstallment! + 1}/${expense.totalInstallments} paga!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remover gasto?'),
            content: Text('Deseja remover "${expense.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _service.deleteExpense(expense.id);
      await _loadData();
    }
  }

  void _showAddExpenseDialog() {
    final categoryController = TextEditingController();
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final currentInstController = TextEditingController(text: '1');
    final totalInstController = TextEditingController();
    ExpenseType selectedType = ExpenseType.fixed;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('Novo Gasto'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Cartão/Categoria',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ExpenseType>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ExpenseType.fixed,
                              child: Text('Fixo'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseType.installment,
                              child: Text('Parcelado'),
                            ),
                          ],
                          onChanged:
                              (v) => setStateDialog(() => selectedType = v!),
                        ),
                        const SizedBox(height: 12),
                        if (selectedType == ExpenseType.installment) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: currentInstController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Parcela atual',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: totalInstController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Total parcelas',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: valueController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor da parcela (R\$)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5876),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final value = double.tryParse(
                          valueController.text.replaceAll(',', '.'),
                        );
                        if (categoryController.text.isEmpty ||
                            nameController.text.isEmpty ||
                            value == null)
                          return;

                        int? currentInst;
                        int? totalInst;
                        if (selectedType == ExpenseType.installment) {
                          currentInst = int.tryParse(
                            currentInstController.text,
                          );
                          totalInst = int.tryParse(totalInstController.text);
                          if (currentInst == null ||
                              totalInst == null ||
                              currentInst > totalInst)
                            return;
                        }

                        await _service.addExpense(
                          Expense(
                            id: _uuid.v4(),
                            category: categoryController.text,
                            name: nameController.text,
                            type: selectedType,
                            value: value,
                            currentInstallment: currentInst,
                            totalInstallments: totalInst,
                          ),
                        );

                        if (mounted) Navigator.pop(context);
                        await _loadData();
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Map<String, List<Expense>> get _groupedExpenses {
    final Map<String, List<Expense>> grouped = {};
    for (final e in _expenses) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    return grouped;
  }

  double get _totalMonth =>
      _expenses.where((e) => e.isActive).fold(0, (sum, e) => sum + e.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas e Parcelas'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _currency.format(_totalMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children:
                    _groupedExpenses.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;
                      final categoryTotal = items
                          .where((e) => e.isActive)
                          .fold(0.0, (sum, e) => sum + e.value);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2B5876),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _currency.format(categoryTotal),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (expense) => _buildExpenseTile(expense),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    final isInstallment = expense.type == ExpenseType.installment;
    final progress =
        isInstallment
            ? expense.currentInstallment! / expense.totalInstallments!
            : 1.0;
    final isCompleted = expense.isCompleted;

    return ListTile(
      title: Text(
        expense.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle:
          isInstallment
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${expense.currentInstallment}/${expense.totalInstallments} parcelas',
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: isCompleted ? Colors.green : const Color(0xFF4facfe),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              )
              : const Text(
                'Fixo mensal',
                style: TextStyle(color: Colors.green),
              ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currency.format(expense.value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          if (isInstallment && !isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Pagar parcela',
              onPressed: () => _payInstallment(expense),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Remover',
            onPressed: () => _deleteExpense(expense),
          ),
        ],
      ),
    );
  }
}
