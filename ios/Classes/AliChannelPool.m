//
//  AliChannelPool.m
//  Pods
//
//  Created by aqi on 2025/1/22.
//
#import "AliChannelPool.h"


@interface AliChannelPool ()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id> *channels;

@end

@implementation AliChannelPool

+ (instancetype)sharedManager {
    static AliChannelPool *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance->_channels = [[NSMutableDictionary alloc] init];
    });
    return sharedInstance;
}

- (void)addChannel:(id)channel forKey:(NSString *)key {
    if (channel && key) {
        [self.channels setObject:channel forKey:key];
    }
}


- (id)channelForKey:(NSString *)key {
    return [self.channels objectForKey:key];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [AliChannelPool sharedManager] ;
}


- (void)clear{
    if (self.channels){
        [self.channels removeAllObjects];
    }
}

@end
