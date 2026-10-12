import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connects the app to Supabase using the keys in the `.env` file.
/// Safe to call without keys: the app keeps working locally and
/// [isConnected] stays false.
class SupabaseService {
  static bool isConnected = false;

  /// The Supabase client. Only use it when [isConnected] is true.
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      final url = dotenv.maybeGet('SUPABASE_URL');
      final apiKey = dotenv.maybeGet('SUPABASE_KEY');

      if (url == null || url.isEmpty || apiKey == null || apiKey.isEmpty || apiKey.startsWith('PASTE_')) {
        debugPrint('Supabase: keys not set in .env, running without a connection.');
        return;
      }

      await Supabase.initialize(url: url, publishableKey: apiKey);
      isConnected = true;
      debugPrint('Supabase: connected to $url');
    } catch (e) {
      debugPrint('Supabase: could not connect ($e)');
    }
  }
}
