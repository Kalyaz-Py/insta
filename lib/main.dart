import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://<PROJECT-REF>.supabase.co', // Settings → API → Project URL
    anonKey: '<ANON-PUBLIC-KEY>',            // Settings → API → anon public
  );
  runApp(const App());
}
