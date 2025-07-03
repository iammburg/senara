import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/scan_models.dart';

class FirestoreDebugScreen extends StatefulWidget {
  @override
  _FirestoreDebugScreenState createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _debugOutput = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore Debug'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _checkAuth,
              child: Text('Check Auth Status'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testFirestoreWrite,
              child: Text('Test Firestore Write'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testFirestoreRead,
              child: Text('Test Firestore Read'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _clearDebug, child: Text('Clear Debug')),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _debugOutput,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDebugOutput(String message) {
    setState(() {
      _debugOutput += '[${DateTime.now().toString()}] $message\n';
    });
  }

  void _checkAuth() {
    _addDebugOutput('=== AUTH CHECK ===');
    _addDebugOutput('User signed in: ${_authService.isSignedIn}');
    _addDebugOutput('User ID: ${_authService.userId}');
    _addDebugOutput('User email: ${_authService.userEmail}');
    _addDebugOutput('User display name: ${_authService.userDisplayName}');
    _addDebugOutput(
      'Firebase Auth current user: ${FirebaseAuth.instance.currentUser?.uid}',
    );
    _addDebugOutput('');
  }

  Future<void> _testFirestoreWrite() async {
    _addDebugOutput('=== FIRESTORE WRITE TEST ===');

    if (!_authService.isSignedIn) {
      _addDebugOutput('ERROR: User not signed in');
      return;
    }

    try {
      final testSession = ScanSession(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        userId: _authService.userId!,
        logEntries: [
          ScanLogEntry(
            character: 'A',
            timestamp: DateTime.now(),
            confidence: 0.95,
          ),
        ],
        createdAt: DateTime.now(),
        sessionText: 'TEST SESSION',
      );

      _addDebugOutput('Attempting to write session: ${testSession.id}');
      _addDebugOutput('Session data: ${testSession.toMap()}');

      await _firestore
          .collection('scan_sessions')
          .doc(testSession.id)
          .set(testSession.toMap());

      _addDebugOutput('SUCCESS: Session written to Firestore');
    } catch (e) {
      _addDebugOutput('ERROR: Failed to write to Firestore');
      _addDebugOutput('Error: $e');
      _addDebugOutput('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        _addDebugOutput('Firebase error code: ${e.code}');
        _addDebugOutput('Firebase error message: ${e.message}');
      }
    }
    _addDebugOutput('');
  }

  Future<void> _testFirestoreRead() async {
    _addDebugOutput('=== FIRESTORE READ TEST ===');

    if (!_authService.isSignedIn) {
      _addDebugOutput('ERROR: User not signed in');
      return;
    }

    try {
      _addDebugOutput(
        'Attempting to read sessions for user: ${_authService.userId}',
      );

      final querySnapshot = await _firestore
          .collection('scan_sessions')
          .where('userId', isEqualTo: _authService.userId)
          .limit(5)
          .get();

      _addDebugOutput('SUCCESS: Query completed');
      _addDebugOutput('Documents found: ${querySnapshot.docs.length}');

      for (final doc in querySnapshot.docs) {
        _addDebugOutput('Document ID: ${doc.id}');
        _addDebugOutput('Document data: ${doc.data()}');
      }
    } catch (e) {
      _addDebugOutput('ERROR: Failed to read from Firestore');
      _addDebugOutput('Error: $e');
      _addDebugOutput('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        _addDebugOutput('Firebase error code: ${e.code}');
        _addDebugOutput('Firebase error message: ${e.message}');
      }
    }
    _addDebugOutput('');
  }

  void _clearDebug() {
    setState(() {
      _debugOutput = '';
    });
  }
}
