//
//  mta_pro.h
//  mta_pro
//
//  Created by xiang on 4/28/16.
//  Copyright © 2016 xiangchen. All rights reserved.
//
#import <Cocoa/Cocoa.h>

//MTA版本号
#define MTAPro_SDK_VERSION @"1.0.0"

//上报策略枚举
typedef NS_ENUM(NSInteger, MTAProReportStrategy) {
    MTAPro_STRATEGY_INSTANT = 1, //实时上报
    MTAPro_STRATEGY_PERIOD = 5,   //每间隔一定最小时间发送，(0,3600*24]s，默认90s
    MTA_STRATEGY_BECOME_ACTIVE = 8 //变成活动状态时上报
};


@interface MTAPro : NSObject

#pragma mark - 自定义配置
+(void)setDebugEnable:(BOOL)isEnable;  //debug开关

+(void)setSmartReport:(BOOL)isWifiInstant; //是否wifi下自动策略变为实时上报

+(void)setReportStrategy:(MTAProReportStrategy)reportStrategy; //统计上报策略

+(void)setChannel:(NSString *)channel; //渠道

+(void)setCustomAppVersion:(NSString *)appVersion; //自定义App版本

+(void)setCustomUserID:(NSString *)customUserID; //自定义用户ID

+(void)setSessionTimeoutSecs:(NSUInteger)timeoutSec; //Session超时时长，默认30秒

+(void)setPeriodSecs:(NSUInteger)periodSecs;  //上报策略为PERIOD时发送间隔，单位秒，默认90


#pragma mark - 服务接口
//启动MTA
+(void)startWithAppKey:(NSString *)appkey;

//页面时长统计
+(void)trackPageViewBegin:(NSString *)page;
+(void)trackPageViewEnd:(NSString *)page;
+(void)trackPage:(NSString *)page duration:(NSUInteger)duration;

//统计App前台运行时间
+(void)trackActiveBegin;
+(void)trackActiveEnd;

//自定义事件
+(void)trackCustomEvent:(NSString *)eventID dict:(NSDictionary *)dict;
+(void)trackCustomEventBegin:(NSString *)eventID dict:(NSDictionary *)dict;
+(void)trackCustomEventEnd:(NSString *)eventID dict:(NSDictionary *)dict;
+(void)trackCustomEventDuration:(NSString *)eventID dict:(NSDictionary *)dict duration:(NSInteger)duration;

//QQ号
+(void)reportQQ:(NSString *)qq;

//帐号 type(Default:0, QQ:1, WeChat:2, QQ_OpenID:3, WeChat_OpenID:4, PhoneNum:5, Email:6, CustomType:7)
+(void)reportAccount:(NSString *)account type:(NSUInteger)type ext:(NSString *)ext;

//获取设备ID相关属性
+(NSDictionary *)getDeviceIDs;

//获取下发的自定义参数
+(NSString *)getOnlineProperty:(NSString *)key;

@end
