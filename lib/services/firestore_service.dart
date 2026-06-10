import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/firebase_options.dart' show appId;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? _stateDoc() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(user.uid)
        .collection('appData')
        .doc('state');
  }

  Stream<Map<String, dynamic>?> watchStateFor(String uid) {
    return _db
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(uid)
        .collection('appData')
        .doc('state')
        .snapshots()
        .map((snap) => snap.data());
  }

  Future<void> saveField(String key, dynamic value) async {
    final ref = _stateDoc();
    if (ref == null) return;
    await ref.set({key: value}, SetOptions(merge: true));
  }

  Future<void> saveMany(Map<String, dynamic> entries) async {
    final ref = _stateDoc();
    if (ref == null) return;
    await ref.set(entries, SetOptions(merge: true));
  }
}
