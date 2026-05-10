class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL.
  /// Set via: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anonymous key.
  /// Set via: flutter run --dart-define=SUPABASE_ANON_KEY=eyJ...
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Storage buckets
  static const String evidenceBucket = 'evidence';
  static const String profileBucket = 'profiles';
  static const String clueBucket = 'clues';
}
