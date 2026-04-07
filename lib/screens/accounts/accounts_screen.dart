import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../import/import_screen.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];

  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    final expenses = await _expenseService.loadExpenses();

    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  Future<void> _deleteExpense(String id) async {
    await _expenseService.deleteExpense(id);
    await _loadExpenses();
  }

  Future<void> _payInstallment(String id) async {
    await _expenseService.payInstallment(id);
    await _loadExpenses();
  }

  void _showAddExpenseDialog() {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final categoryController = TextEditingController();
    final currentInstallmentController = TextEditingController();
    final totalInstallmentsController = TextEditingController();

    ExpenseType selectedType = ExpenseType.fixed;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Adicionar Conta/Parcela'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Cartão/Banco'),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor'),
                  ),
                  DropdownButtonFormField<ExpenseType>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                          value: ExpenseType.fixed,
                          child: Text('Fixo Mensal')),
                      DropdownMenuItem(
                          value: ExpenseType.installment,
                          child: Text('Parcelado')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() => selectedType = value!);
                    },
                  ),
                  if (selectedType == ExpenseType.installment)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: currentInstallmentController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Atual'),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: totalInstallmentsController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Total'),
                          ),
                        ),
                      ],
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
                onPressed: () async {
                  final name = nameController.text.trim();
                  final category = categoryController.text.trim();
                  final value =
                      double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0;

                  if (name.isEmpty || category.isEmpty || value <= 0) return;

                  int? current;
                  int? total;

                  if (selectedType == ExpenseType.installment) {
                    current = int.tryParse(currentInstallmentController.text);
                    total = int.tryParse(totalInstallmentsController.text);
                  }

                  final newExpense = Expense(
                    id: _expenseService.generateId(),
                    category: category,
                    name: name,
                    type: selectedType,
                    value: value,
                    currentInstallment: current,
                    totalInstallments: total,
                  );

                  print("SALVANDO NO FIREBASE: ${newExpense.name}");

                  await _expenseService.addExpense(newExpense);

                  Navigator.pop(context);

                  await _loadExpenses(); // 🔥 FORÇA RELOAD
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Fixas e Parcelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ).then((_) => _loadExpenses());
            },
          ),
        ],
      ),
      body: _expenses.isEmpty
          ? const Center(child: Text('Nenhuma conta cadastrada'))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final e = _expenses[index];

                return ListTile(
                  title: Text(e.name),
                  subtitle: Text(e.category),
                  trailing: Text(_currencyFormat.format(e.value)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
