import 'package:uuid/uuid.dart';

enum TransactionType {
  expense,
  income;

  String get displayName => this == TransactionType.income ? 'Income' : 'Expense';

  static TransactionType fromString(String? value) {
    if (value == null) return TransactionType.expense;
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

enum SyncStatus {
  synced,
  pendingSync,
  pendingDelete;

  static SyncStatus fromString(String? value) {
    if (value == null) return SyncStatus.synced;
    switch (value.toLowerCase()) {
      case 'pendingsync':
        return SyncStatus.pendingSync;
      case 'pendingdelete':
        return SyncStatus.pendingDelete;
      case 'synced':
      default:
        return SyncStatus.synced;
    }
  }
}

enum PaymentMethod {
  cash,
  upi,
  card,
  bankTransfer;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'card':
        return PaymentMethod.card;
      case 'banktransfer':
      case 'bank_transfer':
      case 'transfer':
        return PaymentMethod.bankTransfer;
      default:
        return null;
    }
  }
}

class ExpenseTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String? note;
  final String? description;
  final PaymentMethod? paymentMethod;
  final String? accountId;
  final DateTime createdAt;

  // Group and Multi-user fields
  final bool isGroupTransaction;
  final String? groupId;
  final String? paidByUserId;
  final String? paidByName;
  final String? splitType; // 'equal', 'custom', 'none'
  final Map<String, double>? splitAmounts;

  // Backward compatibility getters
  bool get isFamilyTransaction => isGroupTransaction;
  String? get familyId => groupId;

  // Offline-first sync tracking
  final SyncStatus syncStatus;
  final DateTime? lastModified;

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note,
    this.description,
    this.paymentMethod,
    this.accountId,
    DateTime? createdAt,
    bool? isGroupTransaction,
    bool isFamilyTransaction = false,
    String? groupId,
    String? familyId,
    this.paidByUserId,
    this.paidByName,
    this.splitType,
    this.splitAmounts,
    this.syncStatus = SyncStatus.synced,
    this.lastModified,
  })  : isGroupTransaction = isGroupTransaction ?? isFamilyTransaction,
        groupId = groupId ?? familyId,
        createdAt = createdAt ?? date;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  ExpenseTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    TransactionType? type,
    String? note,
    String? description,
    PaymentMethod? paymentMethod,
    String? accountId,
    DateTime? createdAt,
    bool? isGroupTransaction,
    bool? isFamilyTransaction,
    String? groupId,
    String? familyId,
    String? paidByUserId,
    String? paidByName,
    String? splitType,
    Map<String, double>? splitAmounts,
    SyncStatus? syncStatus,
    DateTime? lastModified,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      isGroupTransaction: isGroupTransaction ?? isFamilyTransaction ?? this.isGroupTransaction,
      groupId: groupId ?? familyId ?? this.groupId,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByName: paidByName ?? this.paidByName,
      splitType: splitType ?? this.splitType,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type.name,
      'note': note,
      'description': description,
      'paymentMethod': paymentMethod?.name,
      'accountId': accountId,
      'createdAt': createdAt.toIso8601String(),
      'isGroupTransaction': isGroupTransaction,
      'groupId': groupId,
      // Backward compatibility keys
      'isFamilyTransaction': isGroupTransaction,
      'familyId': groupId,
      'paidByUserId': paidByUserId,
      'paidByName': paidByName,
      'splitType': splitType,
      'splitAmounts': splitAmounts,
      'syncStatus': syncStatus.name,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) {
    double parsedAmount = 0.0;
    if (json['amount'] is num) {
      parsedAmount = (json['amount'] as num).toDouble();
    } else if (json['amount'] is String) {
      parsedAmount = double.tryParse(json['amount'] as String) ?? 0.0;
    }

    DateTime parsedDate;
    try {
      final rawDate = json['date'];
      parsedDate = rawDate != null
          ? DateTime.parse(rawDate.toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime? parsedModified;
    if (json['lastModified'] != null) {
      try {
        parsedModified = DateTime.parse(json['lastModified'].toString());
      } catch (_) {}
    }

    DateTime parsedCreatedAt;
    try {
      final rawCreated = json['createdAt'];
      parsedCreatedAt = rawCreated != null
          ? DateTime.parse(rawCreated.toString())
          : parsedDate;
    } catch (_) {
      parsedCreatedAt = parsedDate;
    }

    final rawType = json['type']?.toString() ?? 'expense';
    final parsedType = TransactionType.fromString(rawType);

    Map<String, double>? parsedSplits;
    if (json['splitAmounts'] is Map) {
      parsedSplits = {};
      (json['splitAmounts'] as Map).forEach((k, v) {
        if (v is num) {
          parsedSplits![k.toString()] = v.toDouble();
        } else if (v is String) {
          parsedSplits![k.toString()] = double.tryParse(v) ?? 0.0;
        }
      });
    }

    final isGroup = json['isGroupTransaction'] == true || json['isFamilyTransaction'] == true;
    final resolvedGroupId = json['groupId']?.toString() ?? json['familyId']?.toString();

    return ExpenseTransaction(
      id: json['id']?.toString() ?? const Uuid().v4(),
      title: json['title']?.toString() ?? 'Untitled',
      amount: parsedAmount.abs(),
      date: parsedDate,
      category: json['category']?.toString() ??
          (parsedType == TransactionType.expense ? 'Other Expense' : 'Other Income'),
      type: parsedType,
      note: json['note']?.toString(),
      description: json['description']?.toString(),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod']?.toString()),
      accountId: json['accountId']?.toString(),
      createdAt: parsedCreatedAt,
      isGroupTransaction: isGroup,
      groupId: resolvedGroupId,
      paidByUserId: json['paidByUserId']?.toString(),
      paidByName: json['paidByName']?.toString(),
      splitType: json['splitType']?.toString(),
      splitAmounts: parsedSplits,
      syncStatus: SyncStatus.fromString(json['syncStatus']?.toString()),
      lastModified: parsedModified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
