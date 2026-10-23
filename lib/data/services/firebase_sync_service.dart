// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/transaction_model.dart';
import 'firebase_auth_service.dart';

/// Firebase Firestore sync service for personal accounts and shared group ledgers.
class FirebaseSyncService {
  String? _userId;
  String? _fallbackUserId;
  FirebaseAuthService? _authService;

  FirebaseSyncService({String? userId, FirebaseAuthService? authService})
      : _userId = userId,
        _authService = authService;

  void setUserId(String id) {
    _userId = id;
  }

  void setFallbackUserId(String id) {
    _fallbackUserId = id;
  }

  void setAuthService(FirebaseAuthService authService) {
    _authService = authService;
  }

  String? get currentUserId => _userId ?? _authService?.currentUserId ?? _fallbackUserId;

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance not ready: $e');
      return null;
    }
  }

  /// Ensures user ID is resolved from authenticated user or fallback
  Future<String?> ensureAuth() async {
    if (_userId != null && _userId!.isNotEmpty) return _userId;
    if (_authService != null && _authService!.isAvailable) {
      final uid = _authService!.currentUserId;
      if (uid != null && uid.isNotEmpty) {
        _userId = uid;
        return uid;
      }
    }
    return _userId ?? _fallbackUserId;
  }

  bool get hasCloud => _db != null;

  /// Syncs an individual transaction to Firebase if online.
  /// If personal: writes to users/{userId}/transactions/{txId}.
  /// If group: writes to groups/{groupId}/transactions/{txId}.
  Future<bool> syncTransaction(ExpenseTransaction tx) async {
    final db = _db;
    final uid = _userId ?? (await ensureAuth()) ?? _fallbackUserId;
    if (db == null || uid == null) return false;

    try {
      final docData = tx.toJson();
      docData['syncedAt'] = FieldValue.serverTimestamp();

      final targetGroupId = tx.groupId ?? tx.familyId;
      final isGroup = tx.isGroupTransaction || tx.isFamilyTransaction;

      if (isGroup && targetGroupId != null && targetGroupId.isNotEmpty) {
        await db
            .collection('groups')
            .doc(targetGroupId)
            .collection('transactions')
            .doc(tx.id)
            .set(docData, SetOptions(merge: true));

        // Legacy compatibility write
        try {
          await db
              .collection('families')
              .doc(targetGroupId)
              .collection('transactions')
              .doc(tx.id)
              .set(docData, SetOptions(merge: true));
        } catch (_) {}
      } else {
        await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(tx.id)
            .set(docData, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      debugPrint('FirebaseSyncService: sync error for transaction ${tx.id}: $e');
      return false;
    }
  }

  /// Alias for syncTransaction
  Future<bool> pushTransaction(ExpenseTransaction tx) => syncTransaction(tx);

  /// Deletes a transaction from Firebase if online
  Future<bool> deleteTransaction({
    required String txId,
    bool isGroup = false,
    bool isFamily = false,
    String? groupId,
    String? familyId,
  }) async {
    final db = _db;
    final uid = _userId ?? (await ensureAuth()) ?? _fallbackUserId;
    if (db == null || uid == null) return false;

    final targetGroupId = groupId ?? familyId;
    final isGroupTarget = isGroup || isFamily;

    try {
      if (isGroupTarget && targetGroupId != null && targetGroupId.isNotEmpty) {
        await db
            .collection('groups')
            .doc(targetGroupId)
            .collection('transactions')
            .doc(txId)
            .delete();

        // Legacy compatibility delete
        try {
          await db
              .collection('families')
              .doc(targetGroupId)
              .collection('transactions')
              .doc(txId)
              .delete();
        } catch (_) {}
      } else {
        await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(txId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('FirebaseSyncService: delete error for transaction $txId: $e');
      return false;
    }
  }

  Future<bool> deleteRemoteTransaction(
    String txId, {
    String? groupId,
    String? familyId,
  }) {
    final targetId = groupId ?? familyId;
    return deleteTransaction(
      txId: txId,
      isGroup: targetId != null,
      isFamily: targetId != null,
      groupId: targetId,
      familyId: targetId,
    );
  }

  /// Pulls remote transactions for personal account or group
  Future<List<ExpenseTransaction>> fetchRemoteTransactions({
    String? groupId,
    String? familyId,
  }) async {
    final db = _db;
    final uid = _userId ?? (await ensureAuth()) ?? _fallbackUserId;
    if (db == null || uid == null) return [];

    final targetGroupId = groupId ?? familyId;
    final List<ExpenseTransaction> results = [];

    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      if (targetGroupId != null && targetGroupId.isNotEmpty) {
        // First try groups collection
        snap = await db
            .collection('groups')
            .doc(targetGroupId)
            .collection('transactions')
            .orderBy('date', descending: true)
            .get();

        if (snap.docs.isEmpty) {
          // Fallback check legacy families collection
          snap = await db
              .collection('families')
              .doc(targetGroupId)
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();
        }
      } else {
        snap = await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .orderBy('date', descending: true)
            .get();
      }

      for (final doc in snap.docs) {
        try {
          results.add(ExpenseTransaction.fromJson(doc.data()));
        } catch (itemErr) {
          debugPrint('FirebaseSyncService: Skipped malformed transaction: $itemErr');
        }
      }
    } catch (e) {
      debugPrint('FirebaseSyncService.fetchRemoteTransactions error: $e');
    }
    return results;
  }

  /// Real-time stream of transactions for a group
  Stream<List<ExpenseTransaction>> streamGroupTransactions(String groupId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('groups')
        .doc(groupId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => ExpenseTransaction.fromJson(doc.data()))
          .toList();
    }).handleError((e) {
      debugPrint('FirebaseSyncService.streamGroupTransactions error: $e');
      return <ExpenseTransaction>[];
    });
  }

  /// Backward-compatible stream alias
  Stream<List<ExpenseTransaction>> streamFamilyTransactions(String familyId) =>
      streamGroupTransactions(familyId);

  /// Joins group by code using atomic transaction
  Future<GroupModel> joinGroupByCode(
    String code, {
    String? userId,
    String? userName,
  }) async {
    final uid = userId ?? _userId ?? (await ensureAuth()) ?? _fallbackUserId;
    if (uid == null) {
      throw Exception('Could not determine your user ID. Please try again.');
    }

    final db = _db;
    if (db == null) {
      throw Exception('Internet connection and cloud service required to join group by code.');
    }

    final cleanCode = code.trim().toUpperCase();

    // Query in groups collection
    var query = await db
        .collection('groups')
        .where('invitationCode', isEqualTo: cleanCode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    // Fallback to families collection if not found
    bool isLegacy = false;
    if (query.docs.isEmpty) {
      query = await db
          .collection('families')
          .where('invitationCode', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        isLegacy = true;
      }
    }

    if (query.docs.isEmpty) {
      throw Exception('Group with invitation code "$cleanCode" not found');
    }

    final docRef = query.docs.first.reference;

    return await db.runTransaction<GroupModel>((transaction) async {
      final fresh = await transaction.get(docRef);
      if (!fresh.exists) throw Exception('Group no longer exists');

      final group = GroupModel.fromJson(fresh.data()!);
      if (!group.members.contains(uid)) {
        final updatedMembers = List<String>.from(group.members)..add(uid);
        final updatedRoles = Map<String, String>.from(group.memberRoles)
          ..[uid] = 'member';
        final updatedNames = Map<String, String>.from(group.memberNames);
        if (userName != null && userName.isNotEmpty) {
          updatedNames[uid] = userName;
        }

        final updateData = {
          'members': updatedMembers,
          'memberRoles': updatedRoles,
          'memberNames': updatedNames,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.update(docRef, updateData);

        // Also duplicate to new collection if was legacy
        if (isLegacy) {
          db.collection('groups').doc(group.id).set({
            ...group.toJson(),
            ...updateData,
          }, SetOptions(merge: true));
        }

        return group.copyWith(
          members: updatedMembers,
          memberRoles: updatedRoles,
          memberNames: updatedNames,
        );
      }
      return group;
    });
  }

  /// Backward-compatible join alias
  Future<GroupModel> joinFamilyByCode(
    String code, {
    String? userId,
    String? userName,
  }) =>
      joinGroupByCode(code, userId: userId, userName: userName);

  /// Creates a new group in Firestore (or locally offline-first)
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? creatorId,
    String? creatorName,
  }) async {
    final uid = creatorId ??
        _userId ??
        (await ensureAuth()) ??
        _fallbackUserId ??
        const Uuid().v4();
    _userId ??= uid;

    final db = _db;
    final groupId = db != null ? db.collection('groups').doc().id : const Uuid().v4();
    final invitationCode = groupId.length >= 8
        ? groupId.substring(0, 8).toUpperCase()
        : const Uuid().v4().substring(0, 8).toUpperCase();

    final memberNames = <String, String>{};
    if (creatorName != null && creatorName.isNotEmpty) {
      memberNames[uid] = creatorName;
    }

    final group = GroupModel(
      id: groupId,
      name: name.trim(),
      description: description?.trim(),
      createdBy: uid,
      createdAt: DateTime.now(),
      members: [uid],
      memberRoles: {uid: 'admin'},
      memberNames: memberNames,
      invitationCode: invitationCode,
      isActive: true,
    );

    if (db != null) {
      try {
        await db.collection('groups').doc(groupId).set(group.toJson());
        // Also save to legacy collection for existing listeners
        await db.collection('families').doc(groupId).set(group.toJson());
      } catch (e) {
        debugPrint('Firestore group push postponed (offline): $e');
      }
    }
    return group;
  }

  /// Backward-compatible create alias
  Future<GroupModel> createFamily({
    required String name,
    String? description,
    String? creatorId,
    String? creatorName,
  }) =>
      createGroup(
        name: name,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
      );

  /// Pushes a group to Firestore if online
  Future<void> saveGroupRemote(GroupModel group) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('groups').doc(group.id).set(group.toJson(), SetOptions(merge: true));
      await db.collection('families').doc(group.id).set(group.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService.saveGroupRemote error: $e');
    }
  }

  /// Backward-compatible save alias
  Future<void> saveFamilyRemote(GroupModel family) => saveGroupRemote(family);

  /// Fetches groups that the specified user belongs to
  Future<List<GroupModel>> fetchUserGroups([String? targetUserId]) async {
    final db = _db;
    final uid = targetUserId ?? _userId ?? (await ensureAuth()) ?? _fallbackUserId;
    if (db == null || uid == null) return [];

    try {
      final snap = await db
          .collection('groups')
          .where('members', arrayContains: uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => GroupModel.fromJson(doc.data())).toList();
      }

      // Fallback check legacy families collection
      final legacySnap = await db
          .collection('families')
          .where('members', arrayContains: uid)
          .where('isActive', isEqualTo: true)
          .get();

      return legacySnap.docs.map((doc) => GroupModel.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirebaseSyncService.fetchUserGroups error: $e');
      return [];
    }
  }

  /// Removes a user from a group in Firestore
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final docRef = db.collection('groups').doc(groupId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final group = GroupModel.fromJson(docSnap.data()!);
        final updatedMembers = List<String>.from(group.members)..remove(userId);
        final updatedRoles = Map<String, String>.from(group.memberRoles)..remove(userId);
        final updatedNames = Map<String, String>.from(group.memberNames)..remove(userId);

        await docRef.update({
          'members': updatedMembers,
          'memberRoles': updatedRoles,
          'memberNames': updatedNames,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Also clean legacy collection if present
      final legacyRef = db.collection('families').doc(groupId);
      final legacySnap = await legacyRef.get();
      if (legacySnap.exists) {
        final group = GroupModel.fromJson(legacySnap.data()!);
        final updatedMembers = List<String>.from(group.members)..remove(userId);
        final updatedRoles = Map<String, String>.from(group.memberRoles)..remove(userId);
        final updatedNames = Map<String, String>.from(group.memberNames)..remove(userId);

        await legacyRef.update({
          'members': updatedMembers,
          'memberRoles': updatedRoles,
          'memberNames': updatedNames,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FirebaseSyncService.leaveGroup error: $e');
    }
  }

  /// Updates a member's role in a group in Firestore
  Future<void> updateMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final docRef = db.collection('groups').doc(groupId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final group = GroupModel.fromJson(docSnap.data()!);
        final updatedRoles = Map<String, String>.from(group.memberRoles);
        updatedRoles[memberId] = newRole;

        await docRef.update({
          'memberRoles': updatedRoles,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Also update legacy collection if present
      final legacyRef = db.collection('families').doc(groupId);
      final legacySnap = await legacyRef.get();
      if (legacySnap.exists) {
        final group = GroupModel.fromJson(legacySnap.data()!);
        final updatedRoles = Map<String, String>.from(group.memberRoles);
        updatedRoles[memberId] = newRole;

        await legacyRef.update({
          'memberRoles': updatedRoles,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FirebaseSyncService.updateMemberRole error: $e');
      rethrow;
    }
  }

  /// Kicks / removes a member from a group (alias to leaveGroup logic)
  Future<void> kickMember({
    required String groupId,
    required String memberId,
  }) =>
      leaveGroup(groupId: groupId, userId: memberId);

  /// Backward-compatible fetch alias
  Future<List<GroupModel>> fetchUserFamilies([String? userId]) => fetchUserGroups(userId);
}
