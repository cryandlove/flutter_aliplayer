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
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { PlayerEventSink } from './FlutterAliplayerPlugin';

const TAG: string = 'FlutterAliPlayer';

/**
 * playerId 到鸿蒙原生播放器实例的包装：
 * 控制/查询方法由插件按通道协议转发到这里，事件统一回传给 EventSink。
 */
export class FlutterAliPlayer {
  private playerId: string;
  private eventSink: PlayerEventSink;
  private player: AliPlayer;

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
    this.player.release();
  }

  releaseAsync(): void {
    Log.i(TAG, `releaseAsync playerId=${this.playerId}`);
    this.player.releaseAsync();
  }
}
