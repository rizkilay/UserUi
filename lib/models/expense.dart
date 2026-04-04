import 'package:uuid/uuid.dart';

enum ExpenseCategory {
  entretien,
  achatMateriel,
  investisseur,
  achatStock,
}

enum ExpenseSource {
  caisse,
  financement,
}

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
  final bool isSynced;
  final String uuid;

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
    this.isSynced = false,
    String? uuid,
  }) : uuid = uuid ?? const Uuid().v4();

  /// Convertir en Map (pour SQLite)
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
      'is_synced': isSynced ? 1 : 0,
      'uuid': uuid,
    };
  }

  /// Convertir depuis Map (SQLite → objet)
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
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      uuid: map['uuid'] ?? const Uuid().v4(),
    );
  }

  /// Copier avec modification (utile pour update)
  Expense copyWith({
    int? id,
    String? reason,
    double? amount,
    ExpenseCategory? category,
    DateTime? dateTime,
    String? description,
    bool? isValidated,
    ExpenseSource? source,
    String? financeurId,
    bool? isSynced,
    String? uuid,
  }) {
    return Expense(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      isValidated: isValidated ?? this.isValidated,
      source: source ?? this.source,
      financeurId: financeurId ?? this.financeurId,
      isSynced: isSynced ?? this.isSynced,
      uuid: uuid ?? this.uuid,
    );
  }
}