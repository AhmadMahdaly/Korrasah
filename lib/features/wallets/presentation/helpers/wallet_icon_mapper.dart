import 'package:flutter/material.dart';

class WalletIconChoice {
  const WalletIconChoice({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class WalletIconMapper {
  static const String defaultWallet = 'Wallet2';
  static const String defaultJar = 'PiggyBank';
  static const List<Color> colorChoices = [
    Color(0xFF165B47),
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFC2410C),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFF0F172A),
    Color(0xFFBE185D),
    Color(0xFF0F766E),
  ];
  static const List<WalletIconChoice> detailedChoices = [
    WalletIconChoice(id: 'Wallet2', label: 'محفظة', icon: Icons.wallet_outlined),
    WalletIconChoice(
      id: 'CreditCard',
      label: 'بطاقة',
      icon: Icons.credit_card_outlined,
    ),
    WalletIconChoice(
      id: 'Landmark',
      label: 'بنك',
      icon: Icons.account_balance_outlined,
    ),
    WalletIconChoice(
      id: 'Banknote',
      label: 'كاش',
      icon: Icons.payments_outlined,
    ),
    WalletIconChoice(
      id: 'Coins',
      label: 'عملات',
      icon: Icons.monetization_on_outlined,
    ),
    WalletIconChoice(
      id: 'PiggyBank',
      label: 'توفير',
      icon: Icons.savings_outlined,
    ),
    WalletIconChoice(
      id: 'BadgeDollarSign',
      label: 'دخل',
      icon: Icons.attach_money_outlined,
    ),
    WalletIconChoice(
      id: 'Building2',
      label: 'حساب',
      icon: Icons.apartment_outlined,
    ),
    WalletIconChoice(
      id: 'CircleDollarSign',
      label: 'فلوس',
      icon: Icons.toll_outlined,
    ),
    WalletIconChoice(
      id: 'Smartphone',
      label: 'رقمية',
      icon: Icons.smartphone_outlined,
    ),
    WalletIconChoice(
      id: 'Receipt',
      label: 'فاتورة',
      icon: Icons.receipt_long_outlined,
    ),
    WalletIconChoice(
      id: 'ArrowLeftRight',
      label: 'تحويل',
      icon: Icons.swap_horiz_rounded,
    ),
  ];

  static const List<WalletIconChoice> choices = [
    WalletIconChoice(id: 'Wallet2', label: 'محفظة', icon: Icons.wallet_outlined),
    WalletIconChoice(id: 'PiggyBank', label: 'حصالة', icon: Icons.savings_outlined),
    WalletIconChoice(id: 'Landmark', label: 'بنك', icon: Icons.account_balance_outlined),
    WalletIconChoice(id: 'Banknote', label: 'كاش', icon: Icons.payments_outlined),
    WalletIconChoice(id: 'CreditCard', label: 'بطاقة', icon: Icons.credit_card_outlined),
    WalletIconChoice(id: 'Smartphone', label: 'رقمية', icon: Icons.smartphone_outlined),
    WalletIconChoice(id: 'Building2', label: 'شركة', icon: Icons.apartment_outlined),
    WalletIconChoice(id: 'Home', label: 'بيت', icon: Icons.home_outlined),
    WalletIconChoice(id: 'Briefcase', label: 'شغل', icon: Icons.work_outline),
    WalletIconChoice(id: 'Car', label: 'سيارة', icon: Icons.directions_car_outlined),
    WalletIconChoice(id: 'Coins', label: 'فلوس', icon: Icons.monetization_on_outlined),
  ];

  static IconData resolveDetailed(String? iconName, {bool isJar = false}) {
    final fallback = isJar ? defaultJar : defaultWallet;
    return detailedChoices
        .firstWhere(
          (choice) => choice.id == (iconName ?? fallback),
          orElse: () =>
              detailedChoices.firstWhere((choice) => choice.id == fallback),
        )
        .icon;
  }

  static IconData resolve(String? iconName, {bool isJar = false}) {
    final fallback = isJar ? defaultJar : defaultWallet;
    return choices
        .firstWhere(
          (choice) => choice.id == (iconName ?? fallback),
          orElse: () => choices.firstWhere((choice) => choice.id == fallback),
        )
        .icon;
  }
}
