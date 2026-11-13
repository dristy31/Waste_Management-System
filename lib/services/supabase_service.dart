import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://zbcfwvpfffmxcdglmmjw.supabase.co',
      publishableKey: 'sb_publishable_kQylK4SE_7qoR2Cdc91R8A_4z8R-x3C',
    );
  }
}
