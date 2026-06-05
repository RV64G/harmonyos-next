import { FlutterEngine, Log, MethodChannel, MethodCall, MethodResult } from '@ohos/flutter_ohos';
import { common, Want } from '@kit.AbilityKit';

const TAG = 'UrlLauncherPlugin';
const CHANNEL = 'plugins.flutter.io/url_launcher';
const IN_APP_BROWSER_CHANNEL = 'org.lichess.lichess_mobile/in_app_browser';

export class UrlLauncherPlugin {
  private channel: MethodChannel;
  private browserChannel: MethodChannel;
  private context: common.UIAbilityContext;

  constructor(flutterEngine: FlutterEngine, context: common.UIAbilityContext) {
    this.context = context;
    this.channel = new MethodChannel(flutterEngine.dartExecutor, CHANNEL);
    this.browserChannel = new MethodChannel(flutterEngine.dartExecutor, IN_APP_BROWSER_CHANNEL);
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        this.onMethodCall(call, result);
      },
    });
    Log.i(TAG, 'UrlLauncherPlugin registered');
  }

  private onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.i(TAG, `Method call: ${call.method}`);
    switch (call.method) {
      case 'launch':
      case 'launchUrl':
        this.launch(call, result);
        break;
      case 'canLaunch':
        this.canLaunch(call, result);
        break;
      case 'closeWebView':
        result.success(null);
        break;
      case 'supportsLaunchMode':
        this.supportsLaunchMode(call, result);
        break;
      case 'supportsCloseForLaunchMode':
        result.success(false);
        break;
      default:
        Log.w(TAG, `Unsupported method: ${call.method}`);
        result.success(false);
    }
  }

  private launch(call: MethodCall, result: MethodResult): void {
    const url: string = call.argument('url');
    if (!url) {
      result.error('INVALID_URL', 'URL argument is required', null);
      return;
    }

    try {
      if (this.shouldOpenInApp(url) && !this.shouldForceExternal(call) && !this.shouldOpenExternal(url)) {
        this.browserChannel.invokeMethod('open', { url: url }, {
          success: (_: object): void => {
            Log.i(TAG, `Opened in-app URL: ${url}`);
            result.success(true);
          },
          error: (errorCode: string, errorMessage: string, errorDetails: object): void => {
            Log.e(TAG, `Failed to open in-app URL: ${url}, ${errorCode}: ${errorMessage}`);
            result.success(false);
          },
          notImplemented: (): void => {
            Log.e(TAG, `In-app browser channel is not ready for URL: ${url}`);
            result.success(false);
          },
        });
        return;
      }

      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url,
      };
      const launcher = this.context.startAbility(want, { hideStartWindow: true });

      launcher.then(() => {
        Log.i(TAG, `Launched URL: ${url}`);
        result.success(true);
      }).catch((err: Error) => {
        Log.e(TAG, `Failed to launch URL: ${url}, error: ${err.message}`);
        result.success(false);
      });
    } catch (e) {
      Log.e(TAG, `Exception launching URL: ${url}, ${e}`);
      result.success(false);
    }
  }

  private shouldOpenInApp(url: string): boolean {
    return url.startsWith('https://') || url.startsWith('http://');
  }

  private shouldOpenExternal(url: string): boolean {
    return url.startsWith('https://lichess.org/oauth') || url.startsWith('http://lichess.org/oauth');
  }

  private shouldForceExternal(call: MethodCall): boolean {
    const mode: string | null = call.argument('mode');
    return mode === 'externalApplication' || mode === 'externalNonBrowserApplication';
  }

  private canLaunch(call: MethodCall, result: MethodResult): void {
    const url: string = call.argument('url');
    if (!url) {
      result.success(false);
      return;
    }
    const canLaunch =
      url.startsWith('https://') ||
      url.startsWith('http://') ||
      url.startsWith('mailto:') ||
      url.startsWith('tel:') ||
      url.startsWith('org.lichess.mobile://');
    result.success(canLaunch);
  }

  private supportsLaunchMode(call: MethodCall, result: MethodResult): void {
    const mode: string | null = call.argument('mode');
    result.success(
      mode === null ||
      mode === 'platformDefault' ||
      mode === 'inAppWebView' ||
      mode === 'inAppBrowserView' ||
      mode === 'externalApplication' ||
      mode === 'externalNonBrowserApplication'
    );
  }
}
