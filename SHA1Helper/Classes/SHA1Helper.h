//
//  SHA1Help.h
//  prfcloud
//
//  Created by 张 卫平 on 12-8-29.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SHA1Helper : NSObject
-(void)aaa;
//计算字符串
+ (NSString*)sha1:(NSString*)input;
//计算文件
+ (void) calculateFileSHA1WithPath:(NSString *) filePath
           chunkSizeForReadingData:(size_t) chunkSizeForReadingData  //循环读取的块大小，传0为默认值4096
                  needCancelHandle:(BOOL(^)(void)) needCancelHandle  //在需要取消时，返回NO即可终止
                    progressHandle:(void (^)(CGFloat progress)) progressHandle //进度范围0.0-1.0
               calculateDoneHandle:(void (^)(NSString * result)) calculateDoneHandle
                       errorHandle:(void (^)(NSString * errString)) errorHandle;//错误原因
@end
