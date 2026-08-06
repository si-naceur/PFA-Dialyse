import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfa_dialyse/core/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: PfaDialyseApp()));
}

class PfaDialyseApp extends StatelessWidget {
  const PfaDialyseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PFA Dialyse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
