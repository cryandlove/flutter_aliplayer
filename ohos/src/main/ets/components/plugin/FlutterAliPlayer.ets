import common from '@ohos.app.ability.common';
import { AliPlayer, AliPlayerFactory, ErrorInfo, InfoBean, UrlSource } from 'premierlibrary';
import {
  OnCompletionListener,
  OnErrorListener,
  OnInfoListener,
  OnLoadingStatusListener,
  OnPreparedListener,
  OnRenderingStartListener,
  OnSeekCompleteListener,
  OnVideoSizeChangedListener
} from 'premierlibrary/src/main/ets/com/aliyun/player/IPlayer';
import { OnVidAuthExpiredListener } from 'premierlibrary/src/main/ets/com/aliyun/player/AliPlayer';
import {
  OnURLSourceExpiredListener,
  SourceRefreshCallback
} from 'premierlibrary/src/main/ets/com/aliyun/player/UrlPlayer';
import { VidAuth } from 'premierlibrary/src/main/ets/com/aliyun/player/source/VidAuth';
import { BasicMessageChannel, BinaryMessenger, StringCodec } from '@ohos/flutter_ohos';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { PlayerEventSink } from './FlutterAliplayerPlugin';
import {
  createLiveSts,
  createVidAuth,
  createVidMps,
  createVidSts
} from './FlutterAliPlayerSource';

const TAG: string = 'FlutterAliPlayer';

/**
 * playerId 到鸿蒙原生播放器实例的包装：
 * 控制/查询方法由插件按通道协议转发到这里，事件统一回传给 EventSink。
 */
export class FlutterAliPlayer {
  private playerId: string;
  private eventSink: PlayerEventSink;
  private player: AliPlayer;
  private authExpiredChannel: BasicMessageChannel<string> | null = null;
  private urlExpiredChannel: BasicMessageChannel<string> | null = null;

  constructor(context: common.Context, playerId: string, eventSink: PlayerEventSink) {
    this.playerId = playerId;
    this.eventSink = eventSink;
    this.player = AliPlayerFactory.createAliPlayer(context, playerId);
    this.attachListeners();
    Log.i(TAG, `createAliPlayer playerId=${playerId}`);
  }

  private attachListeners(): void {
    const sink: PlayerEventSink = this.eventSink;
    const playerId: string = this.playerId;

    const preparedListener: OnPreparedListener = {
      onPrepared: () => {
        sink.emit(playerId, 'onPrepared');
      }
    };
    this.player.setOnPreparedListener(preparedListener);

    const renderingStartListener: OnRenderingStartListener = {
      onRenderingStart: () => {
        sink.emit(playerId, 'onRenderingStart');
      }
    };
    this.player.setOnRenderingStartListener(renderingStartListener);

    const completionListener: OnCompletionListener = {
      onCompletion: () => {
        sink.emit(playerId, 'onCompletion');
      }
    };
    this.player.setOnCompletionListener(completionListener);

    const seekCompleteListener: OnSeekCompleteListener = {
      onSeekComplete: () => {
        sink.emit(playerId, 'onSeekComplete');
      }
    };
    this.player.setOnSeekCompleteListener(seekCompleteListener);

    const errorListener: OnErrorListener = {
      onError: (errorInfo: ErrorInfo) => {
        const payload: Record<string, ESObject> = {
          'errorCode': errorInfo.getCode() as ESObject,
          'errorMsg': errorInfo.getMsg(),
          'errorExtra': errorInfo.getExtra()
        };
        sink.emit(playerId, 'onError', payload);
      }
    };
    this.player.setOnErrorListener(errorListener);

    const infoListener: OnInfoListener = {
      onInfo: (infoBean: InfoBean) => {
        const payload: Record<string, ESObject> = {
          'infoCode': infoBean.getCode() as ESObject,
          'extraValue': infoBean.getExtraValue(),
          'extraMsg': infoBean.getExtraMsg()
        };
        sink.emit(playerId, 'onInfo', payload);
      }
    };
    this.player.setOnInfoListener(infoListener);

    const loadingListener: OnLoadingStatusListener = {
      onLoadingBegin: () => {
        sink.emit(playerId, 'onLoadingBegin');
      },
      onLoadingEnd: () => {
        sink.emit(playerId, 'onLoadingEnd');
      },
      onLoadingProgress: (percent: number, netSpeed: number) => {
        const payload: Record<string, ESObject> = {
          'percent': percent,
          'netSpeed': netSpeed
        };
        sink.emit(playerId, 'onLoadingProgress', payload);
      }
    };
    this.player.setOnLoadingStatusListener(loadingListener);

    const videoSizeChangedListener: OnVideoSizeChangedListener = {
      onVideoSizeChanged: (width: number, height: number) => {
        const payload: Record<string, ESObject> = {
          'width': width,
          'height': height
        };
        sink.emit(playerId, 'onVideoSizeChanged', payload);
      }
    };
    this.player.setOnVideoSizeChangedListener(videoSizeChangedListener);
  }

  setUrl(url: string): void {
    const source: UrlSource = new UrlSource();
    source.setUri(url);
    this.player.setUrlDataSource(source);
  }

  setVidAuth(arg: Record<string, ESObject>): void {
    this.player.setVidAuthDataSource(createVidAuth(arg));
  }

  setVidSts(arg: Record<string, ESObject>): void {
    this.player.setVidStsDataSource(createVidSts(arg));
  }

  setVidMps(arg: Record<string, ESObject>): void {
    this.player.setVidMpsDataSource(createVidMps(arg));
  }

  setLiveSts(arg: Record<string, ESObject>): void {
    this.player.setLiveStsDataSource(createLiveSts(arg));
  }

  updateVidAuth(arg: Record<string, ESObject>): void {
    this.player.updateVidAuth(createVidAuth(arg));
  }

  /**
   * VidAuth 过期刷新：过期事件经 BasicMessageChannel 发回 Dart，
   * Dart 回复 {"vid": ..., "playAuth": ...} 后提交给 SDK 刷新回调。
   * 协议与 Android/iOS 保持一致，通道名为 aliPlayer_OnVidAuthExpiredListener${playerId}。
   */
  setOnVidAuthExpiredListener(messenger: BinaryMessenger, enable: boolean): void {
    if (!enable) {
      this.authExpiredChannel = null;
      // SDK 参数不接受 null，禁用时挂空监听并显式上报失败，避免静默吞掉刷新请求。
      const disabledListener: OnVidAuthExpiredListener = {
        onVidAuthExpired: (expiredSource: VidAuth, callback: SourceRefreshCallback<VidAuth> | null) => {
          callback?.onError('the OnVidAuthExpired is Refresh Fail: listener disabled');
        }
      };
      this.player.setOnVidAuthExpiredListener(disabledListener);
      return;
    }
    const channel: BasicMessageChannel<string> = new BasicMessageChannel<string>(
      messenger,
      `aliPlayer_OnVidAuthExpiredListener${this.playerId}`,
      StringCodec.INSTANCE
    );
    this.authExpiredChannel = channel;
    const playerId: string = this.playerId;
    const listener: OnVidAuthExpiredListener = {
      onVidAuthExpired: (expiredSource: VidAuth, callback: SourceRefreshCallback<VidAuth> | null) => {
        const payload: Record<string, ESObject> = {
          'method': 'onVidAuthExpired',
          'playerId': playerId,
          'videoId': expiredSource.getVid(),
          'playAuth': expiredSource.getPlayAuth()
        };
        const region: string = String(expiredSource.getRegion());
        if (region.length > 0) {
          payload['region'] = region;
        }
        channel.send(JSON.stringify(payload), (reply: string) => {
          this.handleVidAuthRefreshReply(expiredSource, callback, reply);
        });
      }
    };
    this.player.setOnVidAuthExpiredListener(listener);
  }

  /**
   * URL 源过期刷新：Dart 回复内容为新 URL 字符串本身（非 JSON），与 Android/iOS 协议一致。
   * 通道名为 aliPlayer_onURLSourceExpiredListener${playerId}。
   */
  setOnUrlSourceExpiredListener(messenger: BinaryMessenger, enable: boolean): void {
    if (!enable) {
      this.urlExpiredChannel = null;
      const disabledListener: OnURLSourceExpiredListener = {
        onUrlSourceExpired: (expiredSource: UrlSource, callback: SourceRefreshCallback<UrlSource> | null) => {
          callback?.onError('the onUrlSourceExpired is Refresh Fail: listener disabled');
        }
      };
      this.player.setOnURLSourceExpiredListener(disabledListener);
      return;
    }
    const channel: BasicMessageChannel<string> = new BasicMessageChannel<string>(
      messenger,
      `aliPlayer_onURLSourceExpiredListener${this.playerId}`,
      StringCodec.INSTANCE
    );
    this.urlExpiredChannel = channel;
    const playerId: string = this.playerId;
    const listener: OnURLSourceExpiredListener = {
      onUrlSourceExpired: (expiredSource: UrlSource, callback: SourceRefreshCallback<UrlSource> | null) => {
        const payload: Record<string, ESObject> = {
          'method': 'onUrlSourceExpired',
          'playerId': playerId,
          'expiredUrl': String(expiredSource.getUri())
        };
        channel.send(JSON.stringify(payload), (reply: string) => {
          if (reply == null || reply.length === 0) {
            callback?.onError('the onUrlSourceExpired is Refresh Fail');
            return;
          }
          expiredSource.setUri(reply);
          callback?.onSuccess(expiredSource);
        });
      }
    };
    this.player.setOnURLSourceExpiredListener(listener);
  }

  private handleVidAuthRefreshReply(expiredSource: VidAuth,
                                    callback: SourceRefreshCallback<VidAuth> | null,
                                    reply: string): void {
    if (reply == null || reply.length === 0) {
      callback?.onError('the OnVidAuthExpired is Refresh Fail');
      return;
    }
    let refreshed: Record<string, ESObject>;
    try {
      refreshed = JSON.parse(reply) as Record<string, ESObject>;
    } catch (error) {
      callback?.onError(`the onVidAuthExpired is JSON Exception: ${String(error)}`);
      return;
    }
    const vid: ESObject = refreshed['vid'];
    const playAuth: ESObject = refreshed['playAuth'];
    if (typeof vid !== 'string' || typeof playAuth !== 'string' || vid.length === 0 || playAuth.length === 0) {
      callback?.onError('the onVidAuthExpired is JSON Exception: vid/playAuth missing');
      return;
    }
    expiredSource.setVid(vid);
    expiredSource.setPlayAuth(playAuth);
    callback?.onSuccess(expiredSource);
  }

  setSurfaceId(surfaceId: string): void {
    this.player.setSurfaceId(surfaceId);
  }

  setAutoPlay(autoPlay: boolean): void {
    this.player.setAutoPlay(autoPlay);
  }

  isAutoPlay(): boolean {
    return this.player.isAutoPlay();
  }

  setLoop(on: boolean): void {
    this.player.setLoop(on);
  }

  isLoop(): boolean {
    return this.player.isLoop();
  }

  setMuted(muted: boolean): void {
    this.player.setMute(muted);
  }

  isMuted(): boolean {
    return this.player.isMuted();
  }

  setSpeed(speed: number): void {
    this.player.setSpeed(speed);
  }

  getSpeed(): number {
    return this.player.getSpeed();
  }

  setVolume(volume: number): void {
    this.player.setVolume(volume);
  }

  getVolume(): number {
    return this.player.getVolume();
  }

  seekTo(position: number, seekMode: number): void {
    this.player.seekTo(position, seekMode);
  }

  prepare(): void {
    this.player.prepare();
  }

  play(): void {
    this.player.start();
  }

  pause(): void {
    this.player.pause();
  }

  stop(): void {
    this.player.stop();
  }

  getCurrentPosition(): number {
    return this.player.getCurrentPosition();
  }

  getBufferedPosition(): number {
    return this.player.getBufferedPosition();
  }

  getDuration(): number {
    return this.player.getDuration();
  }

  getVideoWidth(): number {
    return this.player.getVideoWidth();
  }

  getVideoHeight(): number {
    return this.player.getVideoHeight();
  }

  clearScreen(): void {
    this.player.clearScreen();
  }

  release(): void {
    Log.i(TAG, `release playerId=${this.playerId}`);
    this.authExpiredChannel = null;
    this.urlExpiredChannel = null;
    this.player.release();
  }

  releaseAsync(): void {
    Log.i(TAG, `releaseAsync playerId=${this.playerId}`);
    this.authExpiredChannel = null;
    this.urlExpiredChannel = null;
    this.player.releaseAsync();
  }
}
