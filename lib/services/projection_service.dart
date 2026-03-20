import '../models/expense.dart';
import '../models/projection_month.dart';

class ProjectionService {
  List<ProjectionMonth> simulate({
    required List<Expense> expenses,
    required double income,
  }) {
    final now = DateTime.now();
    int projectionMonths = 12;

    for (final expense in expenses) {
      if (expense.type == ExpenseType.installment) {
        final totalInstallments = expense.totalInstallments ?? 0;
        final currentInstallment = expense.currentInstallment ?? 0;

        final monthsLeft = totalInstallments - currentInstallment + 1;

        if (monthsLeft > projectionMonths) {
          projectionMonths = monthsLeft;
        }
      }
    }

    final List<ProjectionMonth> projections = [];

    for (int offset = 0; offset < projectionMonths; offset++) {
      final date = DateTime(now.year, now.month + offset);
      double totalExpenses = 0;

      for (final expense in expenses) {
        if (expense.type == ExpenseType.fixed) {
          totalExpenses += expense.value;
          continue;
        }

        final totalInstallments = expense.totalInstallments ?? 0;
        final currentInstallment = expense.currentInstallment ?? 0;

        if (currentInstallment <= 0 || totalInstallments <= 0) {
          continue;
        }

        final installmentNumberInThisMonth = currentInstallment + offset;

        if (installmentNumberInThisMonth <= totalInstallments) {
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
