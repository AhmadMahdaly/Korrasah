import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/shared_widgets/show_custom_snackbar.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/auth/presentation/cubit/login_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  static const _currencyKey = CacheKeys.selectedCurrency;
  static const _notificationsKey = CacheKeys.notificationsEnabled;

  final TextEditingController _nameController = TextEditingController();
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  String _selectedCurrency = 'EGP';
  bool _notificationsEnabled = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await PackageInfo.fromPlatform();
    final savedName = _prefs.getString(CacheKeys.userName) ?? '';
    final savedCurrency = _prefs.getString(_currencyKey) ?? 'EGP';
    final savedNotifications = _prefs.getBool(_notificationsKey) ?? true;

    if (!mounted) return;
    setState(() {
      _nameController.text = savedName;
      _selectedCurrency = savedCurrency;
      _notificationsEnabled = savedNotifications;
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _saveSettings() async {
    final userName = _nameController.text.trim();
    if (userName.isEmpty) {
      showCustomSnackBar(
        context,
        message: 'اكتب اسم المستخدم أولًا',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    await _prefs.setString(_currencyKey, _selectedCurrency);
    await _prefs.setBool(_notificationsKey, _notificationsEnabled);
    await context.read<AuthCubit>().login(userName);

    if (!mounted) return;
    showCustomSnackBar(context, message: 'تم حفظ الإعدادات بنجاح');
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف جميع البيانات'),
          content: const Text(
            'سيتم حذف المعاملات والمحافظ والخطط والأهداف من التخزين المحلي. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _prefs.clear();
    if (!mounted) return;
    context.go(AppRoutes.loginScreen);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const PageHeader(
        isLeading: true,
        heightBar: 86,
        title: 'إعدادات التطبيق',
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          _SettingsSection(
            title: 'التخصيص',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'اسم المستخدم',
                    hint: 'اكتب اسمك',
                  ),
                ),
                14.verticalSpace,
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: _inputDecoration(
                    label: 'العملة',
                    hint: 'اختر العملة',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري')),
                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي')),
                    DropdownMenuItem(value: 'EUR', child: Text('يورو')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCurrency = value);
                  },
                ),
                14.verticalSpace,
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryColor,
                  title: Text(
                    'تفعيل الإشعارات',
                    style: AppTextStyle.style14W600.copyWith(
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  subtitle: Text(
                    'التحكم في التنبيهات داخل التطبيق',
                    style: AppTextStyle.style12W400.copyWith(
                      color: AppColors.textGreyColor,
                    ),
                  ),
                ),
                10.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    onPressed: _saveSettings,
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          _SettingsSection(
            title: 'إدارة البيانات',
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Cloud Backup',
                  subtitle: 'نسخة احتياطية واستعادة عبر Google Drive',
                  onTap: () => context.pushNamed(AppRoutes.cloudBackupScreen),
                ),
                10.verticalSpace,
                _ActionTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'الإشعارات',
                  subtitle: 'راجع التنبيهات المعلقة والسجل',
                  onTap: () => context.pushNamed(AppRoutes.notificationsScreen),
                ),
                10.verticalSpace,
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'حذف جميع البيانات',
                  subtitle: 'مسح التخزين المحلي وإعادة البداية',
                  onTap: _clearAllData,
                  iconColor: AppColors.errorColor,
                ),
              ],
            ),
          ),
          16.verticalSpace,
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE5F8EF), Color(0xFFD8F1EA)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الميزانية',
                  style: AppTextStyle.style18W700.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                ),
                6.verticalSpace,
                Text(
                  'التنفيذ في Flutter والمرجع الوظيفي مأخوذ من نسخة الويب.',
                  style: AppTextStyle.style12W400.copyWith(
                    color: AppColors.textGreyColor,
                  ),
                ),
                12.verticalSpace,
                Text(
                  _version.isEmpty ? 'الإصدار قيد التحميل...' : 'الإصدار $_version',
                  style: AppTextStyle.style12Bold.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: BorderSide(color: Colors.black.withAlpha(14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: BorderSide(color: Colors.black.withAlpha(14)),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.style16W700.copyWith(
              color: AppColors.primaryTextColor,
            ),
          ),
          14.verticalSpace,
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      leading: CircleAvatar(
        radius: 22.r,
        backgroundColor: (iconColor ?? AppColors.primaryColor).withAlpha(18),
        child: Icon(icon, color: iconColor ?? AppColors.primaryColor),
      ),
      title: Text(
        title,
        style: AppTextStyle.style14W600.copyWith(
          color: AppColors.primaryTextColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyle.style12W400.copyWith(
          color: AppColors.textGreyColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16.r,
        color: AppColors.textGreyColor,
      ),
    );
  }
}
