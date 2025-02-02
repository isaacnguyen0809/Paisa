import 'package:paisa/features/recurring/data/model/recurring.dart';

abstract interface class LocalRecurringDataManager {
  Future<void> addRecurringEvent(RecurringModel recurringModel);

  List<RecurringModel> recurringModels();

  Future<void> clearRecurring(int recurringId);
}
