// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/group_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../ui/widgets/common/top_notification.dart';
import 'system_notification_service.dart';

/// Event model representing a group ledger notification
class GroupLedgerNotificationEvent {
  final String groupId;
  final String groupName;
  final ExpenseTransaction transaction;
  final String actorName;
  final bool isEdit;
  final DateTime timestamp;

  const GroupLedgerNotificationEvent({
    required this.groupId,
    required this.groupName,
    required this.transaction,
    required this.actorName,
    this.isEdit = false,
    required this.timestamp,
  });
}

/// Service that monitors active/joined group ledgers in real-time and surfaces
/// top-of-screen notifications when peer members add or modify transactions.
class GroupNotificationService {
  final TransactionRepository _txnRepo;
  final GroupRepository _groupRepo;

  final Map<String, StreamSubscription<List<ExpenseTransaction>>> _subscriptions = {};
  final Map<String, Set<String>> _knownTransactionIds = {};
  final Map<String, Map<String, DateTime>> _knownTransactionModTimes = {};
  final Map<String, GroupModel> _cachedGroups = {};
  final Set<String> _initializedGroups = {};

  String? _currentUserId;
  GlobalKey<NavigatorState>? _navigatorKey;

  final _eventController = StreamController<GroupLedgerNotificationEvent>.broadcast();
  Stream<GroupLedgerNotificationEvent> get onNotification => _eventController.stream;

  GroupRepository get groupRepository => _groupRepo;

  GroupNotificationService({
    required TransactionRepository txnRepo,
    required GroupRepository groupRepo,
  })  : _txnRepo = txnRepo,
        _groupRepo = groupRepo;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  /// Start monitoring a list of groups or an individual group.
  /// Ignores initial batch so notifications are only triggered on NEW or UPDATED items by others.
  void watchGroups(List<GroupModel> groups, {String? currentUserId}) {
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    final activeIds = <String>{};
    for (final group in groups) {
      activeIds.add(group.id);
      _cachedGroups[group.id] = group;
      _watchGroup(group.id);
    }

    // Cancel subscriptions for groups that the user left
    final toRemove = _subscriptions.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in toRemove) {
      _subscriptions[id]?.cancel();
      _subscriptions.remove(id);
      _knownTransactionIds.remove(id);
      _knownTransactionModTimes.remove(id);
      _initializedGroups.remove(id);
    }
  }

  void watchGroup(GroupModel group, {String? currentUserId}) {
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }
    _cachedGroups[group.id] = group;
    _watchGroup(group.id);
  }

  void _watchGroup(String groupId) {
    if (_subscriptions.containsKey(groupId)) return;

    _knownTransactionIds[groupId] ??= {};
    _knownTransactionModTimes[groupId] ??= {};

    final sub = _txnRepo.streamGroup(groupId).listen(
      (txList) {
        _handleGroupTransactionsUpdate(groupId, txList);
      },
      onError: (err) {
        debugPrint('GroupNotificationService error for group $groupId: $err');
      },
    );

    _subscriptions[groupId] = sub;
  }

  void _handleGroupTransactionsUpdate(String groupId, List<ExpenseTransaction> txList) {
    final isFirstSnapshot = !_initializedGroups.contains(groupId);
    final knownIds = _knownTransactionIds[groupId] ??= {};
    final knownMods = _knownTransactionModTimes[groupId] ??= {};
    final group = _cachedGroups[groupId];
    final groupName = group?.name ?? 'Group Ledger';

    if (isFirstSnapshot) {
      // Prime existing transaction cache without firing notification storm
      for (final tx in txList) {
        knownIds.add(tx.id);
        if (tx.lastModified != null) {
          knownMods[tx.id] = tx.lastModified!;
        }
      }
      _initializedGroups.add(groupId);
      return;
    }

    // Inspect incoming transactions
    for (final tx in txList) {
      final isNew = !knownIds.contains(tx.id);
      final lastMod = tx.lastModified;
      final prevMod = knownMods[tx.id];
      final isUpdated = !isNew &&
          lastMod != null &&
          (prevMod == null || lastMod.isAfter(prevMod));

      // Update tracked state
      knownIds.add(tx.id);
      if (lastMod != null) {
        knownMods[tx.id] = lastMod;
      }

      // Skip notifications for transactions authored/modified by the current user
      final authorId = tx.paidByUserId;
      if (_currentUserId != null &&
          authorId != null &&
          authorId.isNotEmpty &&
          authorId == _currentUserId) {
        continue;
      }

      if (isNew || isUpdated) {
        final actorName = (tx.paidByName != null && tx.paidByName!.isNotEmpty)
            ? tx.paidByName!
            : (group != null && authorId != null ? group.getMemberName(authorId) : 'A member');

        final event = GroupLedgerNotificationEvent(
          groupId: groupId,
          groupName: groupName,
          transaction: tx,
          actorName: actorName,
          isEdit: isUpdated,
          timestamp: DateTime.now(),
        );

        _eventController.add(event);
        _surfaceNotification(event);
      }
    }
  }

  void _surfaceNotification(GroupLedgerNotificationEvent event) {
    final formattedAmount = CurrencyFormatter.format(event.transaction.amount);
    final actionWord = event.isEdit ? 'updated' : 'added';
    final message = '${event.actorName} $actionWord "${event.transaction.title}" ($formattedAmount)';

    // Trigger system native notification in status bar tray
    SystemNotificationService.show(
      title: event.groupName,
      message: message,
    );

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    TopNotificationService.show(
      context: context,
      title: event.groupName,
      message: message,
      type: event.transaction.type == TransactionType.income
          ? TopNotificationType.success
          : TopNotificationType.info,
      icon: LucideIcons.receipt,
      duration: const Duration(seconds: 4),
    );
  }

  /// Manually trigger a notification (useful for testing or local user actions)
  void notifyGroupActivity({
    BuildContext? context,
    required String groupName,
    required String message,
    String? authorName,
    TopNotificationType type = TopNotificationType.info,
    IconData? icon,
    VoidCallback? onTap,
    bool showSystemNotification = true,
  }) {
    final fullMessage = authorName != null && authorName.isNotEmpty ? '$authorName: $message' : message;

    if (showSystemNotification) {
      SystemNotificationService.show(
        title: groupName,
        message: fullMessage,
      );
    }

    final targetContext = context ?? _navigatorKey?.currentContext;
    TopNotificationService.show(
      context: targetContext,
      title: groupName,
      message: fullMessage,
      type: type,
      icon: icon ?? LucideIcons.users,
      onTap: onTap,
    );
  }

  void stopWatching(String groupId) {
    _subscriptions[groupId]?.cancel();
    _subscriptions.remove(groupId);
    _knownTransactionIds.remove(groupId);
    _knownTransactionModTimes.remove(groupId);
    _initializedGroups.remove(groupId);
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _knownTransactionIds.clear();
    _knownTransactionModTimes.clear();
    _initializedGroups.clear();
    _eventController.close();
  }
}
