import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/custom_dropdown_button.dart';
import 'package:opration/core/shared_widgets/custom_primary_button.dart';
import 'package:opration/core/shared_widgets/custom_primary_textfield.dart';
import 'package:opration/core/shared_widgets/page_header.dart' show PageHeader;
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/core/theme/themes.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/helpers/wallet_icon_mapper.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';
import 'package:uuid/uuid.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: false,
        heightBar: 80.h,
        title: 'Ø§Ù„Ù…Ø­Ø§ÙØ¸ ÙˆØ§Ù„Ø­ØµØ§Ù„Ø§Øª',
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, walletState) {
          if (walletState is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (walletState is WalletError) {
            return Center(child: Text('Ø®Ø·Ø£: ${walletState.message}'));
          }

          if (walletState is WalletLoaded) {
            final savingsWallet = walletState.wallets.firstWhere(
              (w) => w.isSavingsWallet,
              orElse: () => const Wallet(
                id: 'savings_wallet_id',
                name: 'Ø§Ù„ØªÙˆÙÙŠØ±',
                balance: 0,
                type: WalletType.savings,
              ),
            );

            final actualWallets = walletState.wallets
                .where((w) => w.isRealWallet)
                .toList();

            final hasalat = walletState.wallets
                .where((w) => w.isHasala)
                .toList();

            return BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
              builder: (context, planState) {
                final currentMonth = planState.currentMonth;

                return Column(
                  children: [
                    _buildMonthSelector(context, currentMonth),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActualWalletsSection(
                              context,
                              actualWallets,
                            ),
                            24.verticalSpace,
                            _buildHasalatSection(
                              context,
                              savingsWallet,
                              hasalat,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime currentMonth) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.r,
              color: AppColors.primaryTextColor,
            ),
            onPressed: () {
              final prevMonth = DateTime(
                currentMonth.year,
                currentMonth.month - 1,
                1,
              );
              context.read<MonthlyPlanCubit>().loadPlanForMonth(prevMonth);
            },
          ),
          Text(
            '${_getMonthArabicName(currentMonth.month)} ${currentMonth.year}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18.r,
              color: AppColors.primaryTextColor,
            ),
            onPressed: () {
              final nextMonth = DateTime(
                currentMonth.year,
                currentMonth.month + 1,
                1,
              );
              context.read<MonthlyPlanCubit>().loadPlanForMonth(nextMonth);
            },
          ),
        ],
      ),
    );
  }

  String _getMonthArabicName(int month) {
    const months = [
      'ÙŠÙ†Ø§ÙŠØ±',
      'ÙØ¨Ø±Ø§ÙŠØ±',
      'Ù…Ø§Ø±Ø³',
      'Ø£Ø¨Ø±ÙŠÙ„',
      'Ù…Ø§ÙŠÙˆ',
      'ÙŠÙˆÙ†ÙŠÙˆ',
      'ÙŠÙˆÙ„ÙŠÙˆ',
      'Ø£ØºØ³Ø·Ø³',
      'Ø³Ø¨ØªÙ…Ø¨Ø±',
      'Ø£ÙƒØªÙˆØ¨Ø±',
      'Ù†ÙˆÙÙ…Ø¨Ø±',
      'Ø¯ÙŠØ³Ù…Ø¨Ø±',
    ];
    return months[month - 1];
  }

  Widget _buildBudgetAggregatorCard({
    required BuildContext context,
    required double income,
    required double expense,
    required double netRemaining,
    required double plannedIncome,
    required double plannedCommitments,
    required double plannedBuffer,
    required String savingsWalletId,
    required List<Wallet> actualWallets,
    required int hasalatCount,
    required String monthName,
  }) {
    final isPositive = netRemaining >= 0;
    final isPlanBalanced = plannedBuffer >= 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: appGradient(),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(66),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 32.r,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ù…Ø­ØµÙ„Ø© Ø´Ù‡Ø± $monthName (Ø§Ù„ÙØ§Ø¦Ø¶)',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${netRemaining.toStringAsFixed(2)} Ø¬.Ù…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          8.verticalSpace,
          Text(
            'Ø¯ÙŠ Ù…Ø­ÙØ¸Ø© Ù…Ù†Ø·Ù‚ÙŠØ© Ù„Ù…Ù„Ø®Øµ Ø§Ù„Ø®Ø·Ø© ÙˆØ§Ù„ØªÙ†ÙÙŠØ°ØŒ ÙˆÙ„ÙŠØ³Øª Ù…ÙƒØ§Ù†Ù‹Ø§ ÙØ¹Ù„ÙŠÙ‹Ø§ Ù„Ø­ÙØ¸ Ø§Ù„ÙÙ„ÙˆØ³.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              height: 1.45,
            ),
          ),
          20.verticalSpace,
          const Divider(color: Colors.white30),
          10.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Ø§Ù„Ù…ØµØ±ÙˆÙ Ø§Ù„ÙØ¹Ù„ÙŠ', expense.toStringAsFixed(2)),
              _buildMiniStat('Ø§Ù„Ø¯Ø®Ù„ Ø§Ù„ÙØ¹Ù„ÙŠ', income.toStringAsFixed(2)),
            ],
          ),
          12.verticalSpace,
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildMiniStat(
                'Ø§Ù„Ø¯Ø®Ù„ Ø§Ù„Ù…Ø®Ø·Ø·',
                plannedIncome.toStringAsFixed(2),
              ),
              _buildMiniStat(
                'Ø§Ù„ØªØ²Ø§Ù…Ø§Øª Ø§Ù„Ø®Ø·Ø©',
                plannedCommitments.toStringAsFixed(2),
              ),
            ],
          ),
          12.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.white.withAlpha(25),
                  child: Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 20.r,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ØºÙŠØ± Ø§Ù„Ù…Ø®ØµØµ Ø¯Ø§Ø®Ù„ Ø§Ù„Ø®Ø·Ø©',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        '${isPlanBalanced ? '+' : ''}${plannedBuffer.toStringAsFixed(2)} Ø¬.Ù…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    '$hasalatCount Ø­ØµØ§Ù„Ø©',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          if (netRemaining > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showRolloverToSavingsDialog(
                    context,
                    netRemaining,
                    savingsWalletId,
                    actualWallets,
                  );
                },
                icon: const Icon(
                  Icons.move_to_inbox,
                  color: AppColors.secondaryTextColor,
                  size: 18,
                ),
                label: Text(
                  'ØªØ±Ø­ÙŠÙ„ Ø§Ù„ÙØ§Ø¦Ø¶ Ù„Ù„Ø§Ø¯Ø®Ø§Ø±',
                  style: AppTextStyle.style12Bold.copyWith(
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessModelCard({
    required int actualWalletsCount,
    required int hasalatCount,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryColor.withAlpha(20),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18.r,
                  color: AppColors.primaryColor,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  'ÙØµÙ„ Ø§Ù„Ø®Ø·Ø© Ø¹Ù† Ø£Ù…Ø§ÙƒÙ† Ø§Ù„ÙÙ„ÙˆØ³',
                  style: AppTextStyle.style14Bold,
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Text(
            'Ø§Ù„Ù…Ø­Ø§ÙØ¸ Ø§Ù„ÙØ¹Ù„ÙŠØ© Ù‡ÙŠ Ø£Ù…Ø§ÙƒÙ† Ø§Ù„ÙÙ„ÙˆØ³ Ø§Ù„Ø­Ù‚ÙŠÙ‚ÙŠØ©ØŒ ÙˆØ§Ù„Ø­ØµØ§Ù„Ø§Øª Ø£ÙˆØ¹ÙŠØ© Ù…Ù†Ø·Ù‚ÙŠØ© Ù…Ù…ÙˆÙ„Ø© Ù…Ù† Ø§Ù„Ø®Ø·Ø©ØŒ Ø£Ù…Ø§ Ù…Ø­ÙØ¸Ø© Ø§Ù„Ù…ÙŠØ²Ø§Ù†ÙŠØ© ÙÙ‡ÙŠ Ù…Ù„Ø®Øµ ÙÙ‚Ø·.',
            style: AppTextStyle.style12W500.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          12.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildTypeChip(
                icon: Icons.account_balance_wallet_outlined,
                label: '$actualWalletsCount Ù…Ø­ÙØ¸Ø© ÙØ¹Ù„ÙŠØ©',
                color: const Color(0xFF165B47),
              ),
              _buildTypeChip(
                icon: Icons.savings_outlined,
                label: '$hasalatCount Ø­ØµØ§Ù„Ø©',
                color: const Color(0xFF0F766E),
              ),
              _buildTypeChip(
                icon: Icons.pie_chart_outline_rounded,
                label: 'Ø®Ø·Ø© Ø§Ù„Ù…ÙŠØ²Ø§Ù†ÙŠØ©',
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: color),
          6.horizontalSpace,
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(Wallet wallet, Color color) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.balance.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ø¬.Ù…',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                wallet.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ø§Ù„Ù…Ø­ÙØ¸Ø© Ø§Ù„Ø¢Ù…Ù†Ø©',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withAlpha(55),
            radius: 24.r,
            child: const Icon(Icons.savings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActualWalletsSection(
    BuildContext context,
    List<Wallet> actualWallets,
  ) {
    return _buildWalletSectionCard(
      context: context,
      title: 'Ø§Ù„Ù…Ø­Ø§ÙØ¸',
      subtitle: 'Ø§Ù„ÙÙ„ÙˆØ³ Ø§Ù„ÙØ¹Ù„ÙŠØ© Ø§Ù„Ù…ÙˆØ¬ÙˆØ¯Ø© Ù…Ø¹Ùƒ Ø§Ù„Ø¢Ù†',
      emptyText: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ø­Ø§ÙØ¸ ÙØ¹Ù„ÙŠØ© Ù…Ø³Ø¬Ù„Ø© Ø­ØªÙ‰ Ø§Ù„Ø¢Ù†',
      wallets: actualWallets,
      accentColor: AppColors.primaryTextColor,
      isRealWalletSection: true,
      primaryActionLabel: 'Ø¥Ø¶Ø§ÙØ© Ù…Ø­ÙØ¸Ø©',
      onPrimaryAction: () => _showAddEditSideWalletDialog(context),
      secondaryActionLabel: 'ØªØ­ÙˆÙŠÙ„',
      onSecondaryAction: actualWallets.length < 2
          ? null
          : () => _showTransferDialog(context, actualWallets),
    );
  }

  Widget _buildHasalatSection(
    BuildContext context,
    Wallet savingsWallet,
    List<Wallet> hasalat,
  ) {
    return _buildWalletSectionCard(
      context: context,
      title: 'Ø§Ù„Ø­ØµØ§Ù„Ø§Øª',
      subtitle: 'Ø£ÙˆØ¹ÙŠØ© Ù…Ù†Ø·Ù‚ÙŠØ© Ù…Ø«Ù„ Ø§Ù„Ø³ÙƒÙ† Ø£Ùˆ Ø§Ù„Ø¨ÙŠØªØŒ ÙˆÙ„ÙŠØ³Øª Ù…Ø­Ø§ÙØ¸ ÙØ¹Ù„ÙŠØ©',
      emptyText: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø­ØµØ§Ù„Ø§Øª Ø¨Ø¹Ø¯',
      wallets: [savingsWallet, ...hasalat],
      accentColor: Colors.teal,
      isRealWalletSection: false,
      primaryActionLabel: 'Ø¥Ø¶Ø§ÙØ© Ø­ØµØ§Ù„Ø©',
      onPrimaryAction: () => _showAddEditSideWalletDialog(
        context,
        startAsJar: true,
      ),
    );
  }

  Widget _buildWalletSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String emptyText,
    required List<Wallet> wallets,
    required Color accentColor,
    required bool isRealWalletSection,
    required String primaryActionLabel,
    required VoidCallback onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    final previewWallets = wallets.take(5).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: accentColor.withAlpha(18),
                    child: Icon(
                      isRealWalletSection
                          ? Icons.account_balance_wallet_outlined
                          : Icons.savings_outlined,
                      size: 18.r,
                      color: accentColor,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyle.style18Bold.copyWith(
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              6.verticalSpace,
              Text(
                subtitle,
                style: AppTextStyle.style12W500.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
              12.verticalSpace,
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  if (secondaryActionLabel != null)
                    _buildSectionActionButton(
                      label: secondaryActionLabel,
                      icon: Icons.swap_horiz,
                      color: accentColor,
                      filled: false,
                      onTap: onSecondaryAction,
                    ),
                  _buildSectionActionButton(
                    label: primaryActionLabel,
                    icon: Icons.add,
                    color: accentColor,
                    filled: true,
                    onTap: onPrimaryAction,
                  ),
                  if (wallets.length > 5)
                    _buildSectionActionButton(
                      label: 'Ø§Ù„Ù…Ø²ÙŠØ¯',
                      icon: Icons.arrow_forward_ios_rounded,
                      color: accentColor,
                      filled: false,
                      onTap: () => _showWalletsSectionSheet(
                        context,
                        title: title,
                        wallets: wallets,
                        isRealWalletSection: isRealWalletSection,
                      ),
                    ),
                ],
              ),
            ],
          ),
          14.verticalSpace,
          if (wallets.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: AppTextStyle.style12W500.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            Column(
              children: previewWallets
                  .map(
                    (wallet) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _buildWalletListTile(context, wallet),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    final foreground = filled ? Colors.white : color;
    final background = filled ? color : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: onTap == null ? Colors.grey.shade300 : color.withAlpha(90),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.r,
              color: onTap == null ? Colors.grey.shade400 : foreground,
            ),
            6.horizontalSpace,
            Text(
              label,
              style: AppTextStyle.style12Bold.copyWith(
                color: onTap == null ? Colors.grey.shade400 : foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletListTile(BuildContext context, Wallet wallet) {
    final accentColor = wallet.isSavingsWallet
        ? const Color(0xFFFF7A00)
        : wallet.isHasala
            ? Colors.teal
            : AppColors.primaryTextColor;

    final subtitle = wallet.isSavingsWallet
        ? 'Ø­ØµØ§Ù„Ø© Ø§Ù„ØªÙˆÙÙŠØ±'
        : wallet.isHasala
            ? wallet.plannedMonthlyFunding > 0
                ? 'ØªÙ…ÙˆÙŠÙ„ Ø´Ù‡Ø±ÙŠ ${wallet.plannedMonthlyFunding.toStringAsFixed(2)} Ø¬.Ù…'
                : 'Ø­ØµØ§Ù„Ø©'
            : 'Ù…Ø­ÙØ¸Ø© ÙØ¹Ù„ÙŠØ©';

    final amountLabel = wallet.isRealWallet ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙÙ„ÙˆØ³' : 'Ø§Ù„Ø±ØµÙŠØ¯ Ø§Ù„Ø­Ø§Ù„ÙŠ';

    return InkWell(
      onTap: () => _showWalletDetailsSheet(context, wallet),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: accentColor.withAlpha(18),
                child: Icon(
                  WalletIconMapper.resolveDetailed(
                  wallet.iconName,
                  isJar: wallet.isSavingsWallet || wallet.isHasala,
                ),
                color: accentColor,
                size: 20.r,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: AppTextStyle.style14Bold.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyle.style12W500.copyWith(
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  wallet.balance.toStringAsFixed(2),
                  style: AppTextStyle.style14Bold.copyWith(
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,
                Text(
                  amountLabel,
                  style: AppTextStyle.style12W500.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            10.horizontalSpace,
            Icon(
              Icons.arrow_forward_ios_outlined,
              size: 14.r,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletsSectionSheet(
    BuildContext context, {
    required String title,
    required List<Wallet> wallets,
    required bool isRealWalletSection,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyle.style18Bold,
                  ),
                  const Spacer(),
                  Text(
                    '${wallets.length} Ø¹Ù†ØµØ±',
                    style: AppTextStyle.style12W500.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Expanded(
                child: ListView.separated(
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => 10.verticalSpace,
                  itemBuilder: (context, index) =>
                      _buildWalletListTile(ctx, wallets[index]),
                ),
              ),
              if (isRealWalletSection) 8.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  void _showWalletDetailsSheet(BuildContext context, Wallet wallet) {
    final transactionState = context.read<TransactionCubit>().state;
    final walletState = context.read<WalletCubit>().state;
    final wallets = walletState is WalletLoaded ? walletState.wallets : <Wallet>[];
    final categories = transactionState.allCategories;
    final relatedTransactions = transactionState.allTransactions.where((tx) {
      if (wallet.isRealWallet || wallet.isSavingsWallet) {
        return tx.walletId == wallet.id ||
            tx.fromWalletId == wallet.id ||
            tx.toWalletId == wallet.id;
      }

      return tx.budgetBucketId == wallet.id ||
          tx.allocationId == wallet.id ||
          tx.categoryId == wallet.id ||
          tx.walletId == wallet.id ||
          tx.fromWalletId == wallet.id ||
          tx.toWalletId == wallet.id;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayedTransactions = relatedTransactions.take(12).toList();

    final accentColor = wallet.isSavingsWallet
        ? const Color(0xFFFF7A00)
        : wallet.isHasala
            ? Colors.teal
            : AppColors.primaryTextColor;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: accentColor.withAlpha(18),
                      child: Icon(
                        WalletIconMapper.resolveDetailed(
                          wallet.iconName,
                          isJar: wallet.isSavingsWallet || wallet.isHasala,
                        ),
                        color: accentColor,
                        size: 22.r,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wallet.name, style: AppTextStyle.style18Bold),
                          4.verticalSpace,
                          Text(
                            wallet.isSavingsWallet
                                ? 'Ø­ØµØ§Ù„Ø© Ø§Ù„ØªÙˆÙÙŠØ±'
                                : wallet.isHasala
                                    ? 'Ø­ØµØ§Ù„Ø©'
                                    : 'Ù…Ø­ÙØ¸Ø© ÙØ¹Ù„ÙŠØ©',
                            style: AppTextStyle.style12W500.copyWith(
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                18.verticalSpace,
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: [
                    _buildWalletDetailStat(
                      label: wallet.isRealWallet ? 'Ø§Ù„Ø±ØµÙŠØ¯ Ø§Ù„ÙƒÙ„ÙŠ' : 'Ø§Ù„Ø±ØµÙŠØ¯ Ø§Ù„Ø­Ø§Ù„ÙŠ',
                      value: '${wallet.balance.toStringAsFixed(2)} Ø¬.Ù…',
                      color: accentColor,
                    ),
                    if (!wallet.isRealWallet)
                      _buildWalletDetailStat(
                        label: 'Ø§Ù„ØªÙ…ÙˆÙŠÙ„ Ø§Ù„Ø´Ù‡Ø±ÙŠ',
                        value:
                            '${wallet.plannedMonthlyFunding.toStringAsFixed(2)} Ø¬.Ù…',
                        color: accentColor,
                      ),
                    _buildWalletDetailStat(
                      label: 'Ø¹Ø¯Ø¯ Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª',
                      value: '${relatedTransactions.length}',
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
                20.verticalSpace,
                Text(
                  'Ø¢Ø®Ø± Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª',
                  style: AppTextStyle.style14Bold,
                ),
                12.verticalSpace,
                Expanded(
                  child: relatedTransactions.isEmpty
                      ? Center(
                          child: Text(
                            'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¹Ù…Ù„ÙŠØ§Øª Ù…Ø±ØªØ¨Ø·Ø© Ø¨Ù‡Ø°Ø§ Ø§Ù„Ø¹Ù†ØµØ± Ø­ØªÙ‰ Ø§Ù„Ø¢Ù†',
                            style: AppTextStyle.style12W500.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: displayedTransactions.length,
                          separatorBuilder: (_, __) => 10.verticalSpace,
                          itemBuilder: (context, index) {
                            final transaction = displayedTransactions[index];
                            return _buildWalletTransactionTile(
                              transaction: transaction,
                              wallets: wallets,
                              categories: categories,
                            );
                          },
                        ),
                ),
                12.verticalSpace,
                Row(
                  children: [
                    if (wallet.isRealWallet) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAllocationDialog(
                              context,
                              initialWallet: wallet,
                            );
                          },
                          icon: const Icon(Icons.move_to_inbox_outlined),
                          label: const Text('ØªØ®ØµÙŠØµ'),
                        ),
                      ),
                      10.horizontalSpace,
                    ],
                    if (wallet.isHasala || wallet.isSavingsWallet) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAllocationDialog(
                              context,
                              initialJar: wallet,
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Ø¥Ø¶Ø§ÙØ© ØªØ®ØµÙŠØµ'),
                        ),
                      ),
                      10.horizontalSpace,
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditSideWalletDialog(context, wallet: wallet);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('ØªØ¹Ø¯ÙŠÙ„'),
                      ),
                    ),
                    if (!wallet.isSavingsWallet) ...[
                      10.horizontalSpace,
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _deleteWallet(context, wallet);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Ø­Ø°Ù',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                10.verticalSpace,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletDetailStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyle.style12W500.copyWith(color: color),
          ),
          4.verticalSpace,
          Text(
            value,
            style: AppTextStyle.style14Bold.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTransactionTile({
    required Transaction transaction,
    required List<Wallet> wallets,
    required List<TransactionCategory> categories,
  }) {
    final categoryName = categories
        .where((category) => category.id == transaction.primaryCategoryId)
        .map((category) => category.name)
        .firstWhere((_) => true, orElse: () => 'Ø¨Ø¯ÙˆÙ† ØªØµÙ†ÙŠÙ');

    String title;
    if (transaction.type == TransactionType.transfer) {
      final fromName = wallets
          .where((wallet) => wallet.id == transaction.fromWalletId)
          .map((wallet) => wallet.name)
          .firstWhere((_) => true, orElse: () => 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯');
      final toName = wallets
          .where((wallet) => wallet.id == transaction.toWalletId)
          .map((wallet) => wallet.name)
          .firstWhere((_) => true, orElse: () => 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯');
      title = 'ØªØ­ÙˆÙŠÙ„: $fromName Ø¥Ù„Ù‰ $toName';
    } else if (transaction.type == TransactionType.income) {
      title = 'Ø¯Ø®Ù„';
    } else if (transaction.type == TransactionType.expense) {
      title = 'Ù…ØµØ±ÙˆÙ';
    } else {
      title = 'Ø¥Ø¹Ø§Ø¯Ø© ØªÙˆØ²ÙŠØ¹';
    }

    final amountColor = transaction.type == TransactionType.expense
        ? Colors.red.shade600
        : Colors.green.shade700;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: amountColor.withAlpha(16),
            child: Icon(
              transaction.type == TransactionType.expense
                  ? Icons.call_made
                  : transaction.type == TransactionType.transfer
                      ? Icons.swap_horiz
                      : Icons.call_received,
              size: 16.r,
              color: amountColor,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.style12Bold),
                4.verticalSpace,
                Text(
                  categoryName,
                  style: AppTextStyle.style12W500.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if ((transaction.note ?? '').trim().isNotEmpty) ...[
                  4.verticalSpace,
                  Text(
                    transaction.note!,
                    style: AppTextStyle.style12W500.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount.toStringAsFixed(2)} Ø¬.Ù…',
                style: AppTextStyle.style12Bold.copyWith(color: amountColor),
              ),
              4.verticalSpace,
              Text(
                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                style: AppTextStyle.style12W500.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet(BuildContext context, Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text(
            'ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø°Ù',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            wallet.isHasala
                ? 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø­Ø°Ù Ø§Ù„Ø­ØµØ§Ù„Ø© "${wallet.name}"ØŸ'
                : 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø­Ø°Ù Ø§Ù„Ù…Ø­ÙØ¸Ø© "${wallet.name}"ØŸ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'ØªØ±Ø§Ø¬Ø¹',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Ø­Ø°Ù',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<WalletCubit>().deleteWallet(wallet.id);
    if (!wallet.isSavingsWallet) {
      await context.read<TransactionCubit>().deleteCategory(wallet.id);
    }
    if (!context.mounted) {
      return;
    }
    context.read<MonthlyPlanCubit>().refreshBudgetSummary();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wallet.isHasala ? 'ØªÙ… Ø­Ø°Ù Ø§Ù„Ø­ØµØ§Ù„Ø© Ø¨Ù†Ø¬Ø§Ø­' : 'ØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ø­ÙØ¸Ø© Ø¨Ù†Ø¬Ø§Ø­',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRolloverToSavingsDialog(
    BuildContext context,
    double netRemaining,
    String savingsWalletId,
    List<Wallet> actualWallets,
  ) {
    String? selectedSourceWalletId;
    final amountCtrl = TextEditingController(
      text: netRemaining.toStringAsFixed(2),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ØªØ±Ø­ÙŠÙ„ Ø§Ù„ÙØ§Ø¦Ø¶ Ù„Ù…Ø­ÙØ¸Ø© Ø§Ù„ØªÙˆÙÙŠØ±',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  8.verticalSpace,
                  Text(
                    'ÙŠÙˆØ¬Ø¯ Ù„Ø¯ÙŠÙƒ ÙØ§Ø¦Ø¶ Ù…ÙŠØ²Ø§Ù†ÙŠØ© Ù‡Ø°Ø§ Ø§Ù„Ø´Ù‡Ø± Ø¨Ù‚ÙŠÙ…Ø© ${netRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  20.verticalSpace,
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ù„Ù…Ø¨Ù„Øº Ø§Ù„Ù…Ø±Ø§Ø¯ ØªØ±Ø­ÙŠÙ„Ù‡',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  16.verticalSpace,
                  DropdownButtonFormField<String>(
                    initialValue: selectedSourceWalletId,
                    decoration: const InputDecoration(
                      labelText: 'Ø³Ø­Ø¨ Ø§Ù„ÙØ§Ø¦Ø¶ Ù…Ù† Ø£ÙŠ Ø­Ø³Ø§Ø¨ ÙØ¹Ù„ÙŠØŸ',
                      border: OutlineInputBorder(),
                    ),
                    items: actualWallets
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text('${w.name} (${w.balance})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedSourceWalletId = v),
                  ),
                  24.verticalSpace,
                  CustomPrimaryButton(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                      if (selectedSourceWalletId != null && amount > 0) {
                        final transferTx = Transaction(
                          id: const Uuid().v4(),
                          amount: amount,
                          date: DateTime.now(),
                          type: TransactionType.transfer,
                          fromWalletId: selectedSourceWalletId,
                          toWalletId: savingsWalletId,
                          note: 'ØªØ±Ø­ÙŠÙ„ ÙØ§Ø¦Ø¶ ÙŠØ¯ÙˆÙŠ',
                        );

                        context
                            .read<TransactionCubit>()
                            .addTransaction(transferTx)
                            .then((_) {
                              if (context.mounted) {
                                context.read<WalletCubit>().loadWallets();
                                context
                                    .read<MonthlyPlanCubit>()
                                    .refreshBudgetSummary();
                              }
                            });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ØªÙ… ØªØ±Ø­ÙŠÙ„ Ø§Ù„ÙØ§Ø¦Ø¶ Ø¨Ù†Ø¬Ø§Ø­! ðŸš€',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color(0xFF00A86B),
                          ),
                        );
                      }
                    },
                    text: 'ØªØ£ÙƒÙŠØ¯ Ø§Ù„ØªØ±Ø­ÙŠÙ„',
                  ),
                  10.verticalSpace,
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditSideWalletDialog(
    BuildContext context, {
    Wallet? wallet,
    bool startAsJar = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddSideWalletForm(
          wallet: wallet,
          startAsJar: startAsJar,
        ),
      ),
    );
  }
}

class _AddSideWalletForm extends StatefulWidget {
  const _AddSideWalletForm({
    this.wallet,
    this.startAsJar = false,
  });

  final Wallet? wallet;
  final bool startAsJar;

  @override
  State<_AddSideWalletForm> createState() => _AddSideWalletFormState();
}

class _AddSideWalletFormState extends State<_AddSideWalletForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _monthlyAmountController;
  late final TextEditingController _executionDayController;
  late String _selectedIconName;
  late Color _selectedColor;

  bool _isJar = false;
  ExecutionType _executionType = ExecutionType.confirm;
  String? _sourceWalletId;

  bool get _isEditing => widget.wallet != null;

  String get _sheetTitle {
    if (_isEditing) {
      return _isJar ? 'تعديل الحصالة' : 'تعديل المحفظة';
    }
    return _isJar ? 'إضافة حصالة جديدة' : 'إضافة محفظة جديدة';
  }

  String get _saveLabel => _isJar ? 'حفظ الحصالة' : 'حفظ المحفظة';
  String get _nameLabel => _isJar ? 'اسم الحصالة' : 'اسم المحفظة';
  String get _balanceLabel => _isJar ? 'الرصيد الحالي داخل الحصالة' : 'الرصيد الحالي';
  String get _iconLabel => _isJar ? 'أيقونة الحصالة' : 'أيقونة المحفظة';

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _isJar = wallet?.type == WalletType.jar || (wallet == null && widget.startAsJar);
    _selectedColor = wallet?.colorValue != null
        ? Color(wallet!.colorValue!)
        : WalletIconMapper.colorChoices.first;
    _selectedIconName = wallet?.iconName ?? (_isJar
        ? WalletIconMapper.defaultJar
        : WalletIconMapper.defaultWallet);
    _nameController = TextEditingController(text: wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: wallet != null && wallet.balance != 0 ? wallet.balance.toString() : '',
    );
    _monthlyAmountController = TextEditingController(
      text: wallet?.monthlyAmount != null && wallet!.monthlyAmount != 0
          ? wallet.monthlyAmount.toString()
          : '',
    );
    _executionDayController = TextEditingController(
      text: wallet?.executionDay?.toString() ?? '1',
    );
    _executionType = wallet?.executionType == ExecutionType.none
        ? ExecutionType.confirm
        : wallet?.executionType ?? ExecutionType.confirm;
    _sourceWalletId = wallet?.sourceWalletId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _monthlyAmountController.dispose();
    _executionDayController.dispose();
    super.dispose();
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.style14Bold),
          if (subtitle != null) ...[
            4.verticalSpace,
            Text(
              subtitle,
              style: AppTextStyle.style12W500.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          14.verticalSpace,
          child,
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              WalletIconMapper.resolveDetailed(
                _selectedIconName,
                isJar: _isJar,
              ),
              color: Colors.white,
              size: 22.r,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_iconLabel, style: AppTextStyle.style14Bold),
                4.verticalSpace,
                Text(
                  'اختر نفس الأيقونات والألوان الموجودة في نسخة الويب.',
                  style: AppTextStyle.style12W500.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: WalletIconMapper.detailedChoices.map((choice) {
        final isSelected = _selectedIconName == choice.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconName = choice.id),
          child: Container(
            width: 74.w,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor.withAlpha(26) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.grey.shade300,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    choice.icon,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    size: 18.r,
                  ),
                ),
                6.verticalSpace,
                Text(
                  choice.label,
                  style: AppTextStyle.style12W500.copyWith(
                    color: Colors.black87,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: WalletIconMapper.colorChoices.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.white,
                width: isSelected ? 2.2 : 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planState = context.read<MonthlyPlanCubit>().state;
    final incomes = planState.plan?.incomes ?? [];

    if (_sourceWalletId != null && !incomes.any((income) => income.id == _sourceWalletId)) {
      _sourceWalletId = incomes.isNotEmpty ? incomes.first.id : null;
    }

    _sourceWalletId ??= incomes.isNotEmpty ? incomes.first.id : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.r, 20.r, 20.r, 24.r),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _sheetTitle,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              _buildSectionCard(
                title: 'البيانات الأساسية',
                subtitle: 'الاسم والرصد والأيقونة واللون مثل نفس خيارات الويب.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    14.verticalSpace,
                    Text('اختيار الأيقونة', style: AppTextStyle.style12W600),
                    10.verticalSpace,
                    _buildIconGrid(),
                    18.verticalSpace,
                    Text(
                      _isJar ? 'اختيار لون الحصالة' : 'اختيار لون المحفظة',
                      style: AppTextStyle.style12W600,
                    ),
                    10.verticalSpace,
                    _buildColorGrid(),
                    18.verticalSpace,
                    CustomPrimaryTextfield(
                      controller: _nameController,
                      text: _nameLabel,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'مطلوب'
                          : null,
                    ),
                    10.verticalSpace,
                    CustomPrimaryTextfield(
                      controller: _balanceController,
                      text: _balanceLabel,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              if (_isJar) ...[
                16.verticalSpace,
                _buildSectionCard(
                  title: 'إعدادات الحصالة',
                  subtitle: 'المساهمة الشهرية ونوع التنفيذ ويومه ومصدر التمويل.',
                  child: Column(
                    children: [
                      CustomPrimaryTextfield(
                        controller: _monthlyAmountController,
                        text: 'المساهمة الشهرية',
                        keyboardType: TextInputType.number,
                      ),
                      10.verticalSpace,
                      CustomPrimaryTextfield(
                        controller: _executionDayController,
                        text: 'يوم التنفيذ (1-31)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final day = int.tryParse(value ?? '');
                          if (day == null || day < 1 || day > 31) {
                            return 'أدخل يومًا صحيحًا من 1 إلى 31';
                          }
                          return null;
                        },
                      ),
                      10.verticalSpace,
                      DropdownButtonFormField<ExecutionType>(
                        value: _executionType,
                        decoration: const InputDecoration(labelText: 'نوع التنفيذ'),
                        items: const [
                          DropdownMenuItem(
                            value: ExecutionType.auto,
                            child: Text('تلقائي'),
                          ),
                          DropdownMenuItem(
                            value: ExecutionType.confirm,
                            child: Text('يحتاج تأكيد'),
                          ),
                          DropdownMenuItem(
                            value: ExecutionType.manual,
                            child: Text('يدوي'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _executionType = value);
                          }
                        },
                      ),
                      10.verticalSpace,
                      DropdownButtonFormField<String>(
                        value: _sourceWalletId,
                        decoration: const InputDecoration(labelText: 'مصدر التمويل'),
                        items: incomes
                            .map(
                              (income) => DropdownMenuItem(
                                value: income.id,
                                child: Text(income.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _sourceWalletId = value),
                      ),
                    ],
                  ),
                ),
              ],
              20.verticalSpace,
              CustomPrimaryButton(
                onPressed: () {
                  _save();
                },
                text: _saveLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isNewWallet = widget.wallet == null;
    final walletId = widget.wallet?.id ?? const Uuid().v4();
    final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
    final monthlyAmount = double.tryParse(_monthlyAmountController.text) ?? 0.0;
    final executionDay = int.tryParse(_executionDayController.text) ?? 1;

    final wallet = Wallet(
      id: walletId,
      name: _nameController.text.trim(),
      balance: isNewWallet ? 0.0 : initialBalance,
      iconName: _selectedIconName,
      colorValue: _selectedColor.value,
      type: _isJar ? WalletType.jar : WalletType.real,
      monthlyAmount: _isJar ? monthlyAmount : null,
      executionDay: _isJar ? executionDay : null,
      executionType: _isJar ? _executionType : ExecutionType.none,
      sourceWalletId: _isJar ? _sourceWalletId : null,
    );

    final linkedCategory = TransactionCategory(
      id: walletId,
      name: _nameController.text.trim(),
      type: TransactionType.expense,
      colorValue: _selectedColor.value,
      targetWalletId: walletId,
    );

    if (isNewWallet) {
      await context.read<WalletCubit>().addWallet(wallet);
      await context.read<TransactionCubit>().addCategory(linkedCategory);

      if (initialBalance > 0) {
        final initialTransaction = Transaction(
          id: const Uuid().v4(),
          walletId: walletId,
          amount: initialBalance,
          type: TransactionType.income,
          date: DateTime.now(),
          budgetBucketId: _isJar ? walletId : null,
          budgetBucketType: _isJar ? BudgetBucketType.jar : null,
          note: _isJar ? 'رصيد افتتاحي للحصالة' : 'رصيد افتتاحي للمحفظة',
        );
        await context.read<TransactionCubit>().addTransaction(initialTransaction);
      }
    } else {
      await context.read<WalletCubit>().updateWallet(wallet);
      await context.read<TransactionCubit>().updateCategory(linkedCategory);
    }

    if (!mounted) {
      return;
    }

    await context.read<WalletCubit>().loadWallets();
    if (mounted) {
      context.read<MonthlyPlanCubit>().refreshBudgetSummary();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJar ? 'تم حفظ الحصالة بنجاح' : 'تم حفظ المحفظة بنجاح'),
        ),
      );
    }
  }
}
void _showAllocationDialog(
  BuildContext context, {
  Wallet? initialWallet,
  Wallet? initialJar,
}) {
  final walletState = context.read<WalletCubit>().state;
  if (walletState is! WalletLoaded) {
    return;
  }

  final realWallets = walletState.wallets.where((wallet) => wallet.isRealWallet).toList();
  final jarWallets = walletState.wallets
      .where((wallet) => wallet.isHasala || wallet.isSavingsWallet)
      .toList()
    ..sort((a, b) {
      if (a.isSavingsWallet == b.isSavingsWallet) {
        return 0;
      }
      return a.isSavingsWallet ? -1 : 1;
    });

  if (realWallets.isEmpty || jarWallets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ø£Ø¶Ù Ù…Ø­ÙØ¸Ø© ÙØ¹Ù„ÙŠØ© ÙˆØ­ØµØ§Ù„Ø© Ø£ÙˆÙ„Ù‹Ø§ Ù‚Ø¨Ù„ ØªÙ†ÙÙŠØ° Ø§Ù„ØªØ®ØµÙŠØµ'),
      ),
    );
    return;
  }

  String? fromWalletId = initialWallet?.id ?? realWallets.first.id;
  String? toJarId = initialJar?.id ?? jarWallets.first.id;
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet<void>(
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 8.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ØªØ®ØµÙŠØµ Ù…Ù† Ù…Ø­ÙØ¸Ø© Ø¥Ù„Ù‰ Ø­ØµØ§Ù„Ø©',
                style: AppTextStyle.style18W700.copyWith(
                  color: AppColors.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              Text(
                'Ù†ÙØ³ ÙÙƒØ±Ø© Ø§Ù„ÙˆÙŠØ¨: Ø§Ù„ÙÙ„ÙˆØ³ ØªØªØ­Ø±Ùƒ Ù…Ù† Ø§Ù„Ù…Ø­ÙØ¸Ø© Ø§Ù„ÙØ¹Ù„ÙŠØ©ØŒ ÙˆØªÙØ³Ø¬Ù„ Ø¹Ù„Ù‰ Ø§Ù„Ø­ØµØ§Ù„Ø© Ø£Ùˆ Ø§Ù„ØªÙˆÙÙŠØ±.',
                style: AppTextStyle.style12W500.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              20.verticalSpace,
              CustomDropdownButtonFormField<String>(
                hintText: 'Ù…Ù† Ù…Ø­ÙØ¸Ø©',
                value: fromWalletId,
                items: realWallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name, style: AppTextStyle.style12W500),
                      ),
                    )
                    .toList(),
                onChanged: (value) => fromWalletId = value,
                validator: (value) => value == null ? 'Ø­Ø¯Ø¯ Ø§Ù„Ù…Ø­ÙØ¸Ø©' : null,
              ),
              12.verticalSpace,
              CustomDropdownButtonFormField<String>(
                hintText: 'Ø¥Ù„Ù‰ Ø­ØµØ§Ù„Ø©',
                value: toJarId,
                items: jarWallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name, style: AppTextStyle.style12W500),
                      ),
                    )
                    .toList(),
                onChanged: (value) => toJarId = value,
                validator: (value) => value == null ? 'Ø­Ø¯Ø¯ Ø§Ù„Ø­ØµØ§Ù„Ø©' : null,
              ),
              12.verticalSpace,
              CustomPrimaryTextfield(
                controller: amountController,
                text: 'Ø§Ù„Ù…Ø¨Ù„Øº',
                style: AppTextStyle.style12W500.copyWith(
                  color: AppColors.textGreyColor,
                ),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null) {
                    return 'Ø£Ø¯Ø®Ù„ Ø±Ù‚Ù…Ù‹Ø§ ØµØ­ÙŠØ­Ù‹Ø§';
                  }
                  if (amount <= 0) {
                    return 'Ø§Ù„Ù…Ø¨Ù„Øº ÙŠØ¬Ø¨ Ø£Ù† ÙŠÙƒÙˆÙ† Ø£ÙƒØ¨Ø± Ù…Ù† ØµÙØ±';
                  }
                  return null;
                },
              ),
              24.verticalSpace,
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Ø¥Ù„ØºØ§Ø¡', style: AppTextStyle.style14W500),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final sourceWallet = realWallets.firstWhere(
                          (wallet) => wallet.id == fromWalletId,
                        );
                        final targetJar = jarWallets.firstWhere(
                          (wallet) => wallet.id == toJarId,
                        );
                        final amount = double.parse(amountController.text);

                        if (sourceWallet.balance < amount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ø§Ù„Ø±ØµÙŠØ¯ ØºÙŠØ± ÙƒØ§ÙÙ Ø¯Ø§Ø®Ù„ ${sourceWallet.name}',
                              ),
                            ),
                          );
                          return;
                        }

                        final transaction = Transaction(
                          id: const Uuid().v4(),
                          amount: amount,
                          date: DateTime.now(),
                          type: TransactionType.transfer,
                          fromWalletId: sourceWallet.id,
                          toWalletId: targetJar.id,
                          budgetBucketId: targetJar.isHasala ? targetJar.id : null,
                          budgetBucketType: targetJar.isHasala
                              ? BudgetBucketType.jar
                              : null,
                          note: targetJar.isSavingsWallet
                              ? 'ØªØ®ØµÙŠØµ Ù„Ù„ØªÙˆÙÙŠØ±'
                              : 'ØªØ®ØµÙŠØµ Ø¥Ù„Ù‰ ${targetJar.name}',
                        );

                        await context.read<TransactionCubit>().addTransaction(
                          transaction,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        await context.read<WalletCubit>().loadWallets();
                        if (context.mounted) {
                          context.read<MonthlyPlanCubit>().refreshBudgetSummary();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                targetJar.isSavingsWallet
                                    ? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„ØªØ®ØµÙŠØµ Ù„Ù„ØªÙˆÙÙŠØ±'
                                    : 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„ØªØ®ØµÙŠØµ Ù„Ù„Ø­ØµØ§Ù„Ø©',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'ØªØ£ÙƒÙŠØ¯ Ø§Ù„ØªØ®ØµÙŠØµ',
                        style: AppTextStyle.style14W500.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showTransferDialog(BuildContext context, List<Wallet> wallets) {
  final availableWallets = wallets;

  String? fromWalletId;
  String? toWalletId;
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet<void>(
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          children: [
            Text(
              'Ù†Ù‚Ù„ Ù…Ø¨Ù„Øº Ø¨ÙŠÙ† Ø§Ù„Ù…Ø­Ø§ÙØ¸',
              style: AppTextStyle.style18W700.copyWith(
                color: AppColors.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            20.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12.h,
                  children: [
                    CustomDropdownButtonFormField<String>(
                      hintText: 'Ù…Ù† Ù…Ø­ÙØ¸Ø©',
                      items: availableWallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                '${w.name} (${w.balance.truncate()} Ø¬.Ù…)',
                                style: AppTextStyle.style12W500,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => fromWalletId = v,
                      validator: (v) => v == null ? 'Ø­Ø¯Ø¯ Ø§Ù„Ù…Ø­ÙØ¸Ø©' : null,
                    ),
                    CustomDropdownButtonFormField<String>(
                      hintText: 'Ø¥Ù„Ù‰ Ù…Ø­ÙØ¸Ø©',
                      items: availableWallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => toWalletId = v,
                      validator: (v) => v == null ? 'Ø­Ø¯Ø¯ Ø§Ù„Ù…Ø­ÙØ¸Ø©' : null,
                    ),
                    CustomPrimaryTextfield(
                      controller: amountController,
                      text: 'Ø§Ù„Ù…Ø¨Ù„Øº Ø§Ù„Ù…Ø±Ø§Ø¯ ØªØ­ÙˆÙŠÙ„Ù‡',
                      style: AppTextStyle.style12W500.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || double.tryParse(v) == null) {
                          return 'Ø£Ø¯Ø®Ù„ Ø±Ù‚Ù… ØµØ­ÙŠØ­';
                        }
                        if (double.parse(v) <= 0) {
                          return 'Ø§Ù„Ù…Ø¨Ù„Øº ÙŠØ¬Ø¨ Ø£Ù† ÙŠÙƒÙˆÙ† Ø£ÙƒØ¨Ø± Ù…Ù† ØµÙØ±';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            30.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Ø¥Ù„ØºØ§Ø¡',
                      style: AppTextStyle.style14W500,
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          if (fromWalletId == toWalletId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ù„Ø§ ÙŠÙ…ÙƒÙ† Ø§Ù„ØªØ­ÙˆÙŠÙ„ Ù„Ù†ÙØ³ Ø§Ù„Ù…Ø­ÙØ¸Ø©!',
                                  style: AppTextStyle.style14W500,
                                ),
                              ),
                            );
                            return;
                          }

                          final transferTx = Transaction(
                            id: const Uuid().v4(),
                            amount: double.parse(amountController.text),
                            date: DateTime.now(),
                            type: TransactionType.transfer,
                            fromWalletId: fromWalletId,
                            toWalletId: toWalletId,
                            note: 'ØªØ­ÙˆÙŠÙ„ ÙŠØ¯ÙˆÙŠ',
                          );

                          context
                              .read<TransactionCubit>()
                              .addTransaction(transferTx)
                              .then((_) {
                                if (context.mounted) {
                                  context.read<WalletCubit>().loadWallets();
                                  context
                                      .read<MonthlyPlanCubit>()
                                      .refreshBudgetSummary();
                                }
                              });

                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        'ØªØ£ÙƒÙŠØ¯ Ø§Ù„ØªØ­ÙˆÙŠÙ„',
                        style: AppTextStyle.style14W500.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}



