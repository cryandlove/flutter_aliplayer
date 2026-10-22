import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'FlutterAliPlayerPlatformView';

/**
 * 鸿蒙端播放器平台视图：持有 XComponent，Dart 侧 setPlayerView(viewId) 后由
 * 插件把播放器绑定到对应 XComponent。按官方原子接入规范：XComponent 通过
 * libraryname: 'premierlibrary' 加载播放器 SO（SDK 原生渲染路径），
 * setSurfaceId 传 XComponent 的 id 字符串（官方 Demo：id='0'、setSurfaceId('0')）；
 * getXComponentSurfaceId() 的 uid 兜底路径在 flutter 纹理合成环境下不可用
 * （SDK 拿不到可渲染窗口，GLRender 每帧丢弃，黑屏）。
 */
export class FlutterAliPlayerPlatformView extends PlatformView {
  readonly viewId: number;
  readonly xComponentId: string;
  onSurfaceReady: ((surfaceId: string) => void) | null = null;
  onDisposed: (() => void) | null = null;
  private cachedSurfaceId: string | null = null;

  constructor(viewId: number) {
    super();
    this.viewId = viewId;
    this.xComponentId = `flutter_aliplayer_surface_${viewId}`;
    Log.i(TAG, `create platform view ${this.viewId}, xComponentId=${this.xComponentId}`);
  }

  /** XComponent onLoad 后即可用的真实原生 surfaceId；未就绪时为 null。 */
  get surfaceId(): string | null {
    return this.cachedSurfaceId;
  }

  /**
   * 由 AliPlayerViewStruct 在 XComponent onLoad 时调用：
   * 缓存真实 surfaceId，并通过 onSurfaceReady 回调通知插件侧重绑播放器。
   */
  markSurfaceReady(surfaceId: string): void {
    this.cachedSurfaceId = surfaceId;
    Log.i(TAG, `surface ready: view=${this.viewId}, realSurfaceId=${surfaceId}`);
    if (this.onSurfaceReady != null) {
      this.onSurfaceReady(surfaceId);
    }
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
  private xComponentController: XComponentController = new XComponentController();

  build() {
    XComponent({
      id: this.platformView.xComponentId,
      type: XComponentType.SURFACE,
      // 官方原子接入规范：必须用 libraryname 加载播放器 SO，
      // SDK 才走原生 XComponent 渲染路径（框架把原生窗口直接交给 SDK）。
      libraryname: 'premierlibrary',
      controller: this.xComponentController
    })
      .width('100%')
      .height('100%')
      .onLoad(() => {
        const realSurfaceId: string = this.xComponentController.getXComponentSurfaceId();
        Log.i(TAG, `xComponent loaded: ${this.platformView.xComponentId}, realSurfaceId=${realSurfaceId}`);
        this.platformView.markSurfaceReady(realSurfaceId);
      })
  }
}

@Builder
export function AliPlayerViewBuilder(params: Params) {
  AliPlayerViewStruct({ params: params })
}
