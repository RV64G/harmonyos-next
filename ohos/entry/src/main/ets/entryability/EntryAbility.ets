
import { FlutterAbility, FlutterEngine, MethodChannel, Log } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { common, Want, AbilityConstant } from '@kit.AbilityKit';
import { UrlLauncherPlugin } from '../plugins/UrlLauncherPlugin';
import {
  LICHESS_BROWSER_VIEW_TYPE,
  LichessBrowserPlatformViewFactory,
} from '../platform/LichessBrowserPlatformView';

const TAG = 'EntryAbility';
const DEEP_LINK_CHANNEL = 'org.lichess.lichess_mobile/deep_link';
const IN_APP_BROWSER_CHANNEL = 'org.lichess.lichess_mobile/in_app_browser';

export default class EntryAbility extends FlutterAbility {
  private deepLinkChannel?: MethodChannel;
  private browserChannel?: MethodChannel;
  private urlLauncherPlugin?: UrlLauncherPlugin;
  private _lastUri?: string;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    this.urlLauncherPlugin = new UrlLauncherPlugin(
      flutterEngine,
      this.context as common.UIAbilityContext,
    );

    this.deepLinkChannel = new MethodChannel(flutterEngine.dartExecutor, DEEP_LINK_CHANNEL);
    this.browserChannel = new MethodChannel(flutterEngine.dartExecutor, IN_APP_BROWSER_CHANNEL);
    const registry = flutterEngine.getPlatformViewsController()?.getRegistry();
    registry?.registerViewFactory(
      LICHESS_BROWSER_VIEW_TYPE,
      new LichessBrowserPlatformViewFactory(this.deepLinkChannel, this.browserChannel),
    );
    Log.i(TAG, 'url_launcher + deep_link + in_app_browser ready');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const uri = want?.uri as string | undefined;
    // Guard against duplicate onNewWant calls from browser "open app" button
    if (!uri || uri === this._lastUri) return;
    this._lastUri = uri;
    Log.i(TAG, `onNewWant: ${uri}`);
    if (this.deepLinkChannel) {
      this.deepLinkChannel.invokeMethod('onDeepLink', uri);
    }
  }

  onWindowStageDestroy(): void {
    try {
      super.onWindowStageDestroy();
    } catch (error) {
      Log.e(TAG, `Ignored FlutterAbility onWindowStageDestroy error: ${JSON.stringify(error)}`);
    }
  }
}
