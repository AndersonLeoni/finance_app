import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../models/projection_month.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/projection_service.dart';
import 'package:intl/intl.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final _valueController = TextEditingController();
  final _monthsController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final ProjectionService _projectionService = ProjectionService();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  ProjectionMonth? _next;
  ProjectionMonth? _six;
  ProjectionMonth? _twelve;

  Future<void> _simulate() async {
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (value <= 0 || months <= 0) return;

    final expenses = await _expenseService.loadExpenses();
    final now = DateTime.now();

    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    final income = incomeData?.total ?? 0;

    // cria gasto fictício
    final simulated = Expense(
      id: 'simulado',
      category: 'Simulação',
      name: 'Nova compra',
      type: ExpenseType.installment,
      value: value,
      currentInstallment: 1,
      totalInstallments: months,
    );

    final all = [...expenses, simulated];

    final projections = _projectionService.simulate(
      expenses: all,
      income: income,
    );

    setState(() {
      _next = projections.length > 1 ? projections[1] : null;
      _six = projections.length > 6 ? projections[6] : null;
      _twelve = projections.length > 12 ? projections[12] : null;
    });
  }

  Widget _result(String title, ProjectionMonth? m) {
    if (m == null) return const SizedBox();

    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          _currency.format(m.balance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: m.balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Compra'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da parcela (R\$)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _monthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade de parcelas',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _simulate,
                child: const Text('Simular'),
              ),
            ),
            const SizedBox(height: 20),
            _result('Próximo mês', _next),
            _result('Em 6 meses', _six),
            _result('Em 12 meses', _twelve),
          ],
        ),
      ),
    );
  }
}
