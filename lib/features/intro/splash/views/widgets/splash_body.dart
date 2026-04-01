import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/constants.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/auth/presentation/cubit/login_cubit.dart';

class SplashBody extends StatefulWidget {
  const SplashBody({
    super.key,
  });

  @override
  State<SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<SplashBody> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        Future.delayed(const Duration(seconds: 4), () {
          if (state is Authenticated) {
            context.go(AppRoutes.mainLayoutScreen);
          } else if (state is Unauthenticated) {
            context.go(AppRoutes.loginScreen);
          }
        });
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.h,
        children: [
          SizedBox(
            width: 250.w,
            height: 250.h,
            child: Image.asset(
              'assets/image/logo.png',
            ),
          ),
          Text(
            kAppName,
            textAlign: TextAlign.center,
            style: AppTextStyle.style20W700.copyWith(
              color: AppColors.primaryColor,
              fontSize: 40.sp,
            ),
          ),

          const SubTitle(
            textColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}
