#import "FlutterAliPlayerGlobalSettings.h"
#import "NSDictionary+ext.h"
#import "AliPlayerFactory.h"
#import "AliChannelPool.h"

#if __has_include(<AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>)
#import <AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>
#else
#import <AliyunPlayer/AliyunPlayer.h>
#endif

#define ChannelBackUp        @"getBackupUrlCallback"
#define ChannelNetData       @"onNetworkDataProcess"
#define ChannelCacheUrlHash       @"getUrlHashCallback"

@interface FlutterAliPlayerGlobalSettings ()<FlutterStreamHandler>{
    NSString *mSavePath;
    NSString *mSaveKeyPath;
}

@property(strong,nonatomic) NSMutableDictionary * mAliPlayerGlobalSettingsMap;
@property(strong,nonatomic) NSMutableDictionary * mProxyMap;
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) AlivcEnv *alivcEnv;

@end

@implementation FlutterAliPlayerGlobalSettings

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.flutter_global_setting"
                                     binaryMessenger:[registrar messenger]];
    FlutterAliPlayerGlobalSettings* instance = [[FlutterAliPlayerGlobalSettings alloc] init];
    instance.mAliPlayerGlobalSettingsMap = @{}.mutableCopy;
    instance.mProxyMap = @{}.mutableCopy;
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"plugins.flutter_global_setting_event" binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
    
    FlutterBasicMessageChannel* backUpChannel = [[FlutterBasicMessageChannel alloc]initWithName:ChannelBackUp binaryMessenger:[registrar messenger] codec:[FlutterStringCodec sharedInstance]];
    FlutterBasicMessageChannel* networkCallbackChannel = [[FlutterBasicMessageChannel alloc]initWithName:ChannelNetData binaryMessenger:[registrar messenger] codec:[FlutterStringCodec sharedInstance]];
    
    FlutterBasicMessageChannel *cacheUrlHashChannel = [[FlutterBasicMessageChannel alloc]initWithName:ChannelCacheUrlHash binaryMessenger:[registrar messenger] codec:[FlutterStringCodec sharedInstance]];
    
    [[AliChannelPool sharedManager] addChannel:backUpChannel forKey:ChannelBackUp];
    [[AliChannelPool sharedManager] addChannel:networkCallbackChannel forKey:ChannelNetData];
    [[AliChannelPool sharedManager] addChannel:cacheUrlHashChannel forKey:ChannelCacheUrlHash];
}

#pragma mark - FlutterStreamHandler
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)eventSink{
    self.eventSink = eventSink;
    return nil;
}
 
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
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

- (void)setGlobalEnvironment:(NSArray *)arr {
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    NSNumber *config = call.arguments;
    if(config.intValue == 1){
        AlivcBase.EnvironmentManager.globalEnvironment = AlivcGlobalEnv_CN;
    }else if (config.intValue == 2){
        AlivcBase.EnvironmentManager.globalEnvironment = AlivcGlobalEnv_SEA;
    }else{
        AlivcBase.EnvironmentManager.globalEnvironment = AlivcGlobalEnv_GLOBAL_DEFAULT;
    }
    result(nil);
}

- (void)setOption:(NSArray *)arr {
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    NSDictionary *dic = call.arguments;
    NSNumber *opt1 = dic[@"opt1"];
    NSObject *opt2 = dic[@"opt2"];
    if ([opt2 isKindOfClass:[NSNumber class]]) {
        NSNumber * optInt = ( NSNumber *)opt2;
        [AliPlayerGlobalSettings setOption:opt1.intValue valueInt:optInt.intValue];
    }else if ([opt2 isKindOfClass:[NSString class]]) {
        NSString * optVal = ( NSString *)opt2;
        [AliPlayerGlobalSettings setOption:opt1.intValue value:optVal];
    }
    result(nil);
}

- (void)disableCrashUpload:(NSArray *)arr {
    FlutterResult result = arr[1];
    FlutterMethodCall *call = arr.firstObject;
    NSNumber *val = [call arguments];
    [AliPlayerGlobalSettings disableCrashUpload:val.boolValue];
    result(nil);
}

- (void)enableEnhancedHttpDns:(NSArray *)arr {
    FlutterResult result = arr[1];
    FlutterMethodCall *call = arr.firstObject;
    NSNumber *val = [call arguments];
    [AliPlayerGlobalSettings enableEnhancedHttpDns:val.boolValue];
    result(nil);
}

/**
 * @method 设置系统亮度
 */
- (void)setSystemBrightness:(NSArray *)arr {
    FlutterResult result = arr[1];
    FlutterMethodCall *call = arr.firstObject;

    if ([[call arguments] valueForKey:@"brightness"]){
        NSNumber *val = [[call arguments] valueForKey:@"brightness"];
        [[UIScreen mainScreen] setBrightness: val.floatValue];
    }
    result(nil);
}

/**
 * @method 获取系统亮度
 */
- (void)getSystemBrightness:(NSArray *)arr {
    FlutterResult result = arr[1];
    result(@([UIScreen mainScreen].brightness));
}

- (void)setCacheUrlHashCallback:(NSArray *)arr {
    FlutterResult result = arr[1];
    [AliPlayerGlobalSettings setCacheUrlHashCallback:CacheUrlHashCallBack];
    result(nil);
}

- (void)setNetworkCallback:(NSArray *)arr {
    FlutterResult result = arr[1];
    [AliPlayerGlobalSettings setNetworkDataProcessCallback:FlutterNetworkDataProcessCallback];
    result(nil);
}

- (void)setAdaptiveDecoderGetBackupURLCallback:(NSArray *)arr{
    FlutterResult result = arr[1];
    [AliPlayerGlobalSettings setAdaptiveDecoderGetBackupURLCallback:FlutterBackupUrlCallback];
    result(nil);
}

NSString* CacheUrlHashCallBack(NSString* url){
    FlutterBasicMessageChannel *cacheUrlHashChannel = [[AliChannelPool sharedManager] channelForKey:ChannelCacheUrlHash];
    if(cacheUrlHashChannel){
        dispatch_async(dispatch_get_main_queue(), ^{
            [cacheUrlHashChannel setMessageHandler:^(id  _Nullable message, FlutterReply callback) {
                callback(nil);
            }];
        });
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSString *result = @"";

    void (^workBlock)(void) = ^{
        NSString *argments = [NSString stringWithFormat:@"{\"param1\": \"%@\"}",url];
        if (cacheUrlHashChannel){
            dispatch_async(dispatch_get_main_queue(), ^(){
                [cacheUrlHashChannel sendMessage:argments reply:^(NSString *reply) {
                    result = reply;
                    dispatch_semaphore_signal(semaphore);// 任务完成后发送信号
                }];
            });
        }
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),workBlock);

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    

    return result;
}

bool FlutterNetworkDataProcessCallback(NSString *requestUrl,
             const uint8_t *inData,
             const int64_t inOutSize,
             uint8_t *outData){
    FlutterBasicMessageChannel *channnel = [[AliChannelPool sharedManager] channelForKey:ChannelNetData];
    if(channnel != nil){
        dispatch_async(dispatch_get_main_queue(), ^{
            [channnel setMessageHandler:^(id  _Nullable message, FlutterReply callback) {
                callback(nil);
            }];
        });
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        __block BOOL result = false;

        void (^workBlock)(void) = ^{
            NSString *argments = [NSString stringWithFormat:@"{\"param1\": \"%@\", \"param2\": \"%@\",\"param3\": \"%lld\",\"param4\": \"%@\"}",requestUrl,hexStringFromBytes(inData, inOutSize),inOutSize,hexStringFromBytes(outData, inOutSize)];
            if (channnel){
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [channnel sendMessage:argments reply:^(NSNumber *reply) {
                        result = reply.boolValue;
                        NSLog(@"[ios] result value %d",reply.boolValue);
                        dispatch_semaphore_signal(semaphore);// 任务完成后发送信号
                    }];
                });
            }
        };

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),workBlock);
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC / 100);
        long time  = dispatch_semaphore_wait(semaphore, timeout);
        
        if (time != 0) {
            // 超时未释放,主动释放
//            NSLog(@"操作超时，信号量未被释放");
            dispatch_semaphore_signal(semaphore);
        }
       
        return result;
    }
    
    return false;
}

NSString* FlutterBackupUrlCallback(AVPBizScene scene, AVPCodecType codecType, NSString* oriurl){
    FlutterBasicMessageChannel* backUpChannel = [[AliChannelPool sharedManager] channelForKey:ChannelBackUp];
    if(backUpChannel){
        dispatch_async(dispatch_get_main_queue(), ^{
            [backUpChannel setMessageHandler:^(id  _Nullable message, FlutterReply callback) {
                callback(nil);
            }];
        });
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSString *result = false;
    
    void (^workBlock)(void) = ^{
        NSString *argments = [NSString stringWithFormat:@"{\"param1\": \"%ld\",\"param2\": \"%ld\",\"param3\": \"%@\"}",(long)scene,(long)codecType,oriurl];
        if (backUpChannel){
            [backUpChannel sendMessage:argments reply:^(NSString *reply) {
                result = reply;
                NSLog(@"[Flutter] FlutterBackupUrlCallback->  %@", reply);
                dispatch_semaphore_signal(semaphore);// 任务完成后发送信号
            }];
        }
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),workBlock);
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC);
    long time  = dispatch_semaphore_wait(semaphore, timeout);
    
    if (time != 0) {
        // 超时未释放,主动释放
//            NSLog(@"操作超时，信号量未被释放");
        dispatch_semaphore_signal(semaphore);
    }
    
    return result;
}

/**
 *  unit8_t  =>  NSString
 */
NSString *hexStringFromBytes(const uint8_t *bytes, const int64_t length) {
    NSMutableString *hexString = [NSMutableString stringWithCapacity:length * 2];
    for (int i = 0; i < length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    return hexString;
}

@end
