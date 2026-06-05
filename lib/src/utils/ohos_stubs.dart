/// Platform stubs for ohos to replace missing platform implementations.
library;

import 'dart:async';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Initialize all ohos platform stubs.
void initOhosStubs() {
  OhosConnectivityPlatform.register();
}

/// Set up deep link handler for OAuth callback on ohos.
///
/// Uses a custom MethodChannel (org.lichess.lichess_mobile/deep_link) to avoid
/// conflicts with the app_links package. ArkTS EntryAbility.onNewWant sends
/// 'onDeepLink' method calls with the URI as argument.
StreamController<Uri>? _deepLinkController;
Uri? _lastOhosDeepLinkUri;

void initOhosDeepLinks() {
  _deepLinkController ??= StreamController<Uri>.broadcast();
  const channel = MethodChannel('org.lichess.lichess_mobile/deep_link');
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final String? uriString = call.arguments as String?;
      if (uriString != null) {
        final uri = Uri.tryParse(uriString);
        // Guard against duplicate onNewWant from browser "open app" button
        if (uri != null && uri != _lastOhosDeepLinkUri) {
          _lastOhosDeepLinkUri = uri;
          _deepLinkController!.add(uri);
        }
      }
    }
  });
}

Stream<Uri> get ohosDeepLinkStream {
  _deepLinkController ??= StreamController<Uri>.broadcast();
  return _deepLinkController!.stream;
}

Future<Uri?> getOhosInitialLink() async {
  // On ohos, initial links arrive via onNewWant after engine is ready.
  // We can't query for them - wait for the deep link stream instead.
  return null;
}

/// Stub ConnectivityPlatform that always reports wifi connected.
class OhosConnectivityPlatform extends ConnectivityPlatform {
  static void register() {
    ConnectivityPlatform.instance = OhosConnectivityPlatform();
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Stream<List<ConnectivityResult>>.value([ConnectivityResult.wifi]);
  }
}
