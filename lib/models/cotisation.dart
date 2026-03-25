class Cotisation {
  final int? id;
  final double amount;
  final String date;
  final String? note;
  final String source;
  final String? category;
  final int? partnerId;
  final double? remaining;
  final bool isWithdrawn;

  Cotisation({
    this.id,
    required this.amount,
    required this.date,
    this.note,
    this.source = 'caisse',
    this.category,
    this.partnerId,
    this.remaining,
    this.isWithdrawn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'note': note,
      'source': source,
      'category': category,
      'partner_id': partnerId,
    };
  }

  factory Cotisation.fromMap(Map<String, dynamic> map) {
    return Cotisation(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
      note: map['note'],
      source: map['source'] ?? 'caisse',
      category: map['category'],
      partnerId: map['partner_id'],
    );
  }
}
