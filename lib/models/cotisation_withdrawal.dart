class CotisationWithdrawal {
  final int? id;
  final int cotisationId;
  final double amount;
  final String date;
  final String? motif;
  final String? source;

  CotisationWithdrawal({
    this.id,
    required this.cotisationId,
    required this.amount,
    required this.date,
    this.motif,
    this.source,
  });

  factory CotisationWithdrawal.fromMap(Map<String, dynamic> m) {
    return CotisationWithdrawal(
      id: m['id'] as int?,
      cotisationId: m['cotisation_id'] as int,
      amount: (m['amount'] as num).toDouble(),
      date: m['date'] as String,
      motif: m['motif'] as String?,
      source: m['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cotisation_id': cotisationId,
      'amount': amount,
      'date': date,
      'motif': motif,
      'source': source,
    };
  }
}
