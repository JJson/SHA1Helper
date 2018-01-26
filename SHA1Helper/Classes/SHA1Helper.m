//
//  SHA1Help.m
//  prfcloud
//
//  Created by 张 卫平 on 12-8-29.
//
//

#import "SHA1Helper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>


// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

@implementation SHA1Helper
-(void)aaa
{
    
}
+ (NSString*) sha1:(NSString*)input
{
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}

+ (void) calculateFileSHA1WithPath:(NSString *) filePath
           chunkSizeForReadingData:(size_t) chunkSizeForReadingData
                  needCancelHandle:(BOOL(^)(void)) needCancelHandle
                    progressHandle:(void (^)(CGFloat progress)) progressHandle
               calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
               errorHandle:(void (^)(NSString * errString)) errorHandle
{
    __block size_t chunkSize = chunkSizeForReadingData;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
        while (inputStream.hasBytesAvailable) {
            if (needCancelHandle && needCancelHandle()) {
                if (errorHandle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorHandle(@"已取消");
                    });
                }
                return;
            }
            uint8_t buffer[chunkSize];
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
        // Compute the hash digest
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(digest, &hashObject);
        
        // Compute the string result
        char hash[2 * sizeof(digest) + 1];
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
