import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/projection_month.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/variable_expense_service.dart';
import '../../services/projection_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final VariableExpenseService _variableService = VariableExpenseService();
  final ProjectionService _projectionService = ProjectionService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  double _income = 0;
  double _fixedExpenses = 0;
  double _variableExpenses = 0;
  double _totalExpenses = 0;
  double _balance = 0;
  int _activeInstallments = 0;

  ProjectionMonth? _nextMonth;
  ProjectionMonth? _in6Months;
  ProjectionMonth? _in12Months;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _expenseService.loadExpenses();
    final now = DateTime.now();

    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    final variableTotal = await _variableService.getTotalCurrentMonth();

    double fixedTotal = 0;
    int installments = 0;

    for (final e in expenses) {
      if (e.isActive) {
        fixedTotal += e.value;
      }
      if (e.type == ExpenseType.installment && !e.isCompleted) {
        installments++;
      }
    }

    final income = incomeData?.total ?? 0;
    final totalExpenses = fixedTotal + variableTotal;
    final balance = income - totalExpenses;

    final projections = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    setState(() {
      _income = income;
      _fixedExpenses = fixedTotal;
      _variableExpenses = variableTotal;
      _totalExpenses = totalExpenses;
      _balance = balance;
      _activeInstallments = installments;
      _nextMonth = projections.length > 1 ? projections[1] : null;
      _in6Months = projections.length > 6 ? projections[6] : null;
      _in12Months = projections.length > 12 ? projections[12] : null;
      _loading = false;
    });
  }

  // --- WIDGETS VISUAIS MODERNOS ---

  Widget _buildMainBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B5876).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Livre Atual',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Este Mês',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currency.format(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String tabName,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Acesse a aba "$tabName" no menu inferior para gerenciar.',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectionTile(
    String title,
    ProjectionMonth? data,
    IconData icon,
  ) {
    if (data == null) return const SizedBox();

    final isPositive = data.balance >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2B5876).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2B5876)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            _currency.format(data.balance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
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

    // Responsividade: 2 colunas no celular, 4 no PC/Web
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return Scaffold(
      backgroundColor:
          Colors
              .grey
              .shade50, // Fundo levemente cinza para destacar os cards brancos
      appBar: AppBar(
        title: const Text(
          'Meu Painel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF2B5876),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainBalanceCard(),
              const SizedBox(height: 28),

              const Text(
                'Resumo do Mês',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15, // Proporção dos cards
                children: [
                  _buildGridCard(
                    title: 'Renda',
                    value: _currency.format(_income),
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                    tabName: 'Renda',
                  ),
                  _buildGridCard(
                    title: 'Contas Fixas',
                    value: _currency.format(_fixedExpenses),
                    icon: Icons.credit_card,
                    color: Colors.red.shade400,
                    tabName: 'Contas',
                  ),
                  _buildGridCard(
                    title: 'Variáveis',
                    value: _currency.format(_variableExpenses),
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    tabName: 'Gastos',
                  ),
                  _buildGridCard(
                    title: 'Total Saídas',
                    value: _currency.format(_totalExpenses),
                    icon: Icons.payments_outlined,
                    color: Colors.deepOrange,
                    tabName: 'Dashboard',
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'Projeção Futura',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildProjectionTile(
                'Próximo mês',
                _nextMonth,
                Icons.skip_next_rounded,
              ),
              _buildProjectionTile(
                'Em 6 meses',
                _in6Months,
                Icons.update_rounded,
              ),
              _buildProjectionTile(
                'Em 12 meses',
                _in12Months,
                Icons.event_available_rounded,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
