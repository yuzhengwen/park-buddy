import 'package:get_it/get_it.dart';
import 'package:park_buddy/services/notification_service.dart';

final getIt = GetIt.instance;

void setupServices() {
  getIt.registerLazySingleton<NotifService>(
    () => NotifService(),
    dispose: (sv) => sv.dispose(),
  );
}
