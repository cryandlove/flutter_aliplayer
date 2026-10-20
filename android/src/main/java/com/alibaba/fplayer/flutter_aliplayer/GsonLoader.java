package com.alibaba.fplayer.flutter_aliplayer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.ToNumberPolicy;

/**
 * Gson 单例
 */
public class GsonLoader {
    private static volatile Gson instance;

    private GsonLoader() {
    }

    public static Gson getInstance() {
        if (instance == null) {
            synchronized (GsonLoader.class) {
                if (instance == null) {
                    instance = new GsonBuilder()
                            .setNumberToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)  //数据转换策略 防止 int 转为 double
                            .setObjectToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)  //数据转换策略 防止 int 转为 double
                            .serializeNulls()
                            .create();
                }
            }
        }
        return instance;
    }
}
