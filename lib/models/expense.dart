enum ExpenseCategory { entretien, achatMateriel, investisseur, achatStock }
enum ExpenseSource { caisse, financement }

class Expense {
  final int? id;
  final String reason;
  final double amount;
  final ExpenseCategory category;
  final DateTime dateTime;
  final String? description;
  final bool isValidated;
  final ExpenseSource source;
  final String? financeurId;

  Expense({
    this.id,
    required this.reason,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.description,
    this.isValidated = false,
    this.source = ExpenseSource.caisse,
    this.financeurId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'amount': amount,
      'category': category.name,
      'datetime': dateTime.toIso8601String(),
      'description': description,
      'is_validated': isValidated ? 1 : 0,
      'source': source.name,
      'financeur_id': financeurId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      reason: map['reason'],
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.investisseur,
      ),
      dateTime: DateTime.parse(map['datetime']),
      description: map['description'],
      isValidated: (map['is_validated'] as int? ?? 0) == 1,
      source: ExpenseSource.values.firstWhere(
        (e) => e.name == (map['source'] as String? ?? 'caisse'),
        orElse: () => ExpenseSource.caisse,
      ),
      financeurId: map['financeur_id'],
    );
  }
}
