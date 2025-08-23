import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://okvcvfyrbrevsjvysamy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rdmN2ZnlyYnJldnNqdnlzYW15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5NTk0ODEsImV4cCI6MjA3MTUzNTQ4MX0.C6DJJv9uDX8Ckd8Tlhmhu_FoadlPI6f1BXav-LyqD7c',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // рекомендовано
    ),
  );

  runApp(const MyApp());
}
