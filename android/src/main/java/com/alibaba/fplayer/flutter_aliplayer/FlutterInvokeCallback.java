package com.alibaba.fplayer.flutter_aliplayer;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;

/**
 * @author junhuiYe
 * @date 2024/12/25
 * @brief
 */
public class FlutterInvokeCallback {
    private BasicMessageChannel<String> mBasicMessageChannel;
    private Context mContext;
    private final String TAG = "FlutterInvoke";
    private static final Handler sMainHandler = new Handler(Looper.getMainLooper());
    private FlutterPlugin.FlutterPluginBinding flutterPluginBinding;

    public FlutterInvokeCallback(Context context, FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        this.mContext = context;
        this.flutterPluginBinding = flutterPluginBinding;
    }

    // 在 Flutter 中，所有与 Flutter 框架的直接交互（包括通过 MethodChannel 发起的通信）都必须在主线程（UI 线程）上执行。这是为了确保对 UI 的安全访问。
    // Methods marked with @UiThread must be executed on the main thread
    public void runOnUiThread(Runnable runnable) {
        // 检查当前线程是否是主线程
        if (Thread.currentThread() == Looper.getMainLooper().getThread()) {
            // 如果是主线程，直接执行
            runnable.run();
        } else {
            // 如果不在主线程，post 到主线程
            sMainHandler.post(runnable);
        }
    }

    public Object invokeOneParameterFlutterCallback(Object s1, String channelName) {
        this.mBasicMessageChannel = new BasicMessageChannel<>(flutterPluginBinding.getBinaryMessenger(), channelName, StringCodec.INSTANCE);
        this.mBasicMessageChannel.setMessageHandler(((message, reply) -> {
            Log.w(TAG, "[D->F] setMessageHandler, message: " + message + ", reply: " + reply);
            reply.reply(null);
        }));

        final Object[] holder = {null};

        // 创建 CountDownLatch 用于同步
        CountDownLatch latch = new CountDownLatch(1);

        Log.i(TAG, "[F->D] invokeFlutterCallback: " + s1);

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final String arguments = String.format("{\"param1\": \"%s\"}", s1);
                mBasicMessageChannel.send(arguments, new BasicMessageChannel.Reply<String>() {
                    @Override
                    public void reply(@Nullable String reply) {
                        Log.w(TAG, "[D->F] invokeFlutterCallback reply: " + reply);
                        holder[0] = reply;
                        latch.countDown(); // 计数器减一，释放锁
                    }
                });
            }
        });

        Log.i(TAG, "[F->D] invokeFlutterCallback await response...");

        // 检查当前线程是否是主线程
        if (Thread.currentThread() != Looper.getMainLooper().getThread()) {
            try {
                boolean await = latch.await(10, TimeUnit.MILLISECONDS);// 等待 Flutter 返回结果, 不会阻塞主线程
                if (!await) {
                    mBasicMessageChannel.setMessageHandler(null);
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            Log.e(TAG, "[F->D] invokeFlutterCallback cannot synchronize and wait for execution on the main thread...");
        }

        Log.i(TAG, "[F->D] invokeFlutterCallback with response: " + holder[0]);

        return holder[0];
    }

    public Object invokeTwoParameterFlutterCallback(Object obj1, Object obj2, String channelName) {
        this.mBasicMessageChannel = new BasicMessageChannel<>(flutterPluginBinding.getBinaryMessenger(), channelName, StringCodec.INSTANCE);
        this.mBasicMessageChannel.setMessageHandler(((message, reply) -> {
            Log.w(TAG, "[D->F] setMessageHandler, message: " + message + ", reply: " + reply);
            reply.reply(null);
        }));

        final Object[] holder = {null};

        // 创建 CountDownLatch 用于同步
        CountDownLatch latch = new CountDownLatch(1);

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final String arguments = String.format("{\"param1\": \"%s\", \"param2\": \"%s\"}",
                        obj1, obj2);
                mBasicMessageChannel.send(arguments, new BasicMessageChannel.Reply<String>() {
                    @Override
                    public void reply(@Nullable String reply) {
                        Log.w(TAG, "[D->F] invokeFlutterCallback reply: " + reply);
                        holder[0] = reply;
                        latch.countDown(); // 计数器减一，释放锁
                    }
                });
            }
        });

        Log.i(TAG, "[F->D] invokeFlutterCallback await response...");

        // 检查当前线程是否是主线程
        if (Thread.currentThread() != Looper.getMainLooper().getThread()) {
            try {
                boolean await = latch.await(10, TimeUnit.MILLISECONDS);// 等待 Flutter 返回结果, 不会阻塞主线程
                if (!await) {
                    mBasicMessageChannel.setMessageHandler(null);
                } // 等待 Flutter 返回结果, 不会阻塞主线程
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            Log.e(TAG, "[F->D] invokeFlutterCallback cannot synchronize and wait for execution on the main thread...");
        }

        Log.i(TAG, "[F->D] invokeFlutterCallback with response: " + holder[0]);

        return holder[0];
    }

    public Object invokeThreeParameterFlutterCallback(Object obj1, Object obj2, Object obj3, String channelName) {
        this.mBasicMessageChannel = new BasicMessageChannel<>(flutterPluginBinding.getBinaryMessenger(), channelName, StringCodec.INSTANCE);
        this.mBasicMessageChannel.setMessageHandler(((message, reply) -> {
            Log.w(TAG, "[D->F] setMessageHandler, message: " + message + ", reply: " + reply);
            reply.reply(null);
        }));

        final Object[] holder = {null};

        // 创建 CountDownLatch 用于同步
        CountDownLatch latch = new CountDownLatch(1);

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final String arguments = String.format("{\"param1\": \"%s\", \"param2\": \"%s\",\"param3\": \"%s\"}",
                        obj1, obj2, obj3);
                mBasicMessageChannel.send(arguments, new BasicMessageChannel.Reply<String>() {
                    @Override
                    public void reply(@Nullable String reply) {
                        Log.w(TAG, "[D->F] invokeFlutterCallback reply: " + reply);
                        holder[0] = reply;
                        latch.countDown(); // 计数器减一，释放锁
                    }
                });
            }
        });

        Log.i(TAG, "[F->D] invokeFlutterCallback await response...");

        // 检查当前线程是否是主线程
        if (Thread.currentThread() != Looper.getMainLooper().getThread()) {
            try {
                boolean await = latch.await(10, TimeUnit.MILLISECONDS);// 等待 Flutter 返回结果, 不会阻塞主线程
                if (!await) {
                    mBasicMessageChannel.setMessageHandler(null);
                } // 等待 Flutter 返回结果, 不会阻塞主线程
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            Log.e(TAG, "[F->D] invokeFlutterCallback cannot synchronize and wait for execution on the main thread...");
        }

        Log.i(TAG, "[F->D] invokeFlutterCallback with response: " + holder[0]);

        return holder[0];
    }

    public Object invokeFourParameterFlutterCallback(Object obj1, Object obj2, Object obj3, Object obj4, String channelName) {
        this.mBasicMessageChannel = new BasicMessageChannel<>(flutterPluginBinding.getBinaryMessenger(), channelName, StringCodec.INSTANCE);
        this.mBasicMessageChannel.setMessageHandler(((message, reply) -> {
            Log.w(TAG, "[D->F] setMessageHandler, message: " + message + ", reply: " + reply);
            reply.reply(null);
        }));

        final Object[] holder = {null};

        // 创建 CountDownLatch 用于同步
        CountDownLatch latch = new CountDownLatch(1);

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final String arguments = String.format("{\"param1\": \"%s\", \"param2\": \"%s\",\"param3\": \"%s\",\"param4\": \"%s\"}",
                        obj1, obj2, obj3, obj4);
                mBasicMessageChannel.send(arguments, new BasicMessageChannel.Reply<String>() {
                    @Override
                    public void reply(@Nullable String reply) {
                        Log.w(TAG, "[D->F] invokeFlutterCallback reply: " + reply);
                        holder[0] = Boolean.parseBoolean(reply);
                        latch.countDown(); // 计数器减一，释放锁
                    }
                });
            }
        });

        Log.i(TAG, "[F->D] invokeFlutterCallback await response...");

        // 检查当前线程是否是主线程
        if (Thread.currentThread() != Looper.getMainLooper().getThread()) {
            try {
                boolean await = latch.await(10, TimeUnit.MILLISECONDS);// 等待 Flutter 返回结果, 不会阻塞主线程
                if (!await) {
                    mBasicMessageChannel.setMessageHandler(null);
                } // 等待 Flutter 返回结果, 不会阻塞主线程
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            Log.e(TAG, "[F->D] invokeFlutterCallback cannot synchronize and wait for execution on the main thread...");
        }

        Log.i(TAG, "[F->D] invokeFlutterCallback with response: " + holder[0]);

        return holder[0];
    }
}
