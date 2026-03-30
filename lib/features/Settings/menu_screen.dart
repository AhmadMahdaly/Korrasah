import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/constants.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/shared_widgets/page_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: false,
        heightBar: 80.h,
        title: 'القائمة', // أو الإعدادات حسب رغبتك
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // 1. إعداد الميزانية
            _buildMenuItem(
              title: 'إعداد الميزانية',
              subtitle: 'إدارة الدخل والمخصصات',
              icon: Icons.grid_view_rounded,
              gradientColors: [
                const Color(0xFF00C689),
                const Color(0xFF00A86B),
              ],
              onTap: () {
                context.push(AppRoutes.setupMonthlyPlanScreen);
              },
            ),

            // 2. إعداد الفئات
            _buildMenuItem(
              title: 'إعداد الفئات',
              subtitle: 'تخصيص فئات المصروفات',
              icon: Icons.window_rounded,
              gradientColors: [
                const Color(0xFF5A8BFF),
                const Color(0xFF2962FF),
              ],
              onTap: () {
                context.push(AppRoutes.manageCategoriesScreen);
              },
            ),

            // 3. الأهداف
            _buildMenuItem(
              title: 'الأهداف',
              subtitle: 'تتبع أهدافك المالية',
              icon: Icons.track_changes_rounded,
              gradientColors: [
                const Color(0xFFD642D0),
                const Color(0xFF9E00C5),
              ],
              onTap: () {
                context.pushNamed(AppRoutes.financialGoalsScreen);
              },
            ),

            // 4. السجلات
            _buildMenuItem(
              title: 'السجلات',
              subtitle: 'عرض جميع التغييرات',
              icon: Icons.receipt_long_rounded,
              gradientColors: [
                const Color(0xFFFF7A00),
                const Color(0xFFFF3D00),
              ],
              onTap: () {
                // context.push(AppRoutes.transferHistoryScreen);
              },
            ),

            // 5. الإشعارات
            _buildMenuItem(
              title: 'الإشعارات',
              subtitle: 'إدارة التنبيهات',
              icon: Icons.notifications_rounded,
              gradientColors: [
                const Color(0xFFFFB300),
                const Color(0xFFF57C00),
              ],
              onTap: () {
                context.push(AppRoutes.notificationsScreen);
              },
            ),

            // 6. إعدادات التطبيق
            // _buildMenuItem(
            //   title: 'إعدادات التطبيق',
            //   subtitle: 'تخصيص الإعدادات العامة',
            //   icon: Icons.settings_rounded,
            //   gradientColors: [
            //     const Color(0xFF788496),
            //     const Color(0xFF455A64),
            //   ],
            //   onTap: () {
            //     // TODO: مسار إعدادات التطبيق العامة
            //   },
            // ),
            24.verticalSpace,

            // الفوتر (صُنع بحب)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.black.withAlpha(15)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'صُنع بـ ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent,
                        size: 18,
                      ),
                      Text(
                        ' لمساعدتك في إدارة أموالك',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Text(
                    '© 2026 $kAppName. جميع الحقوق محفوظة.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء الكروت وتوحيد التصميم
  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_outlined,
          size: 16.r,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
