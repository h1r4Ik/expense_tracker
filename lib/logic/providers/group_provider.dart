// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

import '../../data/services/group_notification_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupRepository _repo;
  final GroupNotificationService? _notificationService;

  List<GroupModel> _groups = [];
  String? _activeGroupId;
  bool _isLoading = false;
  String? _error;

  GroupProvider({
    required GroupRepository repo,
    GroupNotificationService? notificationService,
  })  : _repo = repo,
        _notificationService = notificationService;

  List<GroupModel> get groups => List.unmodifiable(_groups);
  String? get activeGroupId => _activeGroupId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  GroupNotificationService? get notificationService => _notificationService;

  // Backward-compatible family aliases
  List<GroupModel> get families => groups;
  String? get activeFamilyId => _activeGroupId;
  GroupModel? get activeFamily => activeGroup;

  GroupModel? get activeGroup {
    if (_activeGroupId == null) return null;
    try {
      return _groups.firstWhere((g) => g.id == _activeGroupId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadGroups(String accountId, {String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _repo.getCachedGroups(accountId);
      _activeGroupId = await _repo.getActiveGroupId(accountId);

      // Try fetching remote groups in background using user ID
      try {
        final remoteGroups = await _repo.fetchRemoteGroups(userId ?? accountId);
        if (remoteGroups.isNotEmpty) {
          // Merge remote into local
          for (final remote in remoteGroups) {
            final idx = _groups.indexWhere((g) => g.id == remote.id);
            if (idx >= 0) {
              _groups[idx] = remote;
            } else {
              _groups.add(remote);
            }
          }
          await _repo.saveGroups(accountId, _groups);
        }
      } catch (_) {
        // Offline — use cached data
      }

      // Sync active group watchers in notification service
      if (_notificationService != null && _groups.isNotEmpty) {
        _notificationService.watchGroups(_groups, currentUserId: userId ?? accountId);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('GroupProvider.loadGroups error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    String? accountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.leaveGroup(
        groupId: groupId,
        userId: userId,
        accountId: accountId,
      );
      _groups.removeWhere((g) => g.id == groupId);
      _notificationService?.stopWatching(groupId);
      if (_activeGroupId == groupId) {
        _activeGroupId = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> kickMember({
    required String groupId,
    required String memberId,
    String? accountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.kickMember(
        groupId: groupId,
        memberId: memberId,
        accountId: accountId,
      );
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        final group = _groups[idx];
        final updatedMembers = List<String>.from(group.members)..remove(memberId);
        final updatedRoles = Map<String, String>.from(group.memberRoles)..remove(memberId);
        final updatedNames = Map<String, String>.from(group.memberNames)..remove(memberId);
        _groups[idx] = group.copyWith(
          members: updatedMembers,
          memberRoles: updatedRoles,
          memberNames: updatedNames,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
    String? accountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.updateMemberRole(
        groupId: groupId,
        memberId: memberId,
        newRole: newRole,
        accountId: accountId,
      );
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        final group = _groups[idx];
        final updatedRoles = Map<String, String>.from(group.memberRoles);
        updatedRoles[memberId] = newRole;
        _groups[idx] = group.copyWith(memberRoles: updatedRoles);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Backward compatibility alias
  Future<void> loadFamilies(String accountId, {String? userId}) =>
      loadGroups(accountId, userId: userId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<GroupModel> createGroup(
    String name, {
    String? description,
    String? creatorId,
    String? creatorName,
    String? accountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _repo.createGroup(
        name,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        accountId: accountId,
      );
      final idx = _groups.indexWhere((g) => g.id == group.id);
      if (idx >= 0) {
        _groups[idx] = group;
      } else {
        _groups.add(group);
      }
      _activeGroupId = group.id;
      _notificationService?.watchGroup(group, currentUserId: creatorId ?? accountId);
      notifyListeners();
      return group;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Backward compatibility alias
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

  Future<GroupModel> joinByCode(
    String code, {
    String? userId,
    String? userName,
    String? accountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _repo.joinByCode(
        code,
        userId: userId,
        userName: userName,
        accountId: accountId,
      );
      final idx = _groups.indexWhere((g) => g.id == group.id);
      if (idx >= 0) {
        _groups[idx] = group;
      } else {
        _groups.add(group);
      }
      _activeGroupId = group.id;
      _notificationService?.watchGroup(group, currentUserId: userId ?? accountId);
      notifyListeners();
      return group;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveGroup(String accountId, String? groupId) async {
    _activeGroupId = groupId;
    await _repo.setActiveGroupId(accountId, groupId);
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> setActiveFamily(String accountId, String? familyId) =>
      setActiveGroup(accountId, familyId);

  Future<void> saveGroups(String accountId) async {
    await _repo.saveGroups(accountId, _groups);
  }

  // Backward compatibility alias
  Future<void> saveFamilies(String accountId) => saveGroups(accountId);
}

typedef FamilyProvider = GroupProvider;
