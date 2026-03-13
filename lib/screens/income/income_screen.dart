import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income.dart';
import '../../services/income_service.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _salaryController = TextEditingController();
  final _extraController = TextEditingController();

  final _service = IncomeService();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Income? _income;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getIncomeForMonth(
      _selectedMonth,
      _selectedYear,
    );

    if (data != null) {
      _salaryController.text = data.salary.toString();
      _extraController.text = data.extra.toString();
    }

    setState(() {
      _income = data;
    });
  }

  Future<void> _save() async {
    final salary = double.tryParse(_salaryController.text.replaceAll(",", "."));
    final extra =
        double.tryParse(_extraController.text.replaceAll(",", ".")) ?? 0;

    if (salary == null) return;

    final income = Income(
      id: "income_${_selectedMonth}_${_selectedYear}",
      month: _selectedMonth,
      year: _selectedYear,
      salary: salary,
      extra: extra,
    );

    await _service.saveIncome(income);

    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Renda de ${_selectedMonth}/${_selectedYear} salva"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Renda Mensal"),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(monthNames[i]),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _selectedMonth = v!;
                      });
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: now.year + i,
                        child: Text("${now.year + i}"),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _selectedYear = v!;
                      });
                      _load();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Salário líquido",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _extraController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Renda extra",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5876),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Salvar"),
              ),
            ),
            const SizedBox(height: 30),
            if (_income != null)
              Card(
                child: ListTile(
                  title: const Text("Total de renda do mês"),
                  trailing: Text(
                    _currency.format(_income!.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
