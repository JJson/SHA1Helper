//
//  SHA1Help.m
//  prfcloud
//
//

#import "SHA1Helper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#include "sm3.h"
// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

@implementation SHA1Helper
+ (NSString*) sha1:(NSString*)input
{
    return [self calculate:input type:ShaTypeSha1];
}

+ (NSString*) sha256:(NSString*)input
{
    return [self calculate:input type:ShaTypeSha256];
}

+ (NSString*)SM3:(NSString*)input
{
    return [self calculate:input type:SM3];
}

typedef enum _shaType: NSInteger {
    ShaTypeSha1,
    ShaTypeSha256,
    SM3
} ShaType;

+ (NSString *)calculate: (NSString*)input type: (ShaType)type {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    int digestLength = 0;
    uint8_t *digest = nil;
    switch (type) {
        
        case ShaTypeSha1:
            digestLength = CC_SHA1_DIGEST_LENGTH;
            digest = malloc(digestLength);
            memset(digest, 0x0, digestLength);
            CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
            break;
        case ShaTypeSha256:
            digestLength = CC_SHA256_DIGEST_LENGTH;
            digest = malloc(digestLength);
            memset(digest, 0x0, digestLength);
            CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
            break;
        case SM3:
            digestLength = CC_SHA256_DIGEST_LENGTH;
            digest = malloc(digestLength);
            memset(digest, 0x0, digestLength);
            sm3((unsigned char *)data.bytes, (int)data.length, digest);
            break;
    }

    NSMutableString* output = [NSMutableString stringWithCapacity:digestLength * 2];
    
    for(int i = 0; i < digestLength; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    if (digest != nil) {
        free(digest);
    }
    return output;
}

+ (void) calculateFileSM3WithPath:(NSString *) filePath
          chunkSizeForReadingData:(size_t) chunkSizeForReadingData
                 needCancelHandle:(BOOL(^)(void)) needCancelHandle
                   progressHandle:(void (^)(CGFloat progress)) progressHandle
              calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
              errorHandle:(void (^)(NSString * errString)) errorHandle
{
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       __block size_t chunkSize = chunkSizeForReadingData;
       if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
           
           if (errorHandle) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   errorHandle(@"文件不存在");
               });
           }
           return;
       }
       
       NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
       if (inputStream == nil) {
           if (errorHandle) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   errorHandle(@"创建文件流失败");
               });
           }
           return;
       }
       [inputStream open];
       
       // Initialize the hash object
       NSDictionary * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
       size_t fileSize = [[attr objectForKey:NSFileSize] longLongValue];
       sm3_context ctx;
       sm3_starts( &ctx );
       if (!chunkSize) {
           chunkSize = FileHashDefaultChunkSizeForReadingData;
       }
       
       // Feed the data to the hash object
       size_t sizeReaded = 0;
       uint8_t * buffer = malloc(chunkSize);
       while (inputStream.hasBytesAvailable) {
           memset(buffer, 0x0, chunkSize);
           if (needCancelHandle && needCancelHandle()) {
               if (errorHandle) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       errorHandle(@"已取消");
                   });
                   
               }
               free(buffer);
               return;
           }
           NSInteger readBytesCount = [inputStream read:buffer maxLength:chunkSize];
           if (readBytesCount > 0) {
               sizeReaded = sizeReaded + readBytesCount;
               sm3_update( &ctx, buffer, (int) readBytesCount );
               if (progressHandle) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       progressHandle(1.0 * sizeReaded / fileSize);
                   });
               }
           }
           
       }
       free(buffer);
       // Compute the hash digest
       unsigned char digest[CC_SHA256_DIGEST_LENGTH];
       sm3_finish( &ctx, digest );
       // Compute the string result
       char hash[2 * sizeof(digest)];
       for (size_t i = 0; i < sizeof(digest); ++i) {
           snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
       }
       
       NSString * strResult = [[NSString alloc] initWithBytes:hash length:sizeof(hash) encoding:NSUTF8StringEncoding];
       if (strResult == nil) {
           if (errorHandle) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   errorHandle(@"转换字符串失败");
               });
               
           }
           return;
       }
       else {
           if (calculateDoneHandle) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   calculateDoneHandle(strResult);
               });
               
           }
       }
   });
}

+ (void) calculateFileSHA256WithPath:(NSString *) filePath
           chunkSizeForReadingData:(size_t) chunkSizeForReadingData
                  needCancelHandle:(BOOL(^)(void)) needCancelHandle
                    progressHandle:(void (^)(CGFloat progress)) progressHandle
               calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
               errorHandle:(void (^)(NSString * errString)) errorHandle
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block size_t chunkSize = chunkSizeForReadingData;
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
            
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"文件不存在");
                });
            }
            return;
        }
        NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
        if (inputStream == nil) {
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"创建文件流失败");
                });
            }
            return;
        }
        [inputStream open];
        
        // Initialize the hash object
        NSDictionary * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size_t fileSize = [[attr objectForKey:NSFileSize] longLongValue];
        CC_SHA256_CTX hashObject;
        CC_SHA256_Init(&hashObject);
        if (!chunkSize) {
            chunkSize = FileHashDefaultChunkSizeForReadingData;
        }
        
        // Feed the data to the hash object
        size_t sizeReaded = 0;
        uint8_t * buffer = malloc(chunkSize);
        while (inputStream.hasBytesAvailable) {
            memset(buffer, 0x0, chunkSize);
            if (needCancelHandle && needCancelHandle()) {
                if (errorHandle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorHandle(@"已取消");
                    });
                    
                }
                free(buffer);
                return;
            }
            NSInteger readBytesCount = [inputStream read:buffer maxLength:chunkSize];
            if (readBytesCount > 0) {
                sizeReaded = sizeReaded + readBytesCount;
                CC_SHA256_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
                if (progressHandle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressHandle(1.0 * sizeReaded / fileSize);
                    });
                }
            }
            
        }
        free(buffer);
        // Compute the hash digest
        unsigned char digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(digest, &hashObject);
        
        // Compute the string result
        char hash[2 * sizeof(digest)];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        
        NSString * strResult = [[NSString alloc] initWithBytes:hash length:sizeof(hash) encoding:NSUTF8StringEncoding];
        if (strResult == nil) {
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"转换字符串失败");
                });
                
            }
            return;
        }
        else {
            if (calculateDoneHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    calculateDoneHandle(strResult);
                });
                
            }
        }
    });
}

+ (void) calculateFileSHA1WithPath:(NSString *) filePath
           chunkSizeForReadingData:(size_t) chunkSizeForReadingData
                  needCancelHandle:(BOOL(^)(void)) needCancelHandle
                    progressHandle:(void (^)(CGFloat progress)) progressHandle
               calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
               errorHandle:(void (^)(NSString * errString)) errorHandle
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block size_t chunkSize = chunkSizeForReadingData;
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
            
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"文件不存在");
                });
            }
            return;
        }
        NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
        if (inputStream == nil) {
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"创建文件流失败");
                });
            }
            return;
        }
        [inputStream open];
        
        // Initialize the hash object
        NSDictionary * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size_t fileSize = [[attr objectForKey:NSFileSize] longLongValue];
        CC_SHA1_CTX hashObject;
        CC_SHA1_Init(&hashObject);
        if (!chunkSize) {
            chunkSize = FileHashDefaultChunkSizeForReadingData;
        }
        
        // Feed the data to the hash object
        size_t sizeReaded = 0;
        uint8_t * buffer = malloc(chunkSize);
        while (inputStream.hasBytesAvailable) {
            memset(buffer, 0x0, chunkSize);
            if (needCancelHandle && needCancelHandle()) {
                if (errorHandle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorHandle(@"已取消");
                    });
                    
                }
                free(buffer);
                return;
            }
            NSInteger readBytesCount = [inputStream read:buffer maxLength:chunkSize];
            if (readBytesCount > 0) {
                sizeReaded = sizeReaded + readBytesCount;
                CC_SHA1_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
                if (progressHandle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressHandle(1.0 * sizeReaded / fileSize);
                    });
                }
            }
            
        }
        free(buffer);
        // Compute the hash digest
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(digest, &hashObject);
        
        // Compute the string result
        char hash[2 * sizeof(digest)];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        
        NSString * strResult = [[NSString alloc] initWithBytes:hash length:sizeof(hash) encoding:NSUTF8StringEncoding];
        if (strResult == nil) {
            if (errorHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandle(@"转换字符串失败");
                });
                
            }
            return;
        }
        else {
            if (calculateDoneHandle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    calculateDoneHandle(strResult);
                });
                
            }
        }
    });
}

@end
