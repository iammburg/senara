class ScanLogEntry {
  final String character;
  final DateTime timestamp;
  final double confidence;

  ScanLogEntry({
    required this.character,
    required this.timestamp,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'character': character,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory ScanLogEntry.fromMap(Map<String, dynamic> map) {
    return ScanLogEntry(
      character: map['character'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }
}

class ScanSession {
  final String id;
  final String userId;
  final List<ScanLogEntry> logEntries;
  final DateTime createdAt;
  final String sessionText;

  ScanSession({
    required this.id,
    required this.userId,
    required this.logEntries,
    required this.createdAt,
    required this.sessionText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'logEntries': logEntries.map((entry) => entry.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'sessionText': sessionText,
    };
  }

  factory ScanSession.fromMap(Map<String, dynamic> map, String documentId) {
    return ScanSession(
      id: documentId,
      userId: map['userId'] ?? '',
      logEntries: (map['logEntries'] as List<dynamic>? ?? [])
          .map((entry) => ScanLogEntry.fromMap(entry as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      sessionText: map['sessionText'] ?? '',
    );
  }
}
