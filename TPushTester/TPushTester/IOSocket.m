//
//  IOSocket.m
//  TPushTester
//
//  Created by uwei on 21/12/2016.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import "IOSocket.h"

@implementation IOSocket

+ (OSStatus)socketReadOC:(SSLConnectionRef)connection data:(void *)data length:(size_t *)dataLength {
    return SocketRead(connection, data, dataLength);
}
+ (OSStatus)socketWriteOC:(SSLConnectionRef)connection data:(const void *)data length:(size_t *)dataLength {
    return SocketWrite(connection, data, dataLength);
}

@end
