import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/variable_expense.dart';
import '../../services/variable_expense_service.dart';

class VariableExpensesScreen extends StatefulWidget {
  const VariableExpensesScreen({super.key});

  @override
  State<VariableExpensesScreen> createState() => _VariableExpensesScreenState();
}

class _VariableExpensesScreenState extends State<VariableExpensesScreen> {
  final VariableExpenseService _service = VariableExpenseService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  List<VariableExpense> _expenses = [];
  bool _loading = true;

  // Lista de categorias com ícones e cores
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Mercado', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'name': 'Alimentação', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transporte', 'icon': Icons.directions_car, 'color': Colors.green},
    {'name': 'Lazer', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': 'Saúde', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Outros', 'icon': Icons.category, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getAll();
    // Ordena da mais recente para a mais antiga
    data.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _expenses = data;
      _loading = false;
    });
  }

  Future<void> _deleteExpense(String id) async {
    await _service.delete(id);
    _loadData();
  }

  void _showAddDialog() {
    final descController = TextEditingController();
    final valueController = TextEditingController();
    String selectedCategory = 'Outros';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Novo Gasto Variável',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (Ex: Pizza, Uber)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Categoria',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _categories.map((cat) {
                          final isSelected = selectedCategory == cat['name'];
                          return ChoiceChip(
                            label: Text(cat['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(
                                () => selectedCategory = cat['name'],
                              );
                            },
                            avatar: Icon(
                              cat['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : cat['color'],
                            ),
                            selectedColor: cat['color'],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final desc = descController.text;
                        final val =
                            double.tryParse(
                              valueController.text.replaceAll(',', '.'),
                            ) ??
                            0;

                        if (desc.isNotEmpty && val > 0) {
                          final expense = VariableExpense(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            description: desc,
                            category: selectedCategory,
                            value: val,
                            date: DateTime.now(),
                          );
                          await _service.add(expense);
                          if (mounted) Navigator.pop(context);
                          _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5876),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salvar Gasto'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Função para pegar as infos visuais da categoria
  Map<String, dynamic> _getCategoryInfo(String categoryName) {
    return _categories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => _categories.last, // Retorna 'Outros' se não achar
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2B5876)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Variáveis'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body:
          _expenses.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum gasto registrado.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  final catInfo = _getCategoryInfo(expense.category);

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catInfo['color'].withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(catInfo['icon'], color: catInfo['color']),
                      ),
                      title: Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${expense.category} • ${DateFormat('dd/MM HH:mm').format(expense.date)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currency.format(expense.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () => _deleteExpense(expense.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Gasto'),
      ),
    );
  }
}
