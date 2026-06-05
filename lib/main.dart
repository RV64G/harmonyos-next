import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/app.dart';
import 'package:lichess_mobile/src/binding.dart';
import 'package:lichess_mobile/src/init.dart';
import 'package:lichess_mobile/src/intl.dart';
import 'package:lichess_mobile/src/model/common/service/sound_service.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/utils/ohos_stubs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

Future<void> main() async {
  SharedPreferencesAsyncPlatform.instance ??= InMemorySharedPreferencesAsync.empty();
  initOhosStubs();

  PackageInfo.setMockInitialValues(
    appName: 'Lichess', packageName: 'org.lichess.lichess_mobile',
    version: '0.24.1', buildNumber: '002401',
    buildSignature: '', installerStore: '',
  );

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  initOhosDeepLinks();
  final lichessBinding = AppLichessBinding.ensureInitialized();

  try { await lichessBinding.preloadSharedPreferences(); } catch (e) { debugPrint('prefs: $e'); }
  try { await preloadPieceImages(); } catch (e) { debugPrint('pieces: $e'); }
  try { await initializeApp().timeout(const Duration(seconds: 5)); } catch (e) { debugPrint('initApp: $e'); }
  try { await SoundService.initialize(); } catch (e) { debugPrint('sound: $e'); }
  final locale = await setupIntl(widgetsBinding);
  try { await initializeLocalNotifications(locale).timeout(const Duration(seconds: 5)); } catch (e) { debugPrint('notif: $e'); }

  const isOhos = bool.fromEnvironment('dart.library.ohos');
  if (defaultTargetPlatform != TargetPlatform.linux && !isOhos) {
    try { await lichessBinding.initializeFirebase(); } catch (e) { debugPrint('firebase: $e'); }
  }

  runApp(ProviderScope(child: const AppInitializationScreen()));
}