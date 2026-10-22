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

  Future<List<GroupModel>> fetchRemoteGroups() async {
    return await _remote.fetchUserGroups();
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
