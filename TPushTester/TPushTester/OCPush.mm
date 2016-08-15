//
//  OCPush.m
//  TPushTester
//
//  Created by uwei on 5/25/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#import "openssl/crypto.h"
#import "openssl/ssl.h"
#import "openssl/rand.h"
#import "openssl/bio.h"
#import "openssl/err.h"
#import "openssl/x509.h"
#import "OCPush.h"

@interface OCPush() {
    SSL_CTX                *m_pctx;
    SSL                    *m_pssl;
    const SSL_METHOD       *m_pmeth;
    X509                   *m_pserver_cert;
    EVP_PKEY               *m_pkey;
    BIO *bio;
}
@end



@implementation OCPush


- (instancetype)init {
    self = [super init];
    if (self) {
        m_pctx            = NULL;
        m_pssl            = NULL;
        m_pmeth            = NULL;
        m_pserver_cert    = NULL;
        m_pkey            = NULL;
        bio                = NULL;
    }
    
    return self;
}

- (void)dealloc {
    [self reset];
}


- (void)reset {
    if(m_pssl)
    {
        SSL_shutdown(m_pssl);
        SSL_free(m_pssl);
        m_pssl = NULL;
    }
    if(m_pctx)
    {
        SSL_CTX_free(m_pctx);
        m_pctx = NULL;
    }

}

- (int)pushMessageToDeviceToken:(NSString *)deviceToken payload:(NSString *)payload fromHost:(NSString *)host {
    //
//    char token[] = "8da412ec d60b4a8d ea08a8f5 31f0e832 ba87c072 8920cf7d 2e436f40 c367205b";
//    char payload[] = "{\"aps\":{\"alert\":\"Hello world!!! message from c++\",\"badge\":1}}";
//    char host[] = "gateway.sandbox.push.apple.com:2195";
    
    const char *token = [deviceToken UTF8String];
    const char *payloadString = [payload UTF8String];
    const char *hostString = [host UTF8String];
    
    /*
     * Lets get nice error messages
     */
    SSL_load_error_strings();
    ERR_load_BIO_strings();
    OpenSSL_add_all_algorithms();
    
    /*
     * Setup all the global SSL stuff
     */
    SSL_library_init();
    
    m_pctx = SSL_CTX_new(SSLv23_client_method());
    if (SSL_CTX_use_certificate_chain_file(m_pctx, CERTFILE) != 1) {
        printf("Error loading certificate from file\n");
        return -1;
    }
    if (SSL_CTX_use_PrivateKey_file(m_pctx, CERTFILE, SSL_FILETYPE_PEM) != 1) {
        printf("Error loading private key from file\n");
        return -2;
    }
    bio = BIO_new_connect(hostString);
    if (!bio) {
        printf("Error creating connection BIO\n");
        return -3;
    }
    if (BIO_do_connect(bio) <= 0) {
        printf("Error connection to remote machine\n");
        return -4;
    }
    if (!(m_pssl = SSL_new(m_pctx))) {
        printf("Error creating an SSL contexxt\n");
        return -5;
    }
    
    SSL_set_bio(m_pssl, bio, bio);
    int slRc = SSL_connect(m_pssl);
    if (slRc <= 0) {
        printf("Error connecting SSL object>>%d\n", slRc);
        return -6;
    }
//    int ret = pushmessage(token,payloadString);
    int ret = [self pushmessage:token payload:payloadString];
    
    printf("push ret[%d]\n", ret);
    [self reset];
    return 0;
}

- (int)pushmessage:(const char *)token payload:(const char *)payload {
    char tokenBytes[32];
    char message[293];
    int msgLength;
    
    token2bytes(token, tokenBytes);
    
    unsigned char command = 0;
    size_t payloadLength = strlen(payload);
    char *pointer = message;
    unsigned short networkTokenLength = htons((u_short)32);
    unsigned short networkPayloadLength = htons((unsigned short)payloadLength);
    memcpy(pointer, &command, sizeof(unsigned char));
    pointer +=sizeof(unsigned char);
    memcpy(pointer, &networkTokenLength, sizeof(unsigned short));
    pointer += sizeof(unsigned short);
    memcpy(pointer, tokenBytes, 32);
    pointer += 32;
    memcpy(pointer, &networkPayloadLength, sizeof(unsigned short));
    pointer += sizeof(unsigned short);
    memcpy(pointer, payload, payloadLength);
    pointer += payloadLength;
    msgLength = (int)(pointer - message);
    int ret = SSL_write(m_pssl, message, msgLength);
    
    return ret;
}

void token2bytes(const char *token, char *bytes){
    int val;
    while (*token) {
        sscanf(token, "%2x", &val);
        *(bytes++) = (char)val;
        token += 2;
        while (*token == ' ') {
            // skip space
            ++token;
        }
    }
}



+ (OSStatus)pushToDeviceToken:(NSString *)deviceToken payload:(NSString *)payload context:(SSLContextRef)context {
    
    // Validate input.
    if(deviceToken == nil || payload == nil) {
        return kUnknownType;
    } else if(![deviceToken rangeOfString:@" "].length) {
        //put in spaces in device token
        NSMutableString* tempString =  [NSMutableString stringWithString:deviceToken];
        int offset = 0;
        for(int i = 0; i < tempString.length; i++) {
            if(i%8 == 0 && i != 0 && i+offset < tempString.length-1) {
                //NSLog(@"i = %d + offset[%d] = %d", i, offset, i+offset);
                [tempString insertString:@" " atIndex:i+offset];
                offset++;
            }
        }
        deviceToken = tempString;
    }
    
    // Convert string into device token data.
    NSMutableData *deviceTokenData = [NSMutableData data];
    unsigned value;
    NSScanner *scanner = [NSScanner scannerWithString:deviceToken];
    while(![scanner isAtEnd]) {
        [scanner scanHexInt:&value];
        value = htonl(value);
        [deviceTokenData appendBytes:&value length:sizeof(value)];
    }
    
    // Create C input variables.
    char *deviceTokenBinary = (char *)[deviceTokenData bytes];
    char *payloadBinary = (char *)[payload UTF8String];
    size_t payloadLength = strlen(payloadBinary);
    
    // Define some variables.
    uint8_t command = 0;
    char message[512];
    char *pointer = message;
    uint16_t networkTokenLength = htons(32);
    uint16_t networkPayloadLength = htons(payloadLength);
    
    // Compose message.
    memcpy(pointer, &command, sizeof(uint8_t));
    pointer += sizeof(uint8_t);
    memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, deviceTokenBinary, 32);
    pointer += 32;
    memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, payloadBinary, payloadLength);
    pointer += payloadLength;
    
    // Send message over SSL.
    size_t processed = 0;
    OSStatus result = SSLWrite(context, &message, (pointer - message), &processed);
    if (result != noErr) {
        NSLog(@"SSLWrite(): %d %zd", result, processed);
    }
    
    return result;
    
}


+ (void)closeSocket:(otSocket)socket {
    close((int)socket);
}

+ (CFArrayRef)getSecIdentityRefFromFile:(NSString *)file password:(NSString *)pwd {
    NSData *p12Data = [NSData dataWithContentsOfFile:file];
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    
    SecKeyRef privateKeyRef = NULL;
    SecIdentityRef identityApp = NULL;
    CFArrayRef certificates = NULL;
    
    //ange to the actual password you used here
    [options setObject:pwd forKey:(id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import((CFDataRef) p12Data, (CFDictionaryRef)options, &items);
    
    if (securityError == noErr && CFArrayGetCount(items) > 0) {
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        identityApp = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
        securityError = SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
        // Set client certificate.
        certificates = CFArrayCreate(NULL, (const void **)&identityApp, 1, NULL);
        if (securityError != noErr) {
            privateKeyRef = NULL;
        }
    }
    
//    CFRelease(items);
    return certificates;
//    return identityApp;
//    return privateKeyRef;
}

@end



