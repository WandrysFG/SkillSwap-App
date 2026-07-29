import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AppUser> fetchProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromMap(data);
  }

  Future<void> updateProfile({
    required String userId,
    required String nombre,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'nombre': nombre,
      'bio': bio,
    };

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    await _client.from('users').update(updates).eq('id', userId);
  }
}