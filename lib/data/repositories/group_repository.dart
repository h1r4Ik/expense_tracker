// ignore_for_file: prefer_initializing_formals

import '../models/group_model.dart';
import '../services/firebase_sync_service.dart';
import '../services/local_storage_service.dart';

/// Repository managing shared group ledger operations.
class GroupRepository {
  final LocalStorageService _local;
  final FirebaseSyncService _remote;

  GroupRepository({
    required LocalStorageService local,
    required FirebaseSyncService remote,
  })  : _local = local,
        _remote = remote;

  Future<List<GroupModel>> getCachedGroups(String accountId) async {
    return await _local.getCachedGroups(accountId);
  }

  Future<void> saveGroups(String accountId, List<GroupModel> groups) async {
    await _local.saveGroups(accountId, groups);
  }

  Future<GroupModel> createGroup(
    String name, {
    String? description,
    String? creatorId,
    String? creatorName,
    String? accountId,
  }) async {
    final group = await _remote.createGroup(
      name: name,
      description: description,
      creatorId: creatorId,
      creatorName: creatorName,
    );
    if (accountId != null && accountId.isNotEmpty) {
      final cached = await _local.getCachedGroups(accountId);
      final idx = cached.indexWhere((g) => g.id == group.id);
      if (idx >= 0) {
        cached[idx] = group;
      } else {
        cached.add(group);
      }
      await _local.saveGroups(accountId, cached);
      await _local.setActiveGroupId(accountId, group.id);
    }
    return group;
  }

  Future<GroupModel> joinByCode(
    String code, {
    String? userId,
    String? userName,
    String? accountId,
  }) async {
    final group = await _remote.joinGroupByCode(
      code,
      userId: userId,
      userName: userName,
    );
    if (accountId != null && accountId.isNotEmpty) {
      final cached = await _local.getCachedGroups(accountId);
      final idx = cached.indexWhere((g) => g.id == group.id);
      if (idx >= 0) {
        cached[idx] = group;
      } else {
        cached.add(group);
      }
      await _local.saveGroups(accountId, cached);
      await _local.setActiveGroupId(accountId, group.id);
    }
    return group;
  }

  Future<List<GroupModel>> fetchRemoteGroups([String? userId]) async {
    return await _remote.fetchUserGroups(userId);
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    String? accountId,
  }) async {
    await _remote.leaveGroup(groupId: groupId, userId: userId);
    if (accountId != null && accountId.isNotEmpty) {
      final cached = await _local.getCachedGroups(accountId);
      cached.removeWhere((g) => g.id == groupId);
      await _local.saveGroups(accountId, cached);
      final activeGroupId = await _local.getActiveGroupId(accountId);
      if (activeGroupId == groupId) {
        await _local.setActiveGroupId(accountId, null);
      }
    }
  }
  Future<void> kickMember({
    required String groupId,
    required String memberId,
    String? accountId,
  }) async {
    await _remote.kickMember(groupId: groupId, memberId: memberId);
    if (accountId != null && accountId.isNotEmpty) {
      final cached = await _local.getCachedGroups(accountId);
      final idx = cached.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        final group = cached[idx];
        final updatedMembers = List<String>.from(group.members)..remove(memberId);
        final updatedRoles = Map<String, String>.from(group.memberRoles)..remove(memberId);
        final updatedNames = Map<String, String>.from(group.memberNames)..remove(memberId);
        cached[idx] = group.copyWith(
          members: updatedMembers,
          memberRoles: updatedRoles,
          memberNames: updatedNames,
        );
        await _local.saveGroups(accountId, cached);
      }
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
    String? accountId,
  }) async {
    await _remote.updateMemberRole(
      groupId: groupId,
      memberId: memberId,
      newRole: newRole,
    );
    if (accountId != null && accountId.isNotEmpty) {
      final cached = await _local.getCachedGroups(accountId);
      final idx = cached.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        final group = cached[idx];
        final updatedRoles = Map<String, String>.from(group.memberRoles);
        updatedRoles[memberId] = newRole;
        cached[idx] = group.copyWith(memberRoles: updatedRoles);
        await _local.saveGroups(accountId, cached);
      }
    }
  }

  Future<void> syncGroupToRemote(GroupModel group) async {
    await _remote.saveGroupRemote(group);
  }

  Future<String?> getActiveGroupId(String accountId) async {
    return await _local.getActiveGroupId(accountId);
  }

  Future<void> setActiveGroupId(String accountId, String? id) async {
    await _local.setActiveGroupId(accountId, id);
  }

  // Backward compatibility aliases
  Future<List<GroupModel>> getCachedFamilies(String accountId) => getCachedGroups(accountId);
  Future<void> saveFamilies(String accountId, List<GroupModel> families) => saveGroups(accountId, families);
  Future<GroupModel> createFamily(
    String name, {
    String? description,
    String? creatorId,
    String? creatorName,
    String? accountId,
  }) =>
      createGroup(
        name,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        accountId: accountId,
      );
  Future<List<GroupModel>> fetchRemoteFamilies() => fetchRemoteGroups();
  Future<void> syncFamilyToRemote(GroupModel family) => syncGroupToRemote(family);
  Future<String?> getActiveFamilyId(String accountId) => getActiveGroupId(accountId);
  Future<void> setActiveFamilyId(String accountId, String? id) => setActiveGroupId(accountId, id);
}

typedef FamilyRepository = GroupRepository;
