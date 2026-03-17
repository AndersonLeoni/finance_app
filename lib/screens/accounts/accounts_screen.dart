import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../import/import_screen.dart'; // Import da tela criada
import 'package:intl/intl.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];

  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _expenseService.loadExpenses();
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  Future<void> _deleteExpense(String id) async {
    await _expenseService.deleteExpense(id);
    _loadExpenses();
  }

  Future<void> _payInstallment(String id) async {
    await _expenseService.payInstallment(id);
    _loadExpenses();
  }

  // --- Função do botão + para adicionar manualmente ---
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Cartão/Banco (ex: Visa, Nubank)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome da despesa (ex: Netflix, Mercado)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor atual (R\$)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo de Despesa'),
                    items: const [
                      DropdownMenuItem(value: ExpenseType.fixed, child: Text('Fixo Mensal')),
                      DropdownMenuItem(value: ExpenseType.installment, child: Text('Parcelado')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  if (selectedType == ExpenseType.installment) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: currentInstallmentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Parcela Atual (ex: 4)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: totalInstallmentsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total de Parcelas (ex: 6)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5876),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final category = categoryController.text.trim();
                  final valueText = valueController.text.replaceAll(',', '.');
                  final value = double.tryParse(valueText) ?? 0.0;

                  if (name.isEmpty || value <= 0 || category.isEmpty) {
                    // Validação simples
                    return;
                  }

                  int? current;
                  int? total;

                  if (selectedType == ExpenseType.installment) {
                    current = int.tryParse(currentInstallmentController.text);
                    total = int.tryParse(totalInstallmentsController.text);
                    if (current == null || total == null) return; // Segurança extra
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

                  await _expenseService.addExpense(newExpense);
                  Navigator.pop(context);
                  _loadExpenses(); // Atualiza a tela após salvar
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
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        actions: [
          // Botão de importação
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar Planilha',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ).then((_) => _loadExpenses()); // Recarrega ao fechar a importação
            },
          ),
        ],
      ),
      body: _expenses.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma conta cadastrada ou importada ainda.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                final isInstallment = expense.type == ExpenseType.installment;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isInstallment
                          ? Colors.purple.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      child: Icon(
                        isInstallment ? Icons.layers : Icons.credit_card,
                        color: isInstallment ? Colors.purple : Colors.red,
                      ),
                    ),
                    title: Text(expense.name),
                    subtitle: Text(
                      isInstallment
                          ? '${expense.category} • Parcela ${expense.currentInstallment}/${expense.totalInstallments}'
                          : '${expense.category} • Valor fixo',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currencyFormat.format(expense.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteExpense(expense.id);
                            } else if (value == 'pay' && isInstallment) {
                              _payInstallment(expense.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (isInstallment && !expense.isCompleted)
                              const PopupMenuItem(
                                value: 'pay',
                                child: Text('Avançar Parcela'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Excluir',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog, // Aciona a caixa de adicionar manual que devolvemos
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
