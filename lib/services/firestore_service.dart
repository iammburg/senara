import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scan_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionsCollection = 'scan_sessions';

  // Save scan session to Firestore
  Future<void> saveScanSession(ScanSession session) async {
    try {
      print(
        'Attempting to save session: ${session.id} for user: ${session.userId}',
      );
      print('Session data: ${session.toMap()}');

      await _firestore
          .collection(_sessionsCollection)
          .doc(session.id)
          .set(session.toMap());

      print('Successfully saved session: ${session.id}');
    } catch (e) {
      print('Error saving scan session: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      throw e;
    }
  }

  // Get scan sessions for a specific user
  Future<List<ScanSession>> getUserScanSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScanSession.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user scan sessions: $e');
      throw e;
    }
  }

  // Get scan sessions stream for real-time updates
  Stream<List<ScanSession>> getUserScanSessionsStream(String userId) {
    return _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScanSession.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Delete a scan session
  Future<void> deleteScanSession(String sessionId) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).delete();
    } catch (e) {
      print('Error deleting scan session: $e');
      throw e;
    }
  }

  // Delete all scan sessions for a user
  Future<void> deleteAllUserScanSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all user scan sessions: $e');
      throw e;
    }
  }
}
