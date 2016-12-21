//
//  IOSocket.h
//  TPushTester
//
//  Created by uwei on 21/12/2016.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ioSock.h"

@interface IOSocket : NSObject

+ (OSStatus)socketReadOC:(SSLConnectionRef)connection data:(void *)data length:(size_t *)dataLength;
+ (OSStatus)socketWriteOC:(SSLConnectionRef)connection data:(const void *)data length:(size_t *)dataLength;


@end
