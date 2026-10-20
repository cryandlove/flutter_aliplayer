package com.alibaba.fplayer.flutter_aliplayer;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.aliyun.player.AliListPlayer;
import com.aliyun.player.IPlayer;
import com.aliyun.player.videoview.AliDisplayView;

import java.util.Map;

import io.flutter.plugin.platform.PlatformView;


public class FlutterAliPlayerView implements PlatformView {

    // 视图类型
    private static final String SURFACE_VIEW_TYPE = "surfaceview";
    private static final String TEXTURE_VIEW_TYPE = "textureview";
    private static final String DISPLAY_VIEW_TYPE = "displayview";
    private Context mContext; // 上下文
    private IPlayer mPlayer; // 播放器基类
    private final int mViewId; // PlatformView 创建后产出的viewId;

    private SurfaceView mSurfaceView; // 播放器视图 SurfaceView
    private TextureView mTextureView; // 播放器视图 TextureView

    private AliDisplayView mAliDisplayView; // AliDisplayView 适配HDR

    private SurfaceHolder mSurfaceHolder; // SurfaceView 监听产出

    private Surface mSurface; // TextureView 监听产出

    private String viewType = SURFACE_VIEW_TYPE; // 默认视图类型
    private FrameLayout rootView; // 总显示视图，包含播放器视图控件
    private FlutterAliPlayerViewListener mFlutterAliPlayerViewListener; // 播放器视图销毁监听

    /**
     * PlatformView 创建
     *
     * @param context 上下文
     * @param viewId  PlatformView viewID
     * @param args    创建参数，一般为 Map<String, Object>
     */
    public FlutterAliPlayerView(Context context, int viewId, Object args) {
        if (args != null) {
            Map<String, Object> argsMap = (Map<String, Object>) args;
            viewType = (String) argsMap.get("viewType");
        }
        this.mViewId = viewId;
        this.mContext = context;

        initView();
    }


    /**
     * 根据viewType 创建播放器视图
     */
    private void initView() {
        rootView = new FrameLayout(mContext);

        if (isTextureView()) {
            mTextureView = new TextureView(mContext);
            rootView.addView(mTextureView);
        } else if (DISPLAY_VIEW_TYPE.equals(viewType)) {
            mAliDisplayView = new AliDisplayView(mContext);
            mAliDisplayView.setPreferDisplayView(AliDisplayView.DisplayViewType.TextureView);
            rootView.addView(mAliDisplayView);
        } else {
            mSurfaceView = new SurfaceView(mContext);
            rootView.addView(mSurfaceView);
        }

        initRenderListener();
    }

    /**
     * 获取播放器
     *
     * @return aliPlayer
     */
    public IPlayer getPlayer() {
        return mPlayer;
    }


    /**
     * 绑定播放器视图
     *
     * @param player 播放器
     */
    public void setPlayer(IPlayer player) {
        this.mPlayer = player;
        setRenderView();
    }

    /**
     * 清除播放器引用，防止 PlatformView 销毁时触发 setSurface(null)。
     * <p>
     * 当播放器从当前 View 切换到另一个 View 时（如全屏切换），
     * 应先调用旧 View 的 clearPlayer()，确保旧 View 销毁时
     * onSurfaceTextureDestroyed 中的 mPlayer == null 检查生效，
     * 不会误清播放器的 Surface。
     */
    public void clearPlayer() {
        this.mPlayer = null;
    }

    /**
     * 判断是否为 TEXTURE_VIEW_TYPE
     *
     * @return TEXTURE_VIEW_TYPE.equals(viewType)
     */
    private boolean isTextureView() {
        return TEXTURE_VIEW_TYPE.equals(viewType);
    }


    public boolean isDisplayView() {
        return DISPLAY_VIEW_TYPE.equals(viewType);
    }

    @Override
    public View getView() {
        return rootView;
    }

    /**
     * 销毁监听
     */
    @Override
    public void dispose() {
        // 销毁前清除 mPlayer 引用，防止异步回调
        // （如 onSurfaceTextureDestroyed）在 dispose 后仍调用 setSurface(null)
        mPlayer = null;
        destroyView();
    }


    /**
     * 根据 viewType 初始化对应监听
     */
    private void initRenderListener() {
        switch (viewType) {
            case TEXTURE_VIEW_TYPE: {
                if (null != mTextureView) {
                    mTextureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
                        @Override
                        public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
                            mSurface = new Surface(surface);
                            if (null != mPlayer) {
                                mPlayer.setSurface(mSurface);
                            }
                        }

                        @Override
                        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
                            if (null != mPlayer) {
                                mPlayer.surfaceChanged();
                            }
                        }

                        @Override
                        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
                            /*
                             *  当使用 pageView 实现列表播放时，会出现画面卡主，声音正常的问题。
                             *  原因：滑动到下一个界面后，先设置 Surface 给 ListPlayer，然后上一个,Surface 销毁，setSurface(null);
                             *  部分手机如果不设置为 null，多次调用 setSurface 会导致崩溃。因此在 handler的事件里，先设置为 null，再设置 Surface.
                             */
                            if (!(mPlayer instanceof AliListPlayer)) {
                                if (null == mPlayer) return false;
                                mPlayer.setSurface(null);
                            }
                            return false;
                        }

                        @Override
                        public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {

                        }
                    });
                }
            }


            break;
            case DISPLAY_VIEW_TYPE:
                if (null != mAliDisplayView && null != mPlayer) {
                    mPlayer.setDisplayView(mAliDisplayView);
                }
                break;
            default:
                if (null != mSurfaceView) {
                    mSurfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
                        @Override
                        public void surfaceCreated(@NonNull SurfaceHolder holder) {
                            mSurfaceHolder = holder;
                            if (null != mPlayer) {
                                mPlayer.setSurface(holder.getSurface());
                            }
                        }

                        @Override
                        public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
                            if (null != mPlayer) {
                                mPlayer.surfaceChanged();
                            }
                        }

                        @Override
                        public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
                            /*
                                当使用 pageView 实现列表播放时，会出现画面卡主，声音正常的问题。
                                原因：滑动到下一个界面后，先设置 Surface 给 ListPlayer，然后上一个
                                    Surface 销毁，setSurface(null);
                                部分手机如果不设置为 null，多次调用 setSurface 会导致崩溃。因此在 handler
                                的事件里，先设置为 null，再设置 Surface.
                            */
                            if (!(mPlayer instanceof AliListPlayer)) {
                                if (null == mPlayer) return;
                                mPlayer.setSurface(null);
                            }
                        }
                    });
                }

                break;
        }
    }

    /**
     * 确保播放器设置后，绑定了对应播放器视图
     */
    public void setRenderView() {
        if (isTextureView()) {
            if (null != mPlayer && null != mSurface) {
                mPlayer.setSurface(mSurface);
            }
        } else if (DISPLAY_VIEW_TYPE.equals(viewType)) {
            if (null != mPlayer && null != mAliDisplayView) {
                // TODO: 在 surfaceView (悬浮窗场景下) 切回 mAliDisPlayView 有 问题
                mPlayer.setDisplayView(mAliDisplayView);
            }
        } else {
            if (null != mPlayer && null != mSurfaceHolder && null != mSurfaceHolder.getSurface()) {
                mPlayer.setSurface(mSurfaceHolder.getSurface());
            }
        }
    }


    /**
     * 销毁视图
     */
    private void destroyView() {
        // 销毁 TextureView 的 Surface
        if (null != mSurface) {
            mSurface.release();
            mSurface = null;
        }

        // 销毁 AliDisplayView
        if (null != mAliDisplayView) {
            mAliDisplayView = null;
        }

        // 销毁 SurfaceView 的 surfaceHolder
        if (null != mSurfaceHolder) {
            Surface surface = mSurfaceHolder.getSurface();
            if (null != surface && surface.isValid()) {
                surface.release();
            }
            mSurfaceHolder = null;
        }


        if (mFlutterAliPlayerViewListener != null) {
            mFlutterAliPlayerViewListener.onDispose(mViewId);
        }
    }

    /**
     * 销毁监听透出接口
     */
    public interface FlutterAliPlayerViewListener {
        void onDispose(int viewId);
    }


    /**
     * 设置视图销毁监听接口
     *
     * @param listener FlutterAliPlayerViewListener
     */
    public void setFlutterAliPlayerViewListener(FlutterAliPlayerViewListener listener) {
        this.mFlutterAliPlayerViewListener = listener;
    }

}