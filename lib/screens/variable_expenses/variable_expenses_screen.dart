import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/variable_expense.dart';
import '../../services/variable_expense_service.dart';

class VariableExpensesScreen extends StatefulWidget {
  const VariableExpensesScreen({super.key});

  @override
  State<VariableExpensesScreen> createState() => _VariableExpensesScreenState();
}

class _VariableExpensesScreenState extends State<VariableExpensesScreen> {
  final _service = VariableExpenseService();

  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<VariableExpense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAll();
    setState(() => _expenses = data);
  }

  Future<void> _add() async {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value == null) return;

    final expense = VariableExpense(
      id: const Uuid().v4(),
      category:
          _categoryController.text.isEmpty
              ? 'Outros'
              : _categoryController.text,
      description: _descriptionController.text,
      value: value,
      date: DateTime.now(),
    );

    await _service.add(expense);
    _categoryController.clear();
    _descriptionController.clear();
    _valueController.clear();
    await _load();
  }

  Future<void> _delete(String id) async {
    await _service.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateFormat('MMMM yyyy', 'pt_BR').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Variáveis'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Formulário de adicionar
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Gastos do $month',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _valueController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5876),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Lista de gastos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      child: Text(expense.category[0].toUpperCase()),
                    ),
                    title: Text(expense.description),
                    subtitle: Text(
                      '${expense.category} • ${DateFormat('dd/MM').format(expense.date)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currency.format(expense.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(expense.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
