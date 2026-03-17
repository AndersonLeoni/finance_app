import '../models/expense.dart';
import '../models/projection_month.dart';

class ProjectionService {
  List<ProjectionMonth> simulate({
    required List<Expense> expenses,
    required double income,
  }) {
    final now = DateTime.now();

    int maxMonths = 0;

    for (final expense in expenses) {
      if (expense.type == ExpenseType.installment) {
        final totalInstallments = expense.totalInstallments ?? 0;
        final currentInstallment = expense.currentInstallment ?? 0;
        final remainingMonths = totalInstallments - currentInstallment;

        if (remainingMonths > maxMonths) {
          maxMonths = remainingMonths;
        }
      }
    }

    if (maxMonths < 12) {
      maxMonths = 12;
    }

    final List<ProjectionMonth> projections = [];

    for (int offset = 0; offset <= maxMonths; offset++) {
      final date = DateTime(now.year, now.month + offset);
      double totalExpenses = 0;

      for (final expense in expenses) {
        if (expense.type == ExpenseType.fixed) {
          totalExpenses += expense.value;
          continue;
        }

        final totalInstallments = expense.totalInstallments ?? 0;
        final currentInstallment = expense.currentInstallment ?? 0;
        final remainingMonths = totalInstallments - currentInstallment;

        if (offset <= remainingMonths) {
          totalExpenses += expense.value;
        }
      }

      projections.add(
        ProjectionMonth(
          month: date.month,
          year: date.year,
          expenses: totalExpenses,
          income: income,
          balance: income - totalExpenses,
        ),
      );
    }

    return projections;
  }
}
