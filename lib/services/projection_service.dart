import '../models/expense.dart';
import '../models/projection_month.dart';

class ProjectionService {
  List<ProjectionMonth> simulate({
    required List<Expense> expenses,
    required double income,
  }) {
    final now = DateTime.now();

    int maxMonths = 0;

    for (var e in expenses) {
      if (e.type == ExpenseType.installment) {
        final remaining =
            (e.totalInstallments ?? 0) - (e.currentInstallment ?? 0);
        if (remaining > maxMonths) {
          maxMonths = remaining;
        }
      }
    }

    if (maxMonths < 12) {
      maxMonths = 12;
    }

    final List<ProjectionMonth> result = [];

    for (int i = 0; i <= maxMonths; i++) {
      final date = DateTime(now.year, now.month + i);

      double totalExpenses = 0;

      for (var e in expenses) {
        if (e.type == ExpenseType.fixed) {
          totalExpenses += e.value;
        } else {
          final remaining =
              (e.totalInstallments ?? 0) - (e.currentInstallment ?? 0);

          if (i <= remaining) {
            totalExpenses += e.value;
          }
        }
      }

      final balance = income - totalExpenses;

      result.add(
        ProjectionMonth(
          month: date.month,
          year: date.year,
          expenses: totalExpenses,
          income: income,
          balance: balance,
        ),
      );
    }

    return result;
  }
}
