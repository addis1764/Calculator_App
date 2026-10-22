import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/routes.dart';
import 'core/theme.dart';

class CalcVaultApp extends StatelessWidget {
  const CalcVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.calculator,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
