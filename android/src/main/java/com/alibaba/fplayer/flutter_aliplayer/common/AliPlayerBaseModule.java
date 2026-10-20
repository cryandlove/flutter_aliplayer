package com.alibaba.fplayer.flutter_aliplayer.common;

import android.util.Log;

import com.alibaba.fplayer.flutter_aliplayer.listener.OnModuleLifeListener;

import java.util.Locale;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/**
 * 阿里播放器通用模块基类
 *
 * <p>该抽象类封装了 Flutter 插件中 MethodChannel 和 EventChannel 的标准生命周期管理，
 * 并实现了 {@link OnModuleLifeListener}、{@link MethodChannel.MethodCallHandler}
 * 和 {@link EventChannel.StreamHandler} 接口，用于统一处理原生与 Flutter 之间的通信。
 *
 * <p>子类必须实现两个抽象方法：
 * <ul>
 *   <li>{@link #buildMethodChannel()}：返回 MethodChannel 的唯一标识符（channel name）</li>
 *   <li>{@link #buildEventChannel()}：返回 EventChannel 的唯一标识符（channel name）</li>
 * </ul>
 *
 * <p>该类自动处理通道的创建、绑定、解绑和事件发送，开发者只需关注业务逻辑实现。
 */
public abstract class AliPlayerBaseModule implements OnModuleLifeListener,
        MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    /**
     * 是否开启调试日志模式，默认为 false
     * 在 release 版本中建议设为 false 以避免敏感信息泄露和性能损耗
     */
    private boolean isDebugMode = false;

    /**
     * Flutter 与原生通信的 MethodChannel 实例
     * 用于接收来自 Dart 端的方法调用请求
     */
    protected MethodChannel mMethodChannel;

    /**
     * Flutter 与原生通信的 EventChannel 实例
     * 用于向 Dart 端推送异步事件流（如播放状态、错误通知等）
     */
    protected EventChannel mEventChannel;

    /**
     * EventChannel 的事件发送器（EventSink）
     * 用于向 Flutter 端发送成功、错误或完成事件
     * <p>
     * 注意：仅在 {@link #onListen(Object, EventChannel.EventSink)} 被调用后有效，
     * 在 {@link #onCancel(Object)} 被调用后应置为 null，避免向已取消的监听器发送事件。
     */
    protected EventChannel.EventSink mEventSink;

    /**
     * 当模块被附加到 Flutter 引擎时调用
     *
     * <p>在此方法中完成以下初始化工作：
     * <ul>
     *   <li>根据子类提供的 channel 名称创建 MethodChannel 和 EventChannel</li>
     *   <li>将当前对象注册为 MethodCallHandler 和 StreamHandler</li>
     * </ul>
     *
     * @param binding {@link FlutterPlugin.FlutterPluginBinding} 对象，
     *                提供 BinaryMessenger（用于创建通道）和 ApplicationContext 等上下文信息
     */
    @Override
    public void onAttachedToModule(FlutterPlugin.FlutterPluginBinding binding) {
        // 创建 MethodChannel 并绑定方法调用处理器（即当前对象）
        mMethodChannel = new MethodChannel(binding.getBinaryMessenger(), buildMethodChannel());
        mMethodChannel.setMethodCallHandler(this);

        // 创建 EventChannel 并绑定流处理器（即当前对象）
        mEventChannel = new EventChannel(binding.getBinaryMessenger(), buildEventChannel());
        mEventChannel.setStreamHandler(this);
    }

    /**
     * 当模块从 Flutter 引擎分离时调用
     *
     * <p>在此方法中执行资源清理，防止内存泄漏：
     * <ul>
     *   <li>解除 MethodChannel 的方法调用处理器</li>
     *   <li>解除 EventChannel 的流处理器</li>
     *   <li>将通道引用置为 null，便于垃圾回收</li>
     * </ul>
     *
     * <p><strong>重要：</strong>此方法调用后，不应再向 mEventSink 发送任何事件。
     *
     * @param binding {@link FlutterPlugin.FlutterPluginBinding} 对象，
     *                与 onAttachedToModule 中的参数一致
     */
    @Override
    public void onDetachedFromModule(FlutterPlugin.FlutterPluginBinding binding) {
        // 清理 MethodChannel
        if (mMethodChannel != null) {
            mMethodChannel.setMethodCallHandler(null);
            mMethodChannel = null;
        }

        // 清理 EventChannel
        if (mEventChannel != null) {
            mEventChannel.setStreamHandler(null);
            mEventChannel = null;
        }

        // 注意：mEventSink 会在 onCancel 中置为 null，此处无需重复处理
    }

    /**
     * 当 Flutter 端开始监听 EventChannel 时调用
     *
     * <p>Flutter 端调用 stream.listen() 时触发此回调。
     * 此时应保存 {@code events} 引用，以便后续通过它向 Dart 端发送事件。
     *
     * @param arguments 从 Flutter 端传入的监听参数（可为 null）
     * @param events    事件发送器，用于向 Flutter 端推送数据
     */
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        loge("[onListen] " + events);
        mEventSink = events; // 保存 EventSink 供后续使用
    }

    /**
     * 当 Flutter 端取消监听 EventChannel 时调用
     *
     * <p>Flutter 端调用 subscription.cancel() 或 dispose stream 时触发。
     * 此时应停止所有事件推送，并将 mEventSink 置为 null，避免向已取消的监听器发送事件。
     *
     * @param arguments 从 Flutter 端传入的取消参数（通常为 null）
     */
    @Override
    public void onCancel(Object arguments) {
        loge("[onCancel]" + arguments);
        mEventSink = null; // 清空引用，防止误发事件
    }

    /**
     * 子类必须实现此方法，提供 MethodChannel 的唯一标识符
     *
     * <p>该字符串必须与 Dart 端 MethodChannel 的 name 严格一致
     *
     * @return MethodChannel 的名称（例如："com.example/player_method"）
     */
    protected abstract String buildMethodChannel();

    /**
     * 子类必须实现此方法，提供 EventChannel 的唯一标识符
     *
     * <p>该字符串必须与 Dart 端 EventChannel 的 name 严格一致
     *
     * @return EventChannel 的名称（例如："com.example/player_event"）
     */
    protected abstract String buildEventChannel();

    /**
     * 开启调试日志模式
     *
     * <p>调用此方法后，所有通过 {@link #loge(String)} 输出的日志将被打印到 Logcat
     * 建议仅在开发阶段启用
     */
    protected void openDebugMode() {
        isDebugMode = true;
    }

    /**
     * 向 Flutter 端发送成功事件
     *
     * <p>仅在 mEventSink 不为 null 时发送（即 Flutter 端正在监听）
     *
     * @param event 要发送的数据对象（可为任意可序列化类型）
     */
    protected void sendSuccessEvent(Object event) {
        if (null != mEventSink) {
            loge("success to sendSuccessEvent");
            mEventSink.success(event);
        } else {
            loge("fail to sendSuccessEvent: EventSink = null");
        }
    }

    /**
     * 向 Flutter 端发送错误事件
     *
     * <p>仅在 mEventSink 不为 null 时发送（即 Flutter 端正在监听）
     *
     * @param errorCode   错误码（非空字符串）
     * @param errorMsg    错误描述信息
     * @param errorDetail 错误详情（可为 null）
     */
    protected void sendErrorEvent(String errorCode, String errorMsg, Object errorDetail) {
        if (null != mEventSink) {
            loge("success to sendErrorEvent");
            mEventSink.error(errorCode, errorMsg, errorDetail);
        } else {
            loge("fail to sendErrorEvent: EventSink = null");
        }
    }

    /**
     * 条件性输出错误日志
     *
     * <p>仅在调试模式开启时，将日志打印到 Android Logcat 的 ERROR 级别
     *
     * @param log 要输出的日志内容
     */
    protected void loge(String log) {
        if (!isDebugMode) return;
        // 获取调用栈信息
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();

        // stackTrace[0] = getStackTrace()
        // stackTrace[1] = e()
        // stackTrace[2] = 调用者方法
        if (stackTrace.length > 3) {
            StackTraceElement caller = stackTrace[2];
            String className = caller.getClassName();
            String methodName = caller.getMethodName();
            int lineNumber = caller.getLineNumber();

            // 提取简单类名（去掉包名）
            String simpleClassName = className.substring(className.lastIndexOf(".") + 1);

            String logMessage = String.format(Locale.getDefault(),"[%s.%s():%d] %s",
                    simpleClassName, methodName, lineNumber, log);

            Log.e(simpleClassName, logMessage);
        } else {
            Log.e("Logger", log);
        }
    }
}

