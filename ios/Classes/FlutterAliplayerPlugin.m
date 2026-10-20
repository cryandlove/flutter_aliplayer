#import "FlutterAliplayerPlugin.h"
#import "AliPlayerFactory.h"
#import "FlutterAliDownloaderPlugin.h"
#import "FlutterAliMediaLoader.h"
#import "FlutterAliMediaLoaderV2.h"
#import "FlutterAliPlayerGlobalSettings.h"
#import "AliChannelPool.h"

@implementation FlutterAliplayerPlugin

/**
    create
 */
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [AliPlayerGlobalSettings setOption:SET_EXTRA_DATA value:[NSString stringWithFormat:@"{\"platform\":\"flutter\",\"flutter-version\":\"%@\"}",[AliPlayer getSDKVersion]]];
    
    AliPlayerFactory* factory = [[AliPlayerFactory alloc] initWithMessenger:registrar.messenger];
    
    [registrar registerViewFactory:factory withId:@"plugins.flutter_aliplayer"];
   
    [FlutterAliDownloaderPlugin registerWithRegistrar:registrar];
    [FlutterAliPlayerGlobalSettings registerWithRegistrar:registrar];
    [FlutterAliMediaLoader registerWithRegistrar:registrar];
    [FlutterAliMediaLoaderV2 registerWithRegistrar:registrar];
}

/**
    destroy
 */
- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar{
    [[AliChannelPool sharedManager] clear];
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
