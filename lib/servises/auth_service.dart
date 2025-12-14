import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'  hide Provider;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pedantic/pedantic.dart';
import 'package:paragalien/models/app_user.dart';
import 'package:paragalien/models/profile.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    return user != null ? AppUser.fromSupabaseUser(user) : null;
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: User not found');
      }

      await getOrCreateProfile(response.user!.id, email);

      // Associate with OneSignal alias (fire-and-forget)
     

      return AppUser.fromSupabaseUser(response.user!);
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<Profile> getOrCreateProfile(String userId, String email) async {
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return Profile.fromJson(existing);
    }

    final newProfile = {
      'id': userId,
      'email': email,
      'role': 'client',
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').insert(newProfile);
    return Profile.fromJson(newProfile);
  }

 

  Future<void> logout() async {
    try {
      // Remove external id (alias) from OneSignal
     

      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  Future<bool> userExists(String email) async {
    final result = await _supabase
        .from('profiles')
        .select()
        .eq('email', email.trim())
        .maybeSingle();
    return result != null;
  }
}
