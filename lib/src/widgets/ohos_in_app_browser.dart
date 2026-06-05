import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';

const _kInAppBrowserChannel = 'org.lichess.lichess_mobile/in_app_browser';
const _kBrowserViewType = 'lichess/browser';

class OhosInAppBrowser {
  OhosInAppBrowser._();

  static final OhosInAppBrowser instance = OhosInAppBrowser._();

  final MethodChannel _channel = const MethodChannel(_kInAppBrowserChannel);
  final StreamController<Uri> _closedController = StreamController<Uri>.broadcast();

  GlobalKey<NavigatorState>? _navigatorKey;
  Route<dynamic>? _currentRoute;
  Uri? _currentUri;
  bool _registered = false;

  Stream<Uri> get closed => _closedController.stream;

  void register(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    if (_registered) return;
    _registered = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<bool> open(Uri uri) async {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return false;

    final route = OhosInAppBrowserScreen.buildRoute(uri);
    _currentRoute = route;
    _currentUri = uri;
    unawaited(
      navigator.push(route).whenComplete(() {
        if (_currentRoute == route) {
          _currentRoute = null;
          final closedUri = _currentUri;
          _currentUri = null;
          if (closedUri != null) {
            _closedController.add(closedUri);
          }
        }
      }),
    );
    return true;
  }

  void close() {
    final route = _currentRoute;
    if (route?.navigator != null) {
      route!.navigator!.removeRoute(route);
    } else {
      _navigatorKey?.currentState?.maybePop();
    }
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'open':
        final args = call.arguments as Map<Object?, Object?>?;
        final url = args?['url'] as String?;
        final uri = url == null ? null : Uri.tryParse(url);
        if (uri == null) return false;
        return open(uri);
      case 'close':
        close();
        return true;
      default:
        return false;
    }
  }
}

class OhosInAppBrowserScreen extends StatelessWidget {
  const OhosInAppBrowserScreen({super.key, required this.initialUri});

  final Uri initialUri;

  static Route<void> buildRoute(Uri uri) {
    return buildScreenRoute<void>(
      screen: OhosInAppBrowserScreen(initialUri: uri),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = initialUri.host.isEmpty ? initialUri.toString() : initialUri.host;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: OhosView(
          viewType: _kBrowserViewType,
          creationParams: {'url': initialUri.toString()},
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
      ),
    );
  }
}
