import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _controller = TextEditingController();
  final ExpenseService _service = ExpenseService();
  static const Uuid _uuid = Uuid();

  bool _replaceExisting = false;
  List<Expense> _preview = [];
  bool _showPreview = false;

  void _parseAndPreview() {
    final lines =
        _controller.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final List<Expense> parsed = [];

    for (final line in lines) {
      final parts = line.split('|').map((p) => p.trim()).toList();

      if (parts.length < 5) continue;

      final card = parts[0];
      final name = parts[1];
      final typeText = parts[2].toLowerCase();
      final installmentText = parts[3];
      final value = double.tryParse(parts[4].replaceAll(',', '.')) ?? 0;

      if (value == 0) continue;

      if (typeText == 'fixo') {
        parsed.add(
          Expense(
            id: _uuid.v4(),
            category: card,
            name: name,
            value: value,
            type: ExpenseType.fixed,
            currentInstallment: null,
            totalInstallments: null,
          ),
        );
      } else {
        final split = installmentText.split('/');

        if (split.length < 2) continue;

        final current = int.tryParse(split[0]) ?? 0;
        final total = int.tryParse(split[1]) ?? 0;

        if (total == 0) continue;

        parsed.add(
          Expense(
            id: _uuid.v4(),
            category: card,
            name: name,
            value: value,
            type: ExpenseType.installment,
            currentInstallment: current,
            totalInstallments: total,
          ),
        );
      }
    }

    setState(() {
      _preview = parsed;
      _showPreview = parsed.isNotEmpty;
    });
  }

  Future<void> _import() async {
    if (_preview.isEmpty) return;

    if (_replaceExisting) {
      await _service.replaceAll(_preview);
    } else {
      await _service.saveAll(_preview);
    }

    final count = _preview.length;

    setState(() {
      _preview = [];
      _showPreview = false;
      _controller.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count despesas importadas com sucesso ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Dados'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formato esperado:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cartão | Nome | Tipo | Parcela | Valor\n\n'
                'Visa | Hope | Parcelado | 4/6 | 83.16\n'
                'Nubank | Spotify | Fixo | - | 21.90\n'
                'Visa | Samsung | Parcelado | 1/18 | 194.00',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              flex: 2,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Cole seus dados aqui...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Switch(
                  value: _replaceExisting,
                  activeColor: const Color(0xFF2B5876),
                  onChanged: (v) => setState(() => _replaceExisting = v),
                ),
                const Text('Substituir dados existentes'),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _parseAndPreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Pré-visualizar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showPreview ? _import : null,
                    icon: const Icon(Icons.upload),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5876),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (_showPreview && _preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Pré-visualização — ${_preview.length} registros',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _preview.length,
                  itemBuilder: (context, index) {
                    final expense = _preview[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(expense.name),
                      subtitle: Text(
                        expense.type == ExpenseType.installment
                            ? '${expense.category} • Parcela ${expense.currentInstallment}/${expense.totalInstallments}'
                            : '${expense.category} • Fixo',
                      ),
                      trailing: Text(
                        'R\$ ${expense.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
