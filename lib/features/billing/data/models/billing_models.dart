class InvoiceItemModel {
  final int? medicalServiceId;
  final String? description;
  final int quantity;
  final double? unitPrice;

  InvoiceItemModel({
    this.medicalServiceId,
    this.description,
    this.quantity = 1,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicalServiceId': medicalServiceId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class PaymentRequestModel {
  final int invoiceId;
  final double amount;
  final int paymentMethod; // 0 = Cash, 1 = Card, 2 = Transfer
  final String? notes;

  PaymentRequestModel({
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'amount': amount,
      'method': paymentMethod,
      'notes': notes,
    };
  }
}