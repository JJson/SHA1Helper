//
//  SHA1Help.m
//
//

#import "SHA1Helper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>


// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

@implementation SHA1Helper
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
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        if (errorHandle) {
            errorHandle(@"文件不存在");
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
                errorHandle(@"已取消");
            }
            free(buffer);
            return;
        }
        NSInteger readBytesCount = [inputStream read:buffer maxLength:chunkSize];
        if (readBytesCount > 0) {
            sizeReaded = sizeReaded + readBytesCount;
            CC_SHA1_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
            if (progressHandle) {
                progressHandle(1.0 * sizeReaded / fileSize);
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
            errorHandle(@"转换字符串失败");
        }
        return;
    }
    else {
        if (calculateDoneHandle) {
            calculateDoneHandle(strResult);
        }
    }
}


@end
