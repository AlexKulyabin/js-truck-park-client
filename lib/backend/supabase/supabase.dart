import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/config/app_config.dart';

export 'database/database.dart';
export 'storage/storage.dart';

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;

  static Future initialize() {
    final config = AppConfig.current;
    return Supabase.initialize(
      url: config.supabaseUrl,
      headers: {
        'X-Client-Info': 'flutterflow',
      },
      anonKey: config.supabasePublishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }
}
