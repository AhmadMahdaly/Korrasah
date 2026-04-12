import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/services/app_settings_store.dart';
import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/shared_widgets/show_custom_snackbar.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/notifications/notification_history_entry.dart';
import 'package:opration/features/notifications/notification_history_store.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _NotificationsTab { unread, history }

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  final SharedPreferences _prefs = getIt<SharedPreferences>();
  late final NotificationHistoryStore _historyStore = NotificationHistoryStore(
    sharedPreferences: _prefs,
  );

  _NotificationsTab _tab = _NotificationsTab.unread;
  List<NotificationHistoryEntry> _history = const [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  void _loadLocalState() {
    setState(() {
      _history = _historyStore.loadHistory();
      _notificationsEnabled =
          _prefs.getBool(CacheKeys.notificationsEnabled) ?? true;
    });
  }

  Future<void> _handleApprove(TransactionCategory category) async {
    await context.read<TransactionCubit>().approvePendingTransaction(category);
    await _historyStore.addEntry(
      NotificationHistoryEntry(
        id: category.id,
        title: 'تم تأكيد "${category.name}"',
        description: _pendingDescription(category),
        actionLabel: 'تم التأكيد',
        createdAt: DateTime.now(),
      ),
    );
    _loadLocalState();
    if (!mounted) return;
    showCustomSnackBar(
      context,
      message: 'تم تسجيل "${category.name}" بنجاح',
    );
  }

  Future<void> _handleDismiss(TransactionCategory category) async {
    await context.read<TransactionCubit>().dismissPendingTransaction(category);
    await _historyStore.addEntry(
      NotificationHistoryEntry(
        id: category.id,
        title: 'تم إخفاء "${category.name}"',
        description: _pendingDescription(category),
        actionLabel: 'تم الإخفاء',
        createdAt: DateTime.now(),
      ),
    );
    _loadLocalState();
    if (!mounted) return;
    showCustomSnackBar(
      context,
      message: 'تم تجاهل الإشعار لليوم',
      backgroundColor: AppColors.textGreyColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const PageHeader(
        isLeading: true,
        heightBar: 86,
        title: 'الإشعارات',
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final pendingItems = state.pendingTransactions;
          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              if (!_notificationsEnabled)
                Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.black.withAlpha(14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإشعارات متوقفة حاليًا',
                        style: AppTextStyle.style16W700.copyWith(
                          color: AppColors.primaryTextColor,
                        ),
                      ),
                      8.verticalSpace,
                      Text(
                        'يمكنك إعادة تفعيلها من إعدادات التطبيق لو أردت متابعة العناصر المعلقة أولًا بأول.',
                        style: AppTextStyle.style12W400.copyWith(
                          color: AppColors.textGreyColor,
                        ),
                      ),
                      10.verticalSpace,
                      TextButton(
                        onPressed: () {
                          context.pushNamed(AppRoutes.appSettingsScreen);
                        },
                        child: const Text('فتح إعدادات التطبيق'),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: Colors.black.withAlpha(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'غير مقروء',
                        selected: _tab == _NotificationsTab.unread,
                        onTap: () {
                          setState(() => _tab = _NotificationsTab.unread);
                        },
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'السجل',
                        selected: _tab == _NotificationsTab.history,
                        onTap: () {
                          setState(() => _tab = _NotificationsTab.history);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              16.verticalSpace,
              if (_tab == _NotificationsTab.unread)
                _UnreadNotificationsList(
                  items: pendingItems,
                  onApprove: _handleApprove,
                  onDismiss: _handleDismiss,
                )
              else
                _HistoryNotificationsList(items: _history),
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.style12Bold.copyWith(
            color: selected ? Colors.white : AppColors.textGreyColor,
          ),
        ),
      ),
    );
  }
}

class _UnreadNotificationsList extends StatelessWidget {
  const _UnreadNotificationsList({
    required this.items,
    required this.onApprove,
    required this.onDismiss,
  });

  final List<TransactionCategory> items;
  final Future<void> Function(TransactionCategory category) onApprove;
  final Future<void> Function(TransactionCategory category) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _NotificationsEmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'لا توجد إشعارات غير مقروءة الآن',
        subtitle: 'كل العناصر المعلقة تمت مراجعتها.',
      );
    }

    return Column(
      children: items.map((category) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: category.color,
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تأكيد تسجيل "${category.name}"',
                          style: AppTextStyle.style14W700.copyWith(
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          _pendingDescription(category),
                          style: AppTextStyle.style12W400.copyWith(
                            color: AppColors.textGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onDismiss(category),
                    child: Text(
                      'إخفاء',
                      style: AppTextStyle.style12Bold.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                    ),
                  ),
                  8.horizontalSpace,
                  ElevatedButton(
                    onPressed: () => onApprove(category),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryNotificationsList extends StatelessWidget {
  const _HistoryNotificationsList({required this.items});

  final List<NotificationHistoryEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _NotificationsEmptyState(
        icon: Icons.history_rounded,
        title: 'لا توجد عناصر في السجل',
        subtitle: 'سيظهر هنا كل إشعار تم تأكيده أو إخفاؤه.',
      );
    }

    return Column(
      children: items.map((item) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: Colors.black.withAlpha(12)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFFF3F4F6),
                child: Icon(
                  Icons.history_rounded,
                  color: AppColors.primaryTextColor,
                  size: 20.r,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyle.style14W700.copyWith(
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      item.description,
                      style: AppTextStyle.style12W400.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                    ),
                    8.verticalSpace,
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _HistoryBadge(text: item.actionLabel),
                        _HistoryBadge(
                          text: DateFormat('d MMM - h:mm a', 'ar')
                              .format(item.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryBadge extends StatelessWidget {
  const _HistoryBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: AppTextStyle.style9Bold.copyWith(
          color: AppColors.primaryTextColor,
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 42.h, horizontal: 18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56.r, color: AppColors.textGreyColor),
          14.verticalSpace,
          Text(
            title,
            style: AppTextStyle.style16W700.copyWith(
              color: AppColors.primaryTextColor,
            ),
          ),
          8.verticalSpace,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle.style12W400.copyWith(
              color: AppColors.textGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}

String _pendingDescription(TransactionCategory category) {
  final appSettings = AppSettingsStore(sharedPreferences: getIt());
  final amount = category.fixedAmount ?? 0.0;
  assert(appSettings.currencySymbol.isNotEmpty);
  return 'المبلغ المتوقع ${amount.toStringAsFixed(2)} ج.م';
}
