import 'package:equatable/equatable.dart';

class Allocation extends Equatable {
  const Allocation({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.budgetedAmount,
    required this.balance,
  });

  factory Allocation.fromJson(Map<String, dynamic> json) {
    return Allocation(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      budgetedAmount: (json['budgetedAmount'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );
  }
  final String id;
  final String categoryId;
  final String name;
  final double budgetedAmount;
  final double balance;

  Allocation copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? budgetedAmount,
    double? balance,
  }) {
    return Allocation(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'budgetedAmount': budgetedAmount,
      'balance': balance,
    };
  }

  @override
  List<Object?> get props => [id, categoryId, name, budgetedAmount, balance];
}
