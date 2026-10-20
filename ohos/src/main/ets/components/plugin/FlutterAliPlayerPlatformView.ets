import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'FlutterAliPlayerPlatformView';

/**
 * 鸿蒙端播放器平台视图：持有 XComponent 的 surfaceId，
 * Dart 侧 setPlayerView(viewId) 后由插件把 surfaceId 绑定到对应播放器实例。
 */
export class FlutterAliPlayerPlatformView extends PlatformView {
  private viewId: number;
  readonly xComponentId: string;
  onSurfaceReady: (() => void) | null = null;
  onDisposed: (() => void) | null = null;

  constructor(viewId: number) {
    super();
    this.viewId = viewId;
    this.xComponentId = `flutter_aliplayer_surface_${viewId}`;
    Log.i(TAG, `create platform view ${this.viewId}, xComponentId=${this.xComponentId}`);
  }

  getType(): string {
    return 'flutter_aliplayer_render_view';
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(AliPlayerViewBuilder);
  }

  dispose(): void {
    Log.i(TAG, `dispose platform view ${this.viewId}`);
    this.onSurfaceReady = null;
    if (this.onDisposed != null) {
      this.onDisposed();
    }
  }
}

@Component
export struct AliPlayerViewStruct {
  @ObjectLink params: Params;
  private platformView: FlutterAliPlayerPlatformView =
    this.params.platformView as FlutterAliPlayerPlatformView;

  build() {
    XComponent({ id: this.platformView.xComponentId, type: XComponentType.SURFACE })
      .width('100%')
      .height('100%')
      .onLoad(() => {
        Log.i(TAG, `xComponent loaded: ${this.platformView.xComponentId}`);
        if (this.platformView.onSurfaceReady != null) {
          this.platformView.onSurfaceReady();
        }
      })
  }
}

@Builder
export function AliPlayerViewBuilder(params: Params) {
  AliPlayerViewStruct({ params: params })
}
