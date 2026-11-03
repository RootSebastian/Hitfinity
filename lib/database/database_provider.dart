import 'app_database.dart';

/// Global access to the single database instance.
/// Call `DatabaseProvider.instance` anywhere in your app.
class DatabaseProvider {
  static final AppDatabase instance = AppDatabase();
}