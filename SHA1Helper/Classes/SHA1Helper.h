//
//  SHA1Help.h
//  prfcloud
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SHA1Helper : NSObject
//计算字符串
+ (NSString*)sha1:(NSString*)input;
+ (NSString*)sha256:(NSString*)input;
+ (NSString*)SM3:(NSString*)input;
//计算文件

+ (void) calculateFileSM3WithPath:(NSString *) filePath
          chunkSizeForReadingData:(size_t) chunkSizeForReadingData
                 needCancelHandle:(BOOL(^)(void)) needCancelHandle
                   progressHandle:(void (^)(CGFloat progress)) progressHandle
              calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
                      errorHandle:(void (^)(NSString * errString)) errorHandle;

+ (void) calculateFileSHA256WithPath:(NSString *) filePath
           chunkSizeForReadingData:(size_t) chunkSizeForReadingData  //循环读取的块大小，传0为默认值4096
                  needCancelHandle:(BOOL(^)(void)) needCancelHandle  //在需要取消时，返回NO即可终止
                    progressHandle:(void (^)(CGFloat progress)) progressHandle //进度范围0.0-1.0
               calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
                       errorHandle:(void (^)(NSString * errString)) errorHandle;//错误原因

+ (void) calculateFileSHA1WithPath:(NSString *) filePath
chunkSizeForReadingData:(size_t) chunkSizeForReadingData  //循环读取的块大小，传0为默认值4096
       needCancelHandle:(BOOL(^)(void)) needCancelHandle  //在需要取消时，返回NO即可终止
         progressHandle:(void (^)(CGFloat progress)) progressHandle //进度范围0.0-1.0
    calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
            errorHandle:(void (^)(NSString * errString)) errorHandle;//错误原因
@end
