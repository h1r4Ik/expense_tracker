/// Application-wide constants including storage keys, limits, and UI tokens.
class AppConstants {
  AppConstants._();

  // SharedPreferences key prefixes
  static const String keyPrefix = 'et_';
  static String accountKey(String accountId, String suffix) =>
      '$keyPrefix${accountId}_$suffix';

  // Data keys (used with accountKey)
  static const String transactionsKey = 'transactions';
  static const String groupsKey = 'groups';
  static const String familiesKey = 'families'; // backward-compatible alias
  static const String syncQueueKey = 'sync_queue';
  static const String activeGroupKey = 'active_group';
  static const String activeFamilyKey =
      'active_family'; // backward-compatible alias

  // Global keys (not per-account)
  static const String accountsKey = '${keyPrefix}accounts';
  static const String activeAccountKey = '${keyPrefix}active_account';
  static const String themeModeKey = '${keyPrefix}theme_mode';
  static const String tutorialCompletedKey = '${keyPrefix}tutorial_completed';
  static const String localUserIdKey = '${keyPrefix}local_user_id';
  static const String customExpenseCategoriesKey =
      '${keyPrefix}custom_expense_categories';
  static const String customIncomeCategoriesKey =
      '${keyPrefix}custom_income_categories';

  // Limits
  static const int maxAccounts = 4;
  static const int syncBatchSize = 10;
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 2);

  // UI
  static const double cardRadius = 23.0;
  static const double inputRadius = 23.0;
  static const double chipRadius = 23.0;
}
