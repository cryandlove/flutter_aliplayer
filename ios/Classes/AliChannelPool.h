//
//  AliChannelPool.h
//  Pods
//
//  Created by aqi on 2025/1/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AliChannelPool : NSObject

+ (instancetype)sharedManager;

// 添加通道的方法
- (void)addChannel:(id)channel forKey:(NSString *)key;

// 根据字符串获取通道的方法
- (id)channelForKey:(NSString *)key;


- (void) clear;

@end

NS_ASSUME_NONNULL_END
