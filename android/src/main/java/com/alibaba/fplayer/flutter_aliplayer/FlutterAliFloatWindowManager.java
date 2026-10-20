package com.alibaba.fplayer.flutter_aliplayer;

import android.annotation.SuppressLint;
import android.app.ActivityOptions;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import com.aliyun.player.AliPlayer;

import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * FlutterAliFloatWindowManager 类用于管理Flutter阿里播放器的悬浮窗功能
 * <p>
 * 请使用新的悬浮窗实现方案替代
 */
public class FlutterAliFloatWindowManager {

    private final WindowManager mWindowManager;
    private final DisplayMetrics mDisplayMetrics;
    private final WindowManager.LayoutParams mLayoutParams;
    private SurfaceView mSurfaceView;
    private RelativeLayout rootView;
    //
    private ImageView closeButton, backButton;
    private Context mContext;
    private WeakReference<FlutterAliPlayerView> mBindViewReference;

    private int initialX;
    private int initialY;

    private boolean isViewAdded = false;


    @SuppressLint("ClickableViewAccessibility")
    public FlutterAliFloatWindowManager(Context context) {
        this.mContext = context.getApplicationContext();
        // 获取窗口管理器
        mWindowManager = (WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE);
        // 获取屏幕尺寸
        mDisplayMetrics = mContext.getResources().getDisplayMetrics();

        // 设置窗口尺寸
        mLayoutParams = new WindowManager.LayoutParams(540, 690, 0, 0, PixelFormat.TRANSPARENT);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mLayoutParams.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            mLayoutParams.type = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;
        }
        mLayoutParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL;
        mLayoutParams.format = PixelFormat.RGBA_8888; //窗口透明
        mLayoutParams.gravity = Gravity.TOP;

        mLayoutParams.x = 100;
        mLayoutParams.y = 0;

        rootView = new RelativeLayout(mContext);

        mSurfaceView = new SurfaceView(mContext);
        mSurfaceView.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        mSurfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(@NonNull SurfaceHolder surfaceHolder) {
                if (null != mBindViewReference && null != mBindViewReference.get()) {
                    mBindViewReference.get().getPlayer().setDisplayView(null);
                    mBindViewReference.get().getPlayer().setSurface(null);
                    mBindViewReference.get().getPlayer().setSurface(surfaceHolder.getSurface());
                }
            }

            @Override
            public void surfaceChanged(@NonNull SurfaceHolder surfaceHolder, int i, int i1, int i2) {
                if (null != mBindViewReference && null != mBindViewReference.get()) {
                    mBindViewReference.get().getPlayer().surfaceChanged();
                }
            }

            @Override
            public void surfaceDestroyed(@NonNull SurfaceHolder surfaceHolder) {

            }
        });


        closeButton = new ImageView(mContext);
        backButton = new ImageView(mContext);

        RelativeLayout.LayoutParams closeParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        closeParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT, RelativeLayout.TRUE);
        closeParams.addRule(RelativeLayout.ALIGN_PARENT_TOP, RelativeLayout.TRUE);
        closeParams.setMargins(FlutterAliPlayerUtils.dpToPx(mContext, 5), FlutterAliPlayerUtils.dpToPx(mContext, 5), 0, 0);
        closeButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        closeButton.setLayoutParams(closeParams);


        RelativeLayout.LayoutParams backParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        backParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT, RelativeLayout.TRUE);
        backParams.addRule(RelativeLayout.ALIGN_PARENT_TOP, RelativeLayout.TRUE);
        backParams.setMargins(0, FlutterAliPlayerUtils.dpToPx(mContext, 5), FlutterAliPlayerUtils.dpToPx(mContext, 5), 0);

        backButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        backButton.setLayoutParams(backParams);


        rootView.addView(mSurfaceView);
        rootView.addView(closeButton);
        rootView.addView(backButton);


        initListener();


        //  触摸移动事件
        rootView.setOnTouchListener(new View.OnTouchListener() {

            float initialTouchX;
            float initialTouchY;

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        initialX = mLayoutParams.x;
                        initialY = mLayoutParams.y;
                        initialTouchX = event.getRawX();
                        initialTouchY = event.getRawY();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        mLayoutParams.x = initialX + (int) (event.getRawX() - initialTouchX);
                        mLayoutParams.y = initialY + (int) (event.getRawY() - initialTouchY);
                        mWindowManager.updateViewLayout(rootView, mLayoutParams);
                        return true;
                }
                return false;
            }
        });
    }


    private void initListener() {
        closeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                stopFloatWindow();
            }
        });

        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                backToApp();
            }
        });
    }

    private void backToApp() {
        // 先获取rootView位置信息用于动画
        int[] location = new int[2];
        int x = 0, y = 0, width = 0, height = 0;
        boolean canAnimate = false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && rootView != null && rootView.isAttachedToWindow()) {
            rootView.getLocationOnScreen(location);
            x = location[0];
            y = location[1];
            width = rootView.getWidth();
            height = rootView.getHeight();
            canAnimate = (width > 0 && height > 0);
        }
        hideFloatWindow();

        // 1. 获取启动 Intent
        Intent launchIntent = mContext.getPackageManager().getLaunchIntentForPackage(mContext.getPackageName());
        if (launchIntent == null) {
            logPrint("[backToApp] No launcher activity found!");
            return;
        }

        launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && canAnimate) {
                ActivityOptions options = ActivityOptions.makeScaleUpAnimation(rootView, x, y, width, height);
                mContext.startActivity(launchIntent, options.toBundle());
                return;
            }
            mContext.startActivity(launchIntent);
        } catch (Exception e) {
            try {
                // 二次 fallback：清除 flags 避免 intent 冲突
                launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(launchIntent);
            } catch (Exception ex) {
                logPrint("[backToApp] Fallback startActivity also failed :" + Log.getStackTraceString(ex));
            }
        }
    }


    public void showFloatWindow(FlutterAliPlayerView flutterAliPlayerView) {
        if (null == flutterAliPlayerView) return;

        // 仅当传入的 flutterAliPlayerView 有效时，才更新弱引用
        mBindViewReference = new WeakReference<>(flutterAliPlayerView);

        // 安全使用弱引用：先获取，再判空
        FlutterAliPlayerView playerView = mBindViewReference.get();
        if (playerView != null && playerView.getPlayer() != null) {
            // 播放中状态（状态码 3）
            if (playerView.getPlayer().getPlayerStatus() == 3) {
                int videoWidth = playerView.getPlayer().getVideoWidth();
                int videoHeight = playerView.getPlayer().getVideoHeight();
                int[] videoConfig = calculateWindowSize(videoWidth, videoHeight);
                mLayoutParams.width = videoConfig[0];
                mLayoutParams.height = videoConfig[1];
            }
        }

// 添加悬浮窗（确保只添加一次）
        if (!isViewAdded) {
            mWindowManager.addView(rootView, mLayoutParams);
            isViewAdded = true;
        }
    }


    public int[] calculateWindowSize(int videoWidth, int videoHeight) {
        if (videoWidth <= 0 || videoHeight <= 0) {
            return new int[]{540, 690};
        }

        // 计算宽高比
        float aspectRatio = (float) videoWidth / videoHeight;

        // 视频比例-> 9:16 | 16:9
        // 判断是竖屏还是横屏视频
        int screenWidth = mDisplayMetrics.widthPixels;
        int screenHeight = mDisplayMetrics.heightPixels;

        // === 强制输出宽高比为 16:9 ===
        float targetAspectRatio = 16.0f / 9.0f; // 16:9

        // 设定悬浮窗最大宽度（例如：屏幕宽度的 70%）
        int maxWidth = (int) (screenWidth * 0.7);
        int maxHeight = (int) (screenHeight * 0.7);

        // 初始宽度
        int windowWidth = maxWidth;
        int windowHeight = (int) (windowWidth / targetAspectRatio);

        // 如果高度超过最大限制，按高度反向计算
        if (windowHeight > maxHeight) {
            windowHeight = maxHeight;
            windowWidth = (int) (windowHeight * targetAspectRatio);
        }

        // 可选：设置最小尺寸，避免太小
        int minWidth = 320;  // 至少 320px 宽
        int minHeight = 180; // 至少 180px 高
        if (windowWidth < minWidth || windowHeight < minHeight) {
            windowWidth = minWidth;
            windowHeight = (int) (windowWidth / targetAspectRatio);
            if (windowHeight < minHeight) {
                windowHeight = minHeight;
            }
            windowWidth = (int) (windowHeight * targetAspectRatio);
        }

        if (aspectRatio < 1.0f) {
            // 竖屏视频 (高 > 宽)
            return new int[]{windowHeight, windowWidth};
        } else {
            // 横屏视频 (宽 > 高)
            return new int[]{windowWidth, windowHeight};
        }
    }


    public void hideFloatWindow() {
        // 移除悬浮窗
        if (rootView != null && isViewAdded) {
            try {
                mWindowManager.removeView(rootView);
                isViewAdded = false;
            } catch (IllegalArgumentException e) {
                // 视图已被移除，忽略异常
                isViewAdded = false;
            }
        }

        // 解绑并重置播放器渲染视图
        if (mBindViewReference != null) {
            FlutterAliPlayerView playerView = mBindViewReference.get();
            if (playerView != null) {
                playerView.setRenderView();//绑定自身
            }
            mBindViewReference.clear();
            mBindViewReference = null;
        }
    }


    /**
     * 设置关闭按钮的图标（使用 Drawable 资源）
     *
     * @param drawable 要设置的 Drawable 对象，可为本地资源（如 ContextCompat.getDrawable() 获取）或自定义 Drawable。
     *                 若传入 null，则清除当前图标。
     */
    public void setCloseButtonIcon(Drawable drawable) {
        if (null == drawable) return;
        closeButton.setImageDrawable(drawable);
    }


    /**
     * 设置返回按钮的图标（使用 Drawable 资源）
     *
     * @param drawable 要设置的 Drawable 对象。若为 null，则移除当前图标。
     */
    public void setBackButtonIcon(Drawable drawable) {
        if (null == drawable) return;
        backButton.setImageDrawable(drawable);
    }

    public void setUIVisible(boolean isEnable) {
        if (null != backButton) {
            backButton.setVisibility(isEnable ? View.VISIBLE : View.GONE);
        }
        if (null != closeButton) {
            closeButton.setVisibility(isEnable ? View.VISIBLE : View.GONE);
        }
    }


    private void logPrint(String text) {
        Log.d("AliFrameWork", "[Flutter][FlutterAliFloatWindowManager][log]" + text);
    }


    // 暂停播放，并退出悬浮窗
    private void stopFloatWindow() {
        if (null != mBindViewReference && null != mBindViewReference.get()) {
            mBindViewReference.get().getPlayer().pause();
        }
        hideFloatWindow();
    }


    public void destroy() {
        mSurfaceView = null;

        rootView = null;

        closeButton = null;
        backButton = null;

        mContext = null;
    }

}
