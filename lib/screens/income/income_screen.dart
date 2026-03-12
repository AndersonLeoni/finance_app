import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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

  Income? _income;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();

    final data = await _service.getIncomeForMonth(now.month, now.year);

    if (data != null) {
      _salaryController.text = data.salary.toString();
      _extraController.text = data.extra.toString();
    }

    setState(() {
      _income = data;
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();

    final salary = double.tryParse(_salaryController.text.replaceAll(",", "."));
    final extra =
        double.tryParse(_extraController.text.replaceAll(",", ".")) ?? 0;

    if (salary == null) return;

    final income = Income(
      id: const Uuid().v4(),
      month: now.month,
      year: now.year,
      salary: salary,
      extra: extra,
    );

    await _service.saveIncome(income);

    await _load();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Renda salva com sucesso")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final month = DateFormat("MMMM yyyy", "pt_BR").format(now);

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
            Text(
              month.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

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
