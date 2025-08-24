import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: '.._-',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // рекомендовано
    ),
  );

  runApp(const MyApp());
}
