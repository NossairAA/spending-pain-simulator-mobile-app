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
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .add(purchase.toMap());
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
    await _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(purchaseId)
        .update({'decision': decision});
  }

  Future<void> deletePurchase(String uid, String purchaseId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(purchaseId)
        .delete();
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
