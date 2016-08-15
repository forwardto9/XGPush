//
//  OCPush.h
//  TPushTester
//
//  Created by uwei on 5/25/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#ifndef OCPush_h
#define OCPush_h
#import "ioSock.h"

// certificate
#define SSL_CTX_LOAD_VERIFY_LOCATIONS_FAILED  -1
#define BIO_DO_CONNECT_FAILED                 -2
#define SSL_GET_VERIFY_RESULT_FAILED          -3

//typedef void (^completion) (NSString *message, NSInteger statusCode);

@interface OCPush : NSObject

+ (OSStatus)pushToDeviceToken:(NSString *)deviceToken payload:(NSString *)payload context:(SSLContextRef)context;
+ (void)closeSocket:(otSocket)socket;
+ (CFArrayRef)getSecIdentityRefFromFile:(NSString *)file password:(NSString *)pwd statusCode:(OSStatus *)code;


- (void)reset;
- (int)pushMessageToDeviceToken:(NSString *)deviceToken payload:(NSString *)payload fromHost:(NSString *)host withPEMFile:(NSString *)filePath;

+ (void)pushFromXGServerWithDeviceToken:(NSString *)deviceToken accessID:(NSString *)accessID secretKey:(NSString *)secretKey payload:(NSString *)payload enviroment:(NSString *)enviroment completion:(void (^) (NSString *message, NSInteger statusCode))completion;

@end



#endif /* OCPush_h */