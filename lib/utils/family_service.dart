import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getUserFamily() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('familyuser')
        .select('familyjoincode')
        .eq('userid', userId)
        .maybeSingle();

    if (res == null) return null;

    final code = res['familyjoincode'];

    final family = await supabase
        .from('family')
        .select()
        .eq('familyjoincode', code)
        .single();

    final membersRes = await supabase
        .from('familyuser')
        .select('users(username)')
        .eq('familyjoincode', code);

    final members = membersRes
        .map<String>((m) => m['users']['username'] as String)
        .toList();

    return {
      'familyName': family['familyname'],
      'joinCode': code,
      'members': members,
    };
  }

  // Create family (RPC)
  Future<String> createFamily(String familyName) async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase.rpc('create_family', params: {
      'p_familyname': familyName,
      'p_userid': userId,
    });

    return res[0]['familyjoincode'];
  }

  // Join family (RPC)
  Future<void> joinFamily(String code) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.rpc('join_family', params: {
      'p_code': code,
      'p_userid': userId,
    });
  }
}