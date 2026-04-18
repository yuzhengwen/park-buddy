import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/family_service.dart';

class ParkingService {
  final _supabase = Supabase.instance.client;
  final _familyService = FamilyService();
  Future<List<Map<String, dynamic>>> fetchCars() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
    return [];
  }
    final familyData = await _familyService.getUserFamily();
    List<String> ownerIds = [user.id];
    if (familyData != null && familyData['members'] != null) {
    // Add all family member IDs to our search list
    final memberIds = (familyData['members'] as List)
        .map((m) => m['userid'].toString())
        .toList();
    ownerIds.addAll(memberIds);
  }
    final response = await _supabase
        .from('cars')
        .select()
        .inFilter('ownerid', ownerIds.toSet().toList());
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchSessions(String carplate) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('carplate', carplate)
        .order('parkingstarttime', ascending: false)
        .limit(3);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchSessionById(String sessionId) async {
    final List<dynamic> response = await _supabase
        .from('parkingsession')
        .select()
        .eq('sessionid', sessionId);

    if (response.isEmpty) return null;

    return response.first as Map<String, dynamic>;
  }

  Future<bool> hasActiveSession(String carplate) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('carplate', carplate)
        .isFilter('parkingendtime', null)
        .limit(1);
    return (response as List).isNotEmpty;
  }
}
