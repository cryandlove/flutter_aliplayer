package com.alibaba.fplayer.flutter_aliplayer;

import java.util.concurrent.ConcurrentHashMap;

import io.flutter.plugin.common.BasicMessageChannel;

/**
 * 管理 Flutter BasicMessageChannel 的线程安全池。
 * 用于避免重复创建通道，并在不再需要时正确解绑消息处理器，防止内存泄漏。
 */
public class AliChannelPool {

    private final ConcurrentHashMap<String, BasicMessageChannel<String>> channels = new ConcurrentHashMap<>();

    // 静态内部类实现线程安全的单例（推荐方式）
    private static class Holder {
        static final AliChannelPool INSTANCE = new AliChannelPool();
    }

    private AliChannelPool() {
        // 私有构造，防止外部实例化
    }

    public static AliChannelPool getInstance() {
        return Holder.INSTANCE;
    }

    /**
     * 添加通道（如果 key 不存在则添加）
     */
    public void addChannel(String key, BasicMessageChannel<String> channel) {
        if (key == null || channel == null) {
            return;
        }
        channels.putIfAbsent(key, channel);
    }

    /**
     * 移除并正确释放指定 key 的通道
     */
    public void removeChannel(String key) {
        if (key == null) {
            return;
        }
        BasicMessageChannel<String> channel = channels.remove(key);
        if (channel != null) {
            // 关键：解除消息处理器绑定，防止回调到已销毁的上下文（如 Activity）
            channel.setMessageHandler(null);
        }
    }

    /**
     * 检查是否包含指定 key 的通道
     */
    public boolean containsChannel(String key) {
        if (key == null) {
            return false;
        }
        return channels.containsKey(key);
    }

    /**
     * 根据 key 获取通道（可能为 null）
     */
    public BasicMessageChannel<String> channelForKey(String key) {
        if (key == null) {
            return null;
        }
        return channels.get(key);
    }

    /**
     * 清空所有通道并释放资源
     */
    public void clear() {
        for (BasicMessageChannel<String> channel : channels.values()) {
            if (channel != null) {
                channel.setMessageHandler(null);
            }
        }
        channels.clear();
    }
}
