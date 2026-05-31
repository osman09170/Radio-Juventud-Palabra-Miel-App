// lib/services/firestore_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _deviceIdKey = 'device_id';

  // ---------------------------------------------------------------------------
  // Device ID — generado una vez y guardado en SharedPreferences
  // ---------------------------------------------------------------------------

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = _newId();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  static String _newId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ---------------------------------------------------------------------------
  // Rachas — sincroniza la racha local con Firestore
  // Documento: rachas/{deviceId}
  // Campos: count (int), lastDate (String 'YYYY-MM-DD'), updatedAt (Timestamp)
  // ---------------------------------------------------------------------------

  static Future<void> syncStreak({
    required int count,
    required String lastDate,
  }) async {
    try {
      final deviceId = await getDeviceId();
      await _db.collection('rachas').doc(deviceId).set({
        'count': count,
        'lastDate': lastDate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Fallo silencioso — la racha local en SharedPreferences es la fuente de verdad
    }
  }

  // ---------------------------------------------------------------------------
  // Eventos — lee la colección 'eventos' ordenada por campo 'orden'
  // Colección: eventos/{docId}
  // Campos: titulo (String), imageUrl (String), recortar (bool),
  //         orden (int), activo (bool)
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchEvents() async {
    try {
      final snapshot = await _db
          .collection('eventos')
          .where('activo', isEqualTo: true)
          .orderBy('orden')
          .get()
          .timeout(const Duration(seconds: 8));

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'titulo':     (d['titulo']     as String?) ?? '',
          'assetImage': (d['assetImage'] as String?) ?? '',
          'recortar':   (d['recortar']   as bool?)   ?? false,
        };
      }).toList();
    } catch (_) {
      return []; // Firestore no disponible — la pantalla usa el fallback local
    }
  }
}
