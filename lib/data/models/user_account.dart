import 'package:uuid/uuid.dart';

enum AccountType {
  personal,
  group,
}

class UserAccount {
  final String id;
  final String? displayName;
  final String? email;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isActive;
  final AccountType type;
  final String? groupId;

  const UserAccount({
    required this.id,
    this.displayName,
    this.email,
    this.isAnonymous = true,
    required this.createdAt,
    required this.lastActiveAt,
    this.isActive = false,
    this.type = AccountType.personal,
    this.groupId,
  });

  bool get isGroup => type == AccountType.group;
  bool get isPersonal => type == AccountType.personal;

  String get nameOrDefault {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (isGroup) {
      return 'Group Ledger';
    }
    final prefix = id.length >= 4 ? id.substring(0, 4) : id;
    return 'Account $prefix';
  }

  UserAccount copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isActive,
    AccountType? type,
    String? groupId,
  }) {
    return UserAccount(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isActive': isActive,
      'type': type.name,
      'groupId': groupId,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreated;
    try {
      final raw = json['createdAt'];
      parsedCreated = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    DateTime parsedLastActive;
    try {
      final raw = json['lastActiveAt'];
      parsedLastActive = raw != null ? DateTime.parse(raw.toString()) : parsedCreated;
    } catch (_) {
      parsedLastActive = parsedCreated;
    }

    final rawType = json['type']?.toString();
    final parsedType = rawType == 'group' ? AccountType.group : AccountType.personal;

    return UserAccount(
      id: json['id']?.toString() ?? const Uuid().v4(),
      displayName: json['displayName']?.toString(),
      email: json['email']?.toString(),
      isAnonymous: json['isAnonymous'] == null ? true : (json['isAnonymous'] as bool),
      createdAt: parsedCreated,
      lastActiveAt: parsedLastActive,
      isActive: json['isActive'] == null ? false : (json['isActive'] as bool),
      type: parsedType,
      groupId: json['groupId']?.toString(),
    );
  }

  factory UserAccount.create({String? name}) {
    final now = DateTime.now();
    return UserAccount(
      id: const Uuid().v4(),
      displayName: name,
      isAnonymous: true,
      createdAt: now,
      lastActiveAt: now,
      isActive: true,
      type: AccountType.personal,
    );
  }

  factory UserAccount.createGroup({required String groupId, required String groupName}) {
    final now = DateTime.now();
    return UserAccount(
      id: 'grp_$groupId',
      displayName: groupName,
      isAnonymous: true,
      createdAt: now,
      lastActiveAt: now,
      isActive: true,
      type: AccountType.group,
      groupId: groupId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
