import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: PreSalesProApp()));
}

class PreSalesProApp extends ConsumerWidget {
  const PreSalesProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure auth state is initialized on startup
    ref.watch(authProvider);
    return MaterialApp.router(
      title: 'PreSales Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
