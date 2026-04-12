import 'package:flutter/material.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: true,
        heightBar: 80.h,
        title: 'شرح التطبيق',
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: const [
          _GuideSection(
            title: 'الفكرة الأساسية',
            icon: Icons.lightbulb_outline_rounded,
            points: [
              'التطبيق يفصل بين الفلوس الحقيقية وبين التخطيط المالي.',
              'المحافظ الفعلية هي أماكن الفلوس مثل الكاش والبنك والمحفظة الإلكترونية.',
              'الميزانية الشهرية هي خطة الدخل والمخصصات والديون وغير المخصص.',
            ],
          ),
          _GuideSection(
            title: 'الحصالات والتوفير',
            icon: Icons.savings_outlined,
            points: [
              'الحصالة وعاء منطقي مثل السكن أو البيت أو المشروع، وليست محفظة فعلية.',
              'حصالة التوفير تمثل جزءًا مدخرًا من فلوسك الموجودة أصلًا داخل المحافظ.',
              'يمكن تمويل الحصالات من الخطة أو ربط معاملات بها بدون نقل الفلوس فعليًا من مكان لمكان جديد.',
            ],
          ),
          _GuideSection(
            title: 'طريقة تسجيل المعاملة',
            icon: Icons.receipt_long_outlined,
            points: [
              'اختر أولًا المحفظة الفعلية التي تحركت فيها الفلوس.',
              'حدد هل العملية داخل الميزانية أم خارجها.',
              'لو كانت داخل الميزانية تختار مخصصًا أو حصالة، ولو خارجها تختار فئة عامة.',
            ],
          ),
          _GuideSection(
            title: 'صفحة الميزانية',
            icon: Icons.pie_chart_outline_rounded,
            points: [
              'هذه الصفحة للمتابعة الفعلية وليست محفظة.',
              'تُظهر الدخل والمخصصات والحصالات والديون وحالة التنفيذ خلال الدورة.',
              'الشهور القديمة تُعرض كتاريخ، والشهر القادم يمكن بدء خطته من إعداد الميزانية.',
            ],
          ),
          _GuideSection(
            title: 'السجلات والتراجع',
            icon: Icons.history_rounded,
            points: [
              'أي تعديل مهم داخل التطبيق يجب أن يسجل في السجلات.',
              'السجل لا يحذف، ويمكن استخدام التراجع أو إلغاء التراجع حسب العملية.',
              'هذا يساعدك تعرف ماذا تغيّر ومتى حصل التغيير.',
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.icon,
    required this.points,
  });

  final String title;
  final IconData icon;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryColor.withAlpha(16),
                child: Icon(
                  icon,
                  size: 18.r,
                  color: AppColors.primaryColor,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.style16Bold.copyWith(
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          14.verticalSpace,
          ...points.map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Text(
                      point,
                      style: AppTextStyle.style12W500.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
