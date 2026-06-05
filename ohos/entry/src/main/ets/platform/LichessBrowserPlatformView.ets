import common from '@ohos.app.ability.common';
import webview from '@ohos.web.webview';
import {
  Any,
  Log,
  MethodChannel,
  PlatformViewFactory,
  StandardMessageCodec,
} from '@ohos/flutter_ohos';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';

const TAG = 'LichessBrowserPlatformView';

export const LICHESS_BROWSER_VIEW_TYPE = 'lichess/browser';

@Builder
function BuildLichessBrowser(params: Params) {
  LichessBrowserComponent({
    platformView: params.platformView as LichessBrowserPlatformView,
  });
}

@Component
struct LichessBrowserComponent {
  platformView: LichessBrowserPlatformView | null = null;

  build() {
    if (this.platformView) {
      Web({ src: this.platformView.initialUrl, controller: this.platformView.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onlineImageAccess(true)
        .mixedMode(MixedMode.All)
        .onLoadIntercept((event) => this.platformView!.intercept(event.data.getRequestUrl()))
        .width('100%')
        .height('100%');
    }
  }
}

export class LichessBrowserPlatformView extends PlatformView {
  readonly controller: webview.WebviewController = new webview.WebviewController();
  readonly initialUrl: string;
  private deepLinkChannel: MethodChannel;
  private browserChannel: MethodChannel;

  constructor(initialUrl: string, deepLinkChannel: MethodChannel, browserChannel: MethodChannel) {
    super();
    this.initialUrl = initialUrl;
    this.deepLinkChannel = deepLinkChannel;
    this.browserChannel = browserChannel;
  }

  getType(): string {
    return LICHESS_BROWSER_VIEW_TYPE;
  }

  getView(): WrappedBuilder<[Params]> {
    return wrapBuilder(BuildLichessBrowser);
  }

  dispose(): void {
  }

  intercept(url: string): boolean {
    if (url.startsWith('org.lichess.mobile://')) {
      Log.i(TAG, `Intercept deep link: ${url}`);
      this.deepLinkChannel.invokeMethod('onDeepLink', url);
      this.browserChannel.invokeMethod('close', null);
      return true;
    }
    return false;
  }
}

export class LichessBrowserPlatformViewFactory extends PlatformViewFactory {
  private deepLinkChannel: MethodChannel;
  private browserChannel: MethodChannel;

  constructor(deepLinkChannel: MethodChannel, browserChannel: MethodChannel) {
    super(StandardMessageCodec.INSTANCE);
    this.deepLinkChannel = deepLinkChannel;
    this.browserChannel = browserChannel;
  }

  create(context: common.Context, viewId: number, args: Any): PlatformView {
    const params = args as Map<string, string> | null;
    const url = params?.get('url') ?? 'https://lichess.org';
    Log.i(TAG, `Create browser view ${viewId}: ${url}`);
    return new LichessBrowserPlatformView(url, this.deepLinkChannel, this.browserChannel);
  }
}
