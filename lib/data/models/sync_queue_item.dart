import 'package:uuid/uuid.dart';

enum SyncAction {
  create,
  update,
  delete;

  static SyncAction fromString(String value) {
    switch (value.toLowerCase()) {
      case 'create':
        return SyncAction.create;
      case 'update':
        return SyncAction.update;
      case 'delete':
        return SyncAction.delete;
      default:
        return SyncAction.update;
    }
  }
}

class SyncQueueItem {
  final String id;
  final String entityType; // 'transaction' or 'family'
  final String entityId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int retryCount;
  final String accountId;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.queuedAt,
    this.retryCount = 0,
    required this.accountId,
  });

  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncAction? action,
    Map<String, dynamic>? payload,
    DateTime? queuedAt,
    int? retryCount,
    String? accountId,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      accountId: accountId ?? this.accountId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'action': action.name,
      'payload': payload,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'accountId': accountId,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedQueued;
    try {
      final raw = json['queuedAt'];
      parsedQueued = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      parsedQueued = DateTime.now();
    }

    Map<String, dynamic> payloadMap = {};
    if (json['payload'] is Map) {
      payloadMap = Map<String, dynamic>.from(json['payload'] as Map);
    }

    return SyncQueueItem(
      id: json['id']?.toString() ?? const Uuid().v4(),
      entityType: json['entityType']?.toString() ?? 'transaction',
      entityId: json['entityId']?.toString() ?? '',
      action: SyncAction.fromString(json['action']?.toString() ?? 'create'),
      payload: payloadMap,
      queuedAt: parsedQueued,
      retryCount: (json['retryCount'] is num) ? (json['retryCount'] as num).toInt() : 0,
      accountId: json['accountId']?.toString() ?? '',
    );
  }

  factory SyncQueueItem.forTransaction({
    String? id,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
    required String accountId,
    DateTime? queuedAt,
    int retryCount = 0,
  }) {
    return SyncQueueItem(
      id: id ?? const Uuid().v4(),
      entityType: 'transaction',
      entityId: entityId,
      action: action,
      payload: payload,
      queuedAt: queuedAt ?? DateTime.now(),
      retryCount: retryCount,
      accountId: accountId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
