import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// RequestStorageService
/// ─────────────────────
/// Stores blood/adoption requests in SharedPreferences using GLOBAL keys.
/// This means data persists across user logouts and is accessible when
/// the NGO logs in on the same device.
///
/// Data is filtered by ngo_id or user_id at READ time.
class RequestStorageService {
  // ✅ GLOBAL keys — NOT cleared on logout
  static const String _bloodKey = 'kp_global_blood_requests';
  static const String _adoptionKey = 'kp_global_adoption_requests';

  // =====================================================
  // 🩸 SAVE BLOOD REQUEST
  // =====================================================
  static Future<void> saveBloodRequest(Map<String, dynamic> request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_bloodKey) ?? [];

      // Generate unique ID if missing
      final String id = request['id']?.toString().isNotEmpty == true
          ? request['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      request['id'] = id;
      request['status'] ??= 'pending';
      request['created_at'] ??= DateTime.now().toIso8601String();
      request['type'] = 'blood';

      // Update existing or add new
      final List<String> updated = [];
      bool found = false;
      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));
          if (map['id'].toString() == id) {
            updated.add(jsonEncode(request));
            found = true;
          } else {
            updated.add(item);
          }
        } catch (_) {
          updated.add(item);
        }
      }
      if (!found) updated.add(jsonEncode(request));

      await prefs.setStringList(_bloodKey, updated);
    } catch (e) {
      // ignore silently
    }
  }

  // =====================================================
  // 👶 SAVE ADOPTION REQUEST
  // =====================================================
  static Future<void> saveAdoptionRequest(Map<String, dynamic> request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_adoptionKey) ?? [];

      final String id = request['id']?.toString().isNotEmpty == true
          ? request['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      request['id'] = id;
      request['status'] ??= 'pending';
      request['created_at'] ??= DateTime.now().toIso8601String();
      request['type'] = 'adoption';

      final List<String> updated = [];
      bool found = false;
      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));
          if (map['id'].toString() == id) {
            updated.add(jsonEncode(request));
            found = true;
          } else {
            updated.add(item);
          }
        } catch (_) {
          updated.add(item);
        }
      }
      if (!found) updated.add(jsonEncode(request));

      await prefs.setStringList(_adoptionKey, updated);
    } catch (e) {
      // ignore silently
    }
  }

  // =====================================================
  // 📋 GET BLOOD REQUESTS
  // ngoId: pass NGO's userId to get requests for that NGO
  // userId: pass user's userId to get that user's own requests
  // Pass null for both to get ALL requests
  // =====================================================
  static Future<List<Map<String, dynamic>>> getBloodRequests({
    String? ngoId,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_bloodKey) ?? [];
      final List<Map<String, dynamic>> results = [];

      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));

          final bool matchNgo = ngoId == null ||
              ngoId.isEmpty ||
              ngoId == 'all' ||
              map['ngo_id']?.toString() == ngoId;

          final bool matchUser = userId == null ||
              userId.isEmpty ||
              userId == 'all' ||
              map['user_id']?.toString() == userId;

          if (matchNgo && matchUser) results.add(map);
        } catch (_) {}
      }

      // Newest first
      results.sort((a, b) =>
          (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      return results;
    } catch (e) {
      return [];
    }
  }

  // =====================================================
  // 📋 GET ADOPTION REQUESTS
  // =====================================================
  static Future<List<Map<String, dynamic>>> getAdoptionRequests({
    String? ngoId,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_adoptionKey) ?? [];
      final List<Map<String, dynamic>> results = [];

      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));

          final bool matchNgo = ngoId == null ||
              ngoId.isEmpty ||
              ngoId == 'all' ||
              map['ngo_id']?.toString() == ngoId;

          final bool matchUser = userId == null ||
              userId.isEmpty ||
              userId == 'all' ||
              map['user_id']?.toString() == userId;

          if (matchNgo && matchUser) results.add(map);
        } catch (_) {}
      }

      results.sort((a, b) =>
          (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      return results;
    } catch (e) {
      return [];
    }
  }

  // =====================================================
  // 🔄 UPDATE REQUEST STATUS (ACCEPT / REJECT)
  // =====================================================
  static Future<bool> updateRequestStatus({
    required String requestId,
    required String type, // 'blood' or 'adoption'
    required String newStatus, // 'accepted' or 'rejected'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = (type == 'blood') ? _bloodKey : _adoptionKey;
      final List<String> list = prefs.getStringList(key) ?? [];
      final List<String> updatedList = [];
      bool updated = false;

      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));
          final String itemId = (map['id'] ?? map['request_id'] ?? '').toString();
          if (itemId == requestId) {
            map['status'] = newStatus;
            updated = true;
          }
          updatedList.add(jsonEncode(map));
        } catch (_) {
          updatedList.add(item);
        }
      }

      if (updated) {
        await prefs.setStringList(key, updatedList);
      }
      return updated;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // 🗑️ CLEAR ALL REQUESTS (only call if you really need to reset)
  // =====================================================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bloodKey);
    await prefs.remove(_adoptionKey);
  }
}
