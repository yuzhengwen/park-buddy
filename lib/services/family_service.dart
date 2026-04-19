import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyService {
  //final supabase = Supabase.instance.client;
  final SupabaseClient supabase;

  FamilyService([SupabaseClient? client])
      : supabase = client ?? Supabase.instance.client;
      
  Future<void> updateFamilyName(String joinCode, String newName) async {
    await supabase
        .from('family')
        .update({'familyname': newName})
        .eq('familyjoincode', joinCode);
  }

  Future<void> kickMember(String joinCode, String userId) async {
    await supabase
        .from('familyuser')
        .delete()
        .eq('familyjoincode', joinCode)
        .eq('userid', userId);
  }

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
        .select('users(userid, username)')
        .eq('familyjoincode', code);

    final members = membersRes.map<Map<String, dynamic>>((m) {
      return {
        'userid': m['users']['userid'],
        'username': m['users']['username'],
      };
    }).toList();

    return {
      'familyName': family['familyname'],
      'joinCode': code,
      'members': members,
      'ownerId': family['ownerid'],
    };
  }

  // Create family (RPC)
  Future<String> createFamily(String familyName) async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase.rpc(
      'create_family',
      params: {'p_familyname': familyName, 'p_userid': userId},
    );

    return res[0]['familyjoincode'];
  }

  // Join family (RPC)
  Future<void> joinFamily(String code) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.rpc(
      'join_family',
      params: {'p_code': code, 'p_userid': userId},
    );
  }

  Future<void> leaveFamily(String joinCode) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('familyuser')
        .delete()
        .eq('familyjoincode', joinCode)
        .eq('userid', userId);
  }

  Future<void> deleteFamily(String joinCode) async {
    try {
      await supabase.rpc(
        'delete_family_cascade',
        params: {'target_family_code': joinCode},
      );
    } on PostgrestException catch (error) {
      // Pass the database error message up to the UI
      throw error.message;
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }
}
