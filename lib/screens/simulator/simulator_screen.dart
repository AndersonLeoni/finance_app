import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/projection_month.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/projection_service.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final ProjectionService _projectionService = ProjectionService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  List<ProjectionMonth> _currentProjection = [];
  List<ProjectionMonth> _simulatedProjection = [];

  ProjectionMonth? _currentNext;
  ProjectionMonth? _currentSix;
  ProjectionMonth? _currentTwelve;

  ProjectionMonth? _simulatedNext;
  ProjectionMonth? _simulatedSix;
  ProjectionMonth? _simulatedTwelve;

  int? _negativeMonth;
  bool _loading = false;
  bool _hasSimulation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (value <= 0 || months <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor e quantidade de parcelas válidos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final expenses = await _expenseService.loadExpenses();
    final now = DateTime.now();
    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );
    final income = incomeData?.total ?? 0;

    // Projeção ATUAL (sem a nova compra)
    final currentProjection = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    // Despesa simulada
    final simulatedExpense = Expense(
      id: 'simulation-item',
      category: 'Simulação',
      name:
          _nameController.text.trim().isEmpty
              ? 'Nova compra'
              : _nameController.text.trim(),
      type: ExpenseType.installment,
      value: value,
      currentInstallment: 1,
      totalInstallments: months,
    );

    // Projeção SIMULADA (com a nova compra)
    final simulatedProjection = _projectionService.simulate(
      expenses: [...expenses, simulatedExpense],
      income: income,
    );

    // Detecta o primeiro mês com saldo negativo
    int? negativeMonth;
    for (int i = 0; i < simulatedProjection.length; i++) {
      if (simulatedProjection[i].balance < 0) {
        negativeMonth = i;
        break;
      }
    }

    setState(() {
      _currentProjection = currentProjection;
      _simulatedProjection = simulatedProjection;

      _currentNext = currentProjection.length > 1 ? currentProjection[1] : null;
      _currentSix = currentProjection.length > 6 ? currentProjection[6] : null;
      _currentTwelve =
          currentProjection.length > 12 ? currentProjection[12] : null;

      _simulatedNext =
          simulatedProjection.length > 1 ? simulatedProjection[1] : null;
      _simulatedSix =
          simulatedProjection.length > 6 ? simulatedProjection[6] : null;
      _simulatedTwelve =
          simulatedProjection.length > 12 ? simulatedProjection[12] : null;

      _negativeMonth = negativeMonth;
      _hasSimulation = true;
      _loading = false;
    });
  }

  Future<void> _confirmSimulation() async {
    final name =
        _nameController.text.trim().isEmpty
            ? 'Nova compra'
            : _nameController.text.trim();

    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (value <= 0 || months <= 0) return;

    final newExpense = Expense(
      id: _expenseService.generateId(),
      category: 'Simulação',
      name: name,
      type: ExpenseType.installment,
      value: value,
      currentInstallment: 1,
      totalInstallments: months,
    );

    await _expenseService.addExpense(newExpense);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Compra adicionada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _nameController.clear();
      _valueController.clear();
      _monthsController.clear();
      _hasSimulation = false;
      _currentProjection = [];
      _simulatedProjection = [];
      _negativeMonth = null;
    });
  }

  String _buildNegativeMessage() {
    if (_negativeMonth == null) {
      return '✅ Compra segura! Seu saldo não ficará negativo no período projetado.';
    }
    if (_negativeMonth == 0) {
      return '⚠️ Atenção: Essa compra já deixa seu saldo negativo no mês atual.';
    }
    if (_negativeMonth == 1) {
      return '⚠️ Atenção: Essa compra vai deixar seu saldo negativo no próximo mês.';
    }
    return '⚠️ Atenção: Essa compra vai deixar seu saldo negativo em ${_negativeMonth! + 1} meses.';
  }

  Color _alertColor() {
    return _negativeMonth == null ? Colors.green : Colors.red;
  }

  Widget _buildAlert() {
    if (!_hasSimulation) return const SizedBox();

    final color = _alertColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(
            _negativeMonth == null
                ? Icons.check_circle
                : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _buildNegativeMessage(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_currentProjection.isEmpty || _simulatedProjection.isEmpty) {
      return const SizedBox();
    }

    final currentLength =
        _currentProjection.length > 12 ? 12 : _currentProjection.length;
    final simulatedLength =
        _simulatedProjection.length > 12 ? 12 : _simulatedProjection.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativo de saldo projetado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _LegendDot(color: Colors.blue, label: 'Cenário Atual'),
                SizedBox(width: 16),
                _LegendDot(color: Colors.red, label: 'Com a nova compra'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 11,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget:
                            (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index > 11) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'M${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                    getDrawingVerticalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        currentLength,
                        (i) =>
                            FlSpot(i.toDouble(), _currentProjection[i].balance),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        simulatedLength,
                        (i) => FlSpot(
                          i.toDouble(),
                          _simulatedProjection[i].balance,
                        ),
                      ),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard({
    required String title,
    required ProjectionMonth? current,
    required ProjectionMonth? simulated,
  }) {
    if (current == null || simulated == null) return const SizedBox();

    final diff = simulated.balance - current.balance;
    final diffText =
        diff == 0
            ? 'Sem impacto'
            : diff > 0
            ? '+ ${_currency.format(diff.abs())}'
            : '- ${_currency.format(diff.abs())}';
    final diffColor =
        diff > 0
            ? Colors.green
            : diff < 0
            ? Colors.red
            : Colors.grey.shade700;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2B5876),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Antes', style: TextStyle(color: Colors.grey)),
                Text(
                  _currency.format(current.balance),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Depois', style: TextStyle(color: Colors.grey)),
                Text(
                  _currency.format(simulated.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: simulated.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Impacto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    diffText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: diffColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Compra'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Descubra o impacto de uma nova compra no seu orçamento dos próximos meses.',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'O que você quer comprar?',
              hintText: 'Ex: iPhone, TV, Geladeira',
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor da Parcela',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _monthsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Parcelas',
                    suffixText: 'x',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _simulate,
              icon:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.analytics_outlined),
              label: const Text(
                'Simular Impacto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5876),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_hasSimulation) ...[
            _buildAlert(),
            const SizedBox(height: 20),
            _buildChart(),
            const SizedBox(height: 24),
            const Text(
              'Resumo do Impacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B5876),
              ),
            ),
            const SizedBox(height: 16),
            _comparisonCard(
              title: 'Próximo mês',
              current: _currentNext,
              simulated: _simulatedNext,
            ),
            _comparisonCard(
              title: 'Em 6 meses',
              current: _currentSix,
              simulated: _simulatedSix,
            ),
            _comparisonCard(
              title: 'Em 12 meses',
              current: _currentTwelve,
              simulated: _simulatedTwelve,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _confirmSimulation,
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Confirmar e Adicionar Despesa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
