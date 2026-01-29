/// Модель баланса пользователя
class UserBalance {
  final int balance;

  const UserBalance({required this.balance});

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      balance: json['balance'] as int,
    );
  }

  @override
  String toString() => 'UserBalance(balance: $balance)';
}
