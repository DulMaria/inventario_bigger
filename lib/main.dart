import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'modules/auth/view/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventario',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4FAFE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6FC6EE), // Celeste claro Bygger
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6FC6EE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6FC6EE), // Celeste claro Bygger
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),

      home: const LoginView(),
    );
  }
}
