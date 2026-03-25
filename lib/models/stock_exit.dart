class StockExit {
  final int? id;
  final int productId;
  final String uuid;
  final String name;
  final String? productName;
  final int quantity;
  final double amount;
  final int? clientId;
  final String? createdAt;
  final String? category;

  StockExit({
    this.id,
    required this.uuid,
    required this.name,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.amount,
    this.clientId,
    this.createdAt,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'product_id': productId,
      'quantity': quantity,
      'amount': amount,
      'client_id': clientId,
      'created_at': createdAt,
    };
  }

  factory StockExit.fromMap(Map<String, dynamic> map) {
    return StockExit(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      productId: (map['product_id'] as int?) ?? 0,
      productName: map['product_name']?.toString(),
      quantity: (map['quantity'] as int?) ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      clientId: map['client_id'] as int?,
      createdAt: map['created_at']?.toString(),
      category: map['category']?.toString(),
    );
  }
}
