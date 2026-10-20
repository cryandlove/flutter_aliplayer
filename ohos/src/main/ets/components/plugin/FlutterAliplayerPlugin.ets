import common from '@ohos.app.ability.common';
import {
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StandardMessageCodec,
  StreamHandler
} from '@ohos/flutter_ohos';
import { FlutterAliPlayer } from './FlutterAliPlayer';
import { FlutterAliPlayerPlatformView } from './FlutterAliPlayerPlatformView';
import { FlutterAliPlayerViewFactory } from './FlutterAliPlayerViewFactory';

const TAG: string = 'FlutterAliplayerPlugin';
const FACTORY_CHANNEL_NAME: string = 'plugins.flutter_aliplayer_factory';
const EVENT_CHANNEL_NAME: string = 'flutter_aliplayer_event';
const RENDER_VIEW_TYPE: string = 'flutter_aliplayer_render_view';

/**
 * 播放器事件出口：native 侧所有回调按 Dart 层 flutter_aliplayer_event
 * 通道的封包约定发送（method=事件名, playerId=实例标识, 其余为负载）。
 */
export class PlayerEventSink {
  private sink: EventSink | null = null;

  setSink(sink: EventSink | null): void {
    this.sink = sink;
  }

  emit(playerId: string, method: string, payload?: Record<string, ESObject>): void {
    if (this.sink == null) {
      return;
    }
    const event: Record<string, ESObject> = {
      'method': method,
      'playerId': playerId
    };
    if (payload != null) {
      for (const key of Object.keys(payload)) {
        event[key] = payload[key];
      }
    }
    this.sink.success(event);
  }
}

/** Dart 侧回调注册类方法：鸿蒙侧监听常驻，这里只需应答成功。 */
const FLAG_METHODS: Set<string> = new Set<string>([
  'setOnPrepare',
  'setOnRenderingStart',
  'setOnStateChanged',
  'setOnPreRenderFrameCallback',
  'setOnRenderFrameCallback'
]);

/** License 相关：7.18.0 起商用授权，凭证就绪前先保持占位。 */
const LICENSE_PLACEHOLDER_METHODS: Set<string> = new Set<string>([
  'initService',
  'initLicenseServiceForIOS'
]);

export default class FlutterAliplayerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private appContext: common.Context | null = null;
  private readonly eventSink: PlayerEventSink = new PlayerEventSink();
  private readonly viewFactory: FlutterAliPlayerViewFactory = new FlutterAliPlayerViewFactory();
  private readonly players: Map<string, FlutterAliPlayer> = new Map<string, FlutterAliPlayer>();

  getUniqueClassName(): string {
    return 'FlutterAliplayerPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onAttachedToEngine');
    this.appContext = binding.getApplicationContext();
    const messenger = binding.getBinaryMessenger();

    this.channel = new MethodChannel(messenger, FACTORY_CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);

    const eventChannel: EventChannel = new EventChannel(messenger, EVENT_CHANNEL_NAME);
    eventChannel.setStreamHandler({
      onListen: (args: ESObject, events: EventSink) => {
        Log.i(TAG, 'event channel listen');
        this.eventSink.setSink(events);
      },
      onCancel: (args: ESObject) => {
        Log.i(TAG, 'event channel cancel');
        this.eventSink.setSink(null);
      }
    } as StreamHandler);

    binding.getPlatformViewRegistry().registerViewFactory(RENDER_VIEW_TYPE, this.viewFactory);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onDetachedFromEngine');
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.eventSink.setSink(null);
    this.releaseAllPlayers();
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const args: ESObject = call.args as ESObject;
    let playerId: string = '';
    let arg: ESObject = null;
    if (args != null) {
      if (args.playerId != null) {
        playerId = String(args.playerId);
      }
      arg = args.arg;
    }

    if (FLAG_METHODS.has(call.method)) {
      result.success(null);
      return;
    }
    if (LICENSE_PLACEHOLDER_METHODS.has(call.method)) {
      // License 凭证就绪前保持占位：直接成功，待接入阿里云授权后补齐。
      Log.w(TAG, `${call.method} is a license placeholder and takes no effect yet`);
      result.success(null);
      return;
    }

    switch (call.method) {
      case 'createAliPlayer': {
        if (this.appContext == null) {
          result.error('NO_CONTEXT', 'FlutterPluginBinding is detached', null);
          return;
        }
        this.releasePlayer(playerId);
        this.players.set(playerId, new FlutterAliPlayer(this.appContext, playerId, this.eventSink));
        result.success(null);
        return;
      }
      case 'setPlayerView': {
        const view: FlutterAliPlayerPlatformView | null = this.viewFactory.findView(Number(arg));
        const player: FlutterAliPlayer | null = this.players.get(playerId) ?? null;
        if (view == null || player == null) {
          Log.w(TAG, `setPlayerView ignored: view=${view != null}, player=${player != null}`);
        } else {
          player.setSurfaceId(view.xComponentId);
        }
        result.success(null);
        return;
      }
      case 'setUrl': {
        this.withPlayer(playerId, result, (player) => player.setUrl(String(arg)));
        return;
      }
      case 'prepare': {
        this.withPlayer(playerId, result, (player) => player.prepare());
        return;
      }
      case 'play': {
        this.withPlayer(playerId, result, (player) => player.play());
        return;
      }
      case 'pause': {
        this.withPlayer(playerId, result, (player) => player.pause());
        return;
      }
      case 'stop': {
        this.withPlayer(playerId, result, (player) => player.stop());
        return;
      }
      case 'destroy': {
        this.releasePlayer(playerId);
        result.success(null);
        return;
      }
      case 'releaseAsync': {
        const player: FlutterAliPlayer | null = this.players.get(playerId) ?? null;
        this.players.delete(playerId);
        if (player != null) {
          player.releaseAsync();
        }
        result.success(null);
        return;
      }
      case 'seekTo': {
        const seekArg = arg as Record<string, ESObject>;
        const position: number = Number(seekArg?.position ?? 0);
        const seekMode: number = Number(seekArg?.seekMode ?? 0);
        this.withPlayer(playerId, result, (player) => player.seekTo(position, seekMode));
        return;
      }
      case 'setAutoPlay': {
        this.withPlayer(playerId, result, (player) => player.setAutoPlay(Boolean(arg)));
        return;
      }
      case 'isAutoPlay': {
        this.withPlayerResult(playerId, result, (player) => player.isAutoPlay());
        return;
      }
      case 'setLoop': {
        this.withPlayer(playerId, result, (player) => player.setLoop(Boolean(arg)));
        return;
      }
      case 'isLoop': {
        this.withPlayerResult(playerId, result, (player) => player.isLoop());
        return;
      }
      case 'setMuted': {
        this.withPlayer(playerId, result, (player) => player.setMuted(Boolean(arg)));
        return;
      }
      case 'isMuted': {
        this.withPlayerResult(playerId, result, (player) => player.isMuted());
        return;
      }
      case 'setSpeed': {
        this.withPlayer(playerId, result, (player) => player.setSpeed(Number(arg)));
        return;
      }
      case 'getSpeed': {
        this.withPlayerResult(playerId, result, (player) => player.getSpeed());
        return;
      }
      case 'setVolume': {
        this.withPlayer(playerId, result, (player) => player.setVolume(Number(arg)));
        return;
      }
      case 'getVolume': {
        this.withPlayerResult(playerId, result, (player) => player.getVolume());
        return;
      }
      case 'getCurrentPosition': {
        this.withPlayerResult(playerId, result, (player) => player.getCurrentPosition());
        return;
      }
      case 'getBufferedPosition': {
        this.withPlayerResult(playerId, result, (player) => player.getBufferedPosition());
        return;
      }
      case 'getDuration': {
        this.withPlayerResult(playerId, result, (player) => player.getDuration());
        return;
      }
      case 'getVideoWidth': {
        this.withPlayerResult(playerId, result, (player) => player.getVideoWidth());
        return;
      }
      case 'getVideoHeight': {
        this.withPlayerResult(playerId, result, (player) => player.getVideoHeight());
        return;
      }
      case 'clearScreen':
      case 'clearScreenSync': {
        this.withPlayer(playerId, result, (player) => player.clearScreen());
        return;
      }
      default: {
        // 未实现的方法宁可大声失败，避免静默吞掉业务行为。
        Log.w(TAG, `method not implemented on ohos: ${call.method}`);
        result.notImplemented();
        return;
      }
    }
  }

  private withPlayer(playerId: string, result: MethodResult, action: (player: FlutterAliPlayer) => void): void {
    const player: FlutterAliPlayer | null = this.players.get(playerId) ?? null;
    if (player == null) {
      result.error('PLAYER_NOT_FOUND', `no player for id ${playerId}`, null);
      return;
    }
    action(player);
    result.success(null);
  }

  private withPlayerResult(playerId: string, result: MethodResult, action: (player: FlutterAliPlayer) => ESObject): void {
    const player: FlutterAliPlayer | null = this.players.get(playerId) ?? null;
    if (player == null) {
      result.error('PLAYER_NOT_FOUND', `no player for id ${playerId}`, null);
      return;
    }
    result.success(action(player));
  }

  private releasePlayer(playerId: string): void {
    const player: FlutterAliPlayer | null = this.players.get(playerId) ?? null;
    if (player != null) {
      this.players.delete(playerId);
      player.release();
    }
  }

  private releaseAllPlayers(): void {
    for (const playerId of Array.from(this.players.keys())) {
      this.releasePlayer(playerId);
    }
  }
}
