//
//  定制版本: 自定义事件上报
//  TA-SDK
//
//  Created by WQY on 12-11-5.
//  Copyright (c) 2012年 WQY. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MTA_SDK_VERSION @"1.4.3.2"

@interface MTA : NSObject

+(void) startWithAppkey:(NSString*) appkey;

+(void) trackCustomKeyValueEvent:(NSString*)event_id props:(NSDictionary*) kvs;
+(void) trackCustomKeyValueEventDuration:(NSUInteger)seconds withEventid:(NSString*)event_id props:(NSDictionary*) kvs;


/*********************************************************************
 以下是需要自定义的增强接口,
 appkey:指定appkey进行上报
 isRealTime:如果为true，则进行实时上报。如果为false,则进行默认MTAConfig中的上报策略进行上报
*********************************************************************/

+(void) trackCustomKeyValueEvent:(NSString*)event_id props:(NSDictionary*) kvs appkey:(NSString *)appkey isRealTime:(BOOL)isRealTime;
+(void) trackCustomKeyValueEventDuration:(NSUInteger) seconds withEventid:(NSString*)event_id props:(NSDictionary*) kvs appKey:(NSString*)appkey isRealTime:(BOOL)isRealTime;

@end
