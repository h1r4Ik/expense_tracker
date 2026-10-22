class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final Map<String, String> memberRoles; // userId -> 'admin' | 'member'
  final Map<String, String> memberNames; // userId -> displayName
  final String? currency;
  final String invitationCode;
  final bool isActive;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.memberRoles,
    this.memberNames = const {},
    this.currency,
    required this.invitationCode,
    this.isActive = true,
  });

  bool isMember(String userId) => members.contains(userId);
  bool isAdmin(String userId) => memberRoles[userId] == 'admin';
  String getMemberName(String userId) => memberNames[userId] ?? 'Member';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'members': members,
      'memberRoles': memberRoles,
      'memberNames': memberNames,
      'currency': currency,
      'invitationCode': invitationCode,
      'isActive': isActive,
    };
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      final raw = json['createdAt'];
      parsedCreatedAt = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    final rawMembers = json['members'];
    final membersList = rawMembers is List
        ? rawMembers.map((e) => e.toString()).toList()
        : <String>[];

    final rawRoles = json['memberRoles'];
    final rolesMap = <String, String>{};
    if (rawRoles is Map) {
      rawRoles.forEach((key, value) {
        rolesMap[key.toString()] = value.toString();
      });
    }

    final rawNames = json['memberNames'];
    final namesMap = <String, String>{};
    if (rawNames is Map) {
      rawNames.forEach((key, value) {
        namesMap[key.toString()] = value.toString();
      });
    }

    return GroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Group',
      description: json['description']?.toString(),
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      members: membersList,
      memberRoles: rolesMap,
      memberNames: namesMap,
      currency: json['currency']?.toString(),
      invitationCode: json['invitationCode']?.toString() ?? '',
      isActive: json['isActive'] == null ? true : (json['isActive'] as bool),
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? members,
    Map<String, String>? memberRoles,
    Map<String, String>? memberNames,
    String? currency,
    String? invitationCode,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      memberRoles: memberRoles ?? this.memberRoles,
      memberNames: memberNames ?? this.memberNames,
      currency: currency ?? this.currency,
      invitationCode: invitationCode ?? this.invitationCode,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Backward compatibility alias
typedef FamilyModel = GroupModel;
