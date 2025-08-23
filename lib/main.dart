import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hssvwlkhhncgwgluciqz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhzc3Z3bGtoaG5jZ3dnbHVjaXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3OTcxMDQsImV4cCI6MjA3MTM3MzEwNH0.NnAHBx7ndqMw3DtbSLl8yhfgwCy3hMQb8XC6sK2CqZ8',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // рекомендовано
    ),
  );

  runApp(const MyApp());
}
