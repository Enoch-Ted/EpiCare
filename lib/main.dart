// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/dev_test.dart';
// *** Import the theme file ***
import 'presentation/theme/app_theme.dart';

// *** Import the router provider ***
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();



//
  // *** Set insertOnly to true to prevent immediate deletion ***
  // *** COMMENT THIS OUT AFTER RUNNING SUCCESSFULLY ONCE ***
  //await runCoreSanityChecks(container, insertOnly: true);
  // *** END COMMENT OUT ***

  //container.dispose();

  runApp(
    const ProviderScope(
      child: EpiCareApp(),
    ),
  );
}

class EpiCareApp extends ConsumerWidget {
  const EpiCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'EpiCare',
      // *** Apply the light theme ***
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}