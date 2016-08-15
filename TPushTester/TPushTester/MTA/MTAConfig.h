//
//  StatConfig.h
//  TA-SDK
//
//  Created by WQY on 12-11-5.
//  Copyright (c) 2012年 WQY. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef enum {
    MTA_STRATEGY_INSTANT = 1,            //实时上报
    MTA_STRATEGY_BATCH = 2,              //批量上报，达到缓存临界值时触发发送
    MTA_STRATEGY_APP_LAUNCH = 3,         //应用启动时发送
    MTA_STRATEGY_PERIOD = 5             //每间隔一定最小时间发送，默认24小时
} MTAStatReportStrategy;

@interface MTAConfig : NSObject

@property (nonatomic, copy) NSString* ifa;    //苹果的广告标识符，强烈建议有广告的App传入
@property (nonatomic, copy) NSString* appkey; //应用的统计AppKey

@property (nonatomic, assign) NSUInteger sessionTimeoutSecs;          //Session超时时长，默认30秒
@property (nonatomic, assign) NSUInteger maxStoreEventCount;          //最大缓存的未发送的统计消息，默认1024
@property (nonatomic, assign) NSUInteger maxLoadEventCount;           //一次最大加载未发送的缓存消息，默认30
@property (nonatomic, assign) NSUInteger minBatchReportCount;         //统计上报策略为BATCH时，触发上报时最小缓存消息数，默认30
@property (nonatomic, assign) NSUInteger maxSendRetryCount;           //发送失败最大重试数，默认3
@property (nonatomic, assign) NSUInteger sendPeriodMinutes;           //上报策略为PERIOD时发送间隔，单位分钟，默认一天（1440分钟）
@property (nonatomic, assign) NSUInteger maxParallelTimingEvents;     //最大并行统计的时长事件数，默认1024上报，默认TRUE
@property (nonatomic, assign) NSUInteger maxReportEventLength;        //最大上报的单条event长度，超过不上报
@property (nonatomic, assign) NSUInteger maxSessionStatReportCount;   //最大上报的Session数量

@property (nonatomic, assign) BOOL debugEnable;                    //debug开关
@property (nonatomic, assign) BOOL smartReporting;                 //智能上报开关:在WIFI模式下实时
@property (nonatomic, assign) BOOL statEnable;                     //MTA总开关:为false时MTA失效

@property MTAStatReportStrategy reportStrategy;    //统计上报策略

+(instancetype) getInstance;

@end
