import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/purchase_history.dart';

/// Purchase history service — mirrors web app's purchase-history.ts
class PurchaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _guestKey = 'mindspend_purchase_history';

  // ─── Firestore (authenticated users) ───

  Future<String> savePurchase(String uid, PurchaseHistory purchase) async {
    final doc = _db.collection('users').doc(uid).collection('purchases').doc();
    await _setMapWithCleanup(doc, purchase.toMap());
    return doc.id;
  }

  Future<List<PurchaseHistory>> getPurchaseHistory(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => PurchaseHistory.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<void> updateDecision(
    String uid,
    String purchaseId,
    String decision,
  ) async {
    final doc = _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(purchaseId);

    final snapshot = await doc.get();
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null) return;

    final sanitized = PurchaseHistory.fromMap(data, id: snapshot.id).copyWith(
      decision: decision,
    );
    await _setMapWithCleanup(doc, sanitized.toMap());
  }

  Future<void> deletePurchase(String uid, String purchaseId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(purchaseId)
        .delete();
  }

  Future<void> _setMapWithCleanup(
    DocumentReference<Map<String, dynamic>> doc,
    Map<String, dynamic> next,
  ) async {
    final snapshot = await doc.get();
    final existing = snapshot.data() ?? <String, dynamic>{};

    await doc.set(next, SetOptions(merge: true));

    final fieldsToDelete = <String, dynamic>{};
    _collectMissingPaths(existing, next, fieldsToDelete);

    if (fieldsToDelete.isNotEmpty) {
      await doc.update(fieldsToDelete);
    }
  }

  void _collectMissingPaths(
    Map<String, dynamic> existing,
    Map<String, dynamic> next,
    Map<String, dynamic> output, {
    String prefix = '',
  }) {
    for (final entry in existing.entries) {
      final key = entry.key;
      final path = prefix.isEmpty ? key : '$prefix.$key';

      if (!next.containsKey(key)) {
        output[path] = FieldValue.delete();
        continue;
      }

      final currentValue = entry.value;
      final nextValue = next[key];
      if (currentValue is Map && nextValue is Map) {
        final currentMap = Map<String, dynamic>.from(currentValue);
        final nextMap = Map<String, dynamic>.from(nextValue);
        _collectMissingPaths(currentMap, nextMap, output, prefix: path);
      }
    }
  }

  // ─── Guest mode (SharedPreferences) ───

  Future<void> saveGuestPurchase(PurchaseHistory purchase) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGuestPurchaseHistory();

    final newPurchase = PurchaseHistory(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      price: purchase.price,
      label: purchase.label,
      category: purchase.category,
      decision: purchase.decision,
      timestamp: purchase.timestamp,
      timeOfDay: purchase.timeOfDay,
      calculations: purchase.calculations,
    );

    history.insert(0, newPurchase);
    await prefs.setString(
      _guestKey,
      jsonEncode(history.map((h) => {...h.toMap(), 'id': h.id}).toList()),
    );
  }

  Future<List<PurchaseHistory>> getGuestPurchaseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_guestKey);
    if (json == null) return [];

    final list = jsonDecode(json) as List;
    return list
        .map(
          (item) => PurchaseHistory.fromMap(
            item as Map<String, dynamic>,
            id: item['id'] as String?,
          ),
        )
        .toList();
  }

  Future<void> updateGuestDecision(String purchaseId, String decision) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGuestPurchaseHistory();
    final index = history.indexWhere((p) => p.id == purchaseId);
    if (index == -1) return;

    final updated = history[index].copyWith(decision: decision);
    history[index] = updated;
    await prefs.setString(
      _guestKey,
      jsonEncode(history.map((h) => {...h.toMap(), 'id': h.id}).toList()),
    );
  }

  Future<void> deleteGuestPurchase(String purchaseId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGuestPurchaseHistory();
    history.removeWhere((p) => p.id == purchaseId);
    await prefs.setString(
      _guestKey,
      jsonEncode(history.map((h) => {...h.toMap(), 'id': h.id}).toList()),
    );
  }
}
