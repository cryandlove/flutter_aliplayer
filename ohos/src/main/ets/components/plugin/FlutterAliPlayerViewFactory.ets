import common from '@ohos.app.ability.common';
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import { StandardMessageCodec, Any } from '@ohos/flutter_ohos';
import { FlutterAliPlayerPlatformView } from './FlutterAliPlayerPlatformView';

/**
 * 平台视图工厂：viewId 是 Flutter 侧已知的唯一标识，
 * setPlayerView(viewId) 时通过这里的注册表把视图与播放器实例关联。
 */
export class FlutterAliPlayerViewFactory extends PlatformViewFactory {
  private viewMap: Map<number, FlutterAliPlayerPlatformView> = new Map<number, FlutterAliPlayerPlatformView>();

  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Any): PlatformView {
    const view: FlutterAliPlayerPlatformView = new FlutterAliPlayerPlatformView(viewId);
    this.viewMap.set(viewId, view);
    return view;
  }

  findView(viewId: number): FlutterAliPlayerPlatformView | null {
    return this.viewMap.get(viewId) ?? null;
  }

  removeView(viewId: number): void {
    this.viewMap.delete(viewId);
  }
}
