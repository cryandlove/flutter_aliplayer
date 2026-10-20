//
//  FlutterAliMediaLoaderV2.m
//  flutter_aliplayer
//
//  Created by aqi on 2025/10/29.
//

#import "FlutterAliMediaLoaderV2.h"


#if __has_include(<AliVCSDK_Standard/AliVCSDK_Standard.h>)
#import <AliVCSDK_Standard/AliVCSDK_Standard.h>

#elif __has_include(<AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>)
#import <AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>
#import <AliVCSDK_InteractiveLive/AliMediaLoaderV2.h>
#import <AliVCSDK_InteractiveLive/AVPPreloadTask.h>

#elif __has_include(<AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>)
#import <AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>

#elif __has_include(<AliVCSDK_UGC/AliVCSDK_UGC.h>)
#import <AliVCSDK_UGC/AliVCSDK_UGC.h>

#endif

#if __has_include(<RtsSDK/RtsSDK.h>)
#define RTS_SUPPORT
#import <RtsSDK/RtsSDK.h>
#endif

#if __has_include(<AliyunPlayer/AliyunPlayer.h>)
#import <AliyunPlayer/AliyunPlayer.h>
#import <AliyunPlayer/AliMediaLoaderV2.h>
#import <AliyunPlayer/AVPPreloadTask.h>

#endif
#import "NSDictionary+ext.h"
#define kAliPlayerMethod    @"method"

@interface FlutterAliMediaLoaderV2 ()<FlutterStreamHandler, OnPreloadListener>

@property (nonatomic, copy) FlutterEventSink eventSink;
@property (nonatomic, strong) AliMediaLoaderV2 *mediaLoader;
@property (nonatomic, strong) AVPPreloadConfig *config;

@end

@implementation FlutterAliMediaLoaderV2


#pragma mark - FlutterPlugin

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.flutter_aliplayer_loader_v2"
                                     binaryMessenger:[registrar messenger]];
    
    FlutterAliMediaLoaderV2* instance = [[FlutterAliMediaLoaderV2 alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"flutter_aliplayer_loader_v2_event" binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];

}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* method = [call method];
    SEL methodSel=NSSelectorFromString([NSString stringWithFormat:@"%@:",method]);
    NSArray *arr = @[call,result];
    if([self respondsToSelector:methodSel]){
        IMP imp = [self methodForSelector:methodSel];
        CGRect (*func)(id, SEL, NSArray*) = (void *)imp;
        func(self, methodSel, arr);
    }else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self.mediaLoader = nil;
    self.config = nil;
}


#pragma mark - FlutterStreamHandler

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)eventSink{
    self.eventSink = eventSink;
    return nil;
}
 
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

#pragma mark - OnPreloadListener

- (void)onError:(NSString *)taskId urlOrVid:(NSString *)urlOrVid errorModel:(AVPErrorModel *)errorModel {
    if (self.eventSink) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[kAliPlayerMethod] = @"onError";
        dict[@"taskId"] = taskId;
        dict[@"urlOrVid"] = urlOrVid;
        dict[@"errorCode"] = [NSString stringWithFormat:@"%ld", errorModel.code];
        if (errorModel.message) {
            dict[@"errorMsg"] = errorModel.message;
        }
        if (errorModel.extra) {
            dict[@"errorExtra"] = errorModel.extra;
        } else {
            dict[@"errorExtra"] = [NSNull null]; // 或者干脆不设置，取决于接收端是否要求字段存在
        }
        self.eventSink(dict);
    }
    
   
}

- (void)onCompleted:(NSString *)taskId urlOrVid:(NSString *)urlOrVid {
    self.eventSink(@{
        kAliPlayerMethod : @"onCompleted",
        @"taskId" : taskId,
        @"urlOrVid" : urlOrVid,
    });
}


- (void)onCanceled:(NSString *)taskId urlOrVid:(NSString *)urlOrVid {
    self.eventSink(@{
        kAliPlayerMethod : @"onCanceled",
        @"taskId" : taskId,
        @"urlOrVid" : urlOrVid,
    });
}


/**
 * @brief 处理来自 Flutter 的预加载任务请求，构建并添加一个媒体预加载任务。
 *
 * 该方法从 Flutter 传入的参数中解析视频类型及其他配置信息，
 * 构建对应的 AVPPreloadTask 对象，并通过 mediaLoader 添加到预加载队列中。
 * 任务添加成功后，将生成的任务 ID 回传给 Flutter 端。
 *
 * @param arr 包含两个元素的数组：
 *            - 第一个元素为 FlutterMethodCall 对象，包含调用的方法名和参数；
 *            - 第二个元素为 FlutterResult 回调 block，用于向 Flutter 返回结果。
 */
- (void)addTask:(NSArray*)arr {
    // 从参数数组中提取 Flutter 方法调用对象和结果回调
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    
    // 移除参数字典中的 NSNull 值，避免后续处理出错
    NSDictionary<NSString *, id> *dataMap = [call.arguments removeNull];
    
    // 检查参数是否有效且非空
    if (dataMap != nil && dataMap.count > 0) {
        // 获取视频类型参数（videoType），默认为 0
        id obj = dataMap[@"videoType"];
        NSInteger videoType = 0;
        
        // 安全地将 NSNumber 转换为 NSInteger
        if ([obj isKindOfClass:[NSNumber class]]) {
            videoType = [obj integerValue];
        }
        
        // 根据视频类型和参数构建预加载任务对象
        AVPPreloadTask* preloadTask = [self buildPreloadTask:videoType dataMap:dataMap];
        
        // 将任务添加到媒体加载器中，并注册当前对象为监听器
        // 返回的任务 ID 用于后续任务管理（如取消、查询状态等）
        NSString* taskId = [self.mediaLoader addTask:preloadTask listener:self];
        
        // 将任务 ID 通过 FlutterResult 回传给 Dart 侧
        result(taskId);
    }
}

- (void)pauseTask:(NSArray*)arr {
    // 从参数数组中提取 Flutter 方法调用对象和结果回调
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
        NSDictionary* args = (NSDictionary*)call.arguments;
        
        // 提取 taskId
        NSString* taskId = args[@"taskId"];
        [self.mediaLoader pauseTask:taskId];
        
        
    }
    result(nil);
}

- (void)resumeTask:(NSArray*)arr {
    // 从参数数组中提取 Flutter 方法调用对象和结果回调
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
        NSDictionary* args = (NSDictionary*)call.arguments;
        
        // 提取 taskId
        NSString* taskId = args[@"taskId"];
        
        [self.mediaLoader resumeTask:taskId];
    }
    result(nil);
}


- (void)cancelTask:(NSArray*)arr {
    // 从参数数组中提取 Flutter 方法调用对象和结果回调
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
        NSDictionary* args = (NSDictionary*)call.arguments;
        
        // 提取 taskId
        NSString* taskId = args[@"taskId"];
        
        [self.mediaLoader cancelTask:taskId];
    }
    result(nil);
}

- (void)getPreloadConfig:(NSArray*)arr {
    FlutterResult result = arr[1];
    
    [self buildPreloadConfig];
    
    NSMutableDictionary<NSString*, id> *dict = [NSMutableDictionary dictionary];
    dict[@"duration"] = @([self.config getDuration]);
    dict[@"defaultBandWidth"] = @([self.config getDefaultBandWidth]);
    dict[@"defaultResolution"] = @([self.config getDefaultResolution]);
    
    if ([self.config getDefaultQuality]){
        dict[@"defaultQuality"] = [self.config getDefaultQuality];
    }
    
    result(dict);
}

- (void)setPreloadConfig:(NSArray*)arr {
    // 从参数数组中提取 Flutter 方法调用对象和结果回调
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    
    [self buildPreloadConfig];
    
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
        NSDictionary<NSString* ,id>* args = (NSDictionary*)call.arguments;
        
        // 假设 args 是 NSDictionary*

        // 安全提取 duration
        if ([args objectForKey:@"duration"]) {
            [self.config setDuration:[args[@"duration"] intValue]];
        }
        
        // 安全提取 defaultBandWidth
        if ([args objectForKey:@"defaultBandWidth"]) {
            [self.config setDefaultBandWidth:[args[@"defaultBandWidth"] intValue]];
        }

        // 安全提取 defaultResolution
        if ([args objectForKey:@"defaultResolution"]) {
            [self.config setDefaultResolution:[args[@"defaultResolution"] intValue]];
        }
        
        if ([args objectForKey:@"defaultQuality"]){
            [self.config setDefaultQuality:args[@"defaultQuality"]];
        }
       
    }
    result(nil);
}

- (void)resetPreloadConfig:(NSArray*)arr {
    FlutterResult result = arr[1];
    self.config = [[AVPPreloadConfig alloc]initWithDuration:1000];
    result(nil);
}


- (AVPPreloadTask *)buildPreloadTask:(NSInteger)type dataMap:(NSDictionary<NSString *, id> *)dataMap {
    __weak __typeof__(self) weakSelf = self;
    switch (type) {
        case 0:{
            AVPUrlSource* urlSource = [[AVPUrlSource alloc]urlWithString:dataMap[@"videoUrl"]];
            AVPPreloadTask* task = [[AVPPreloadTask alloc] initWithUrlSource:urlSource preloadConfig:[weakSelf buildPreloadConfig]];
            return task;
        }
            break;
        case 1:{
            AVPVidAuthSource* vidAuthSource = [[AVPVidAuthSource alloc]init];
            [vidAuthSource setVid:dataMap[@"vid"]];
            [vidAuthSource setPlayAuth:dataMap[@"playAuth"]];
            
            if ([dataMap objectForKey:@"region"]){
                [vidAuthSource setRegion:dataMap[@"region"]];
                
            }
            
            [self setSourceConfig:dataMap sourceBase:vidAuthSource];
            
            AVPPreloadTask* task = [[AVPPreloadTask alloc] initWithVidAuthSource:vidAuthSource preloadConfig:[weakSelf buildPreloadConfig]];
            return task;
            
        }
            break;
        case 2:{
            AVPVidStsSource* vidStsSource = [[AVPVidStsSource alloc]init];
            [vidStsSource setVid:dataMap[@"vid"]];
            [vidStsSource setSecurityToken:dataMap[@"securityToken"]];
            [vidStsSource setAccessKeyId:dataMap[@"accessKeyId"]];
            [vidStsSource setAccessKeySecret:dataMap[@"accessKeySecret"]];
            
            if ([dataMap objectForKey:@"region"]){
                [vidStsSource setRegion:dataMap[@"region"]];
            }
            
            [self setSourceConfig:dataMap sourceBase:vidStsSource];
            
            AVPPreloadTask* task = [[AVPPreloadTask alloc] initWithVidStsSource:vidStsSource preloadConfig:[weakSelf buildPreloadConfig]];
            return task;
        }
        default:
            break;
    }
    
    return nil;
}


- (void)setSourceConfig:(NSDictionary<NSString *, id> *)dataMap
             sourceBase:(id)sourceBase {
    
    if ([dataMap objectForKey:@"config"] != nil) {
        NSDictionary<NSString *, id> *configMap = [dataMap objectForKey:@"config"];
        
        if (configMap != nil && configMap.count > 0 && [configMap objectForKey:@"type"]) {
            id typeObj = [configMap objectForKey:@"type"];
            
            // 检查 type 是否为 NSNumber（Flutter 传递的整数在 iOS 中是 NSNumber）
            if ([typeObj isKindOfClass:[NSNumber class]]) {
                
                NSInteger type = [typeObj integerValue];
                VidPlayerConfigGenerator *configGen = nil;
                
                switch (type) {
                    case 1: {
                        // 私有加密
                        configGen = [[VidPlayerConfigGenerator alloc] init];
                        [configGen addVidPlayerConfigByStringValue:@"EncryptType" value:@"AliyunVoDEncryption"];
                        break;
                    }
                    case 2: {
                        // 标准加密
                        configGen = [[VidPlayerConfigGenerator alloc] init];
                        [configGen addVidPlayerConfigByStringValue:@"EncryptType" value:@"HLSEncryption"];
                        
                        if ([configMap objectForKey:@"hlsUriToken"] != nil) {
                            NSString *hlsUriToken = [configMap objectForKey:@"hlsUriToken"];
                            if ([hlsUriToken isKindOfClass:[NSString class]]) {
                                [configGen setHlsUriToken: hlsUriToken];
                            }
                        }
                        break;
                    }
                    default:
                        break;
                }
                
                if (configGen != nil && sourceBase != nil) {
                    
                    if ([sourceBase isKindOfClass:[AVPVidAuthSource class]]) {
                        AVPVidAuthSource* vidAuth = (AVPVidAuthSource *) sourceBase;
                        vidAuth.playConfig = [configGen generatePlayerConfig];
                    }
                    
                    if ([sourceBase isKindOfClass:[AVPVidStsSource class]]) {
                        AVPVidStsSource* vidSts = (AVPVidStsSource *) sourceBase;
                        vidSts.playConfig = [configGen generatePlayerConfig];
                    }
                }
            }
        }
    }
}


- (AVPPreloadConfig *)buildPreloadConfig {
    if (!self.config){
        self.config = [[AVPPreloadConfig alloc]initWithDuration:1000];
    }
    
    return self.config;
}

#pragma mark -- lazy load
- (AliMediaLoaderV2 *)mediaLoader {
    if (!_mediaLoader) {
        _mediaLoader = [AliMediaLoaderV2 shareInstance];
    }
    return _mediaLoader;
}


@end
