//
//  PCViewController.m
//  SHA1Helper
//
//  Created by JJSon on 01/26/2018.
//  Copyright (c) 2018 JJSon. All rights reserved.
//

#import "PCViewController.h"
#import <SHA1Helper/SHA1Helper.h>
@interface PCViewController ()
@property(nonatomic)BOOL needStop;
@property (weak, nonatomic) IBOutlet UILabel *lbResult;
@end

@implementation PCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    NSString * result = [SHA1Helper sha256:@"hello"];
//    NSString * result2 = [SHA1Helper SM3:@"昨天"];
//    NSLog(@"result: %@", result2);
    
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/Downloads.zip",NSHomeDirectory()];
    
    
   /* [SHA1Helper calculateFileSHA1WithPath:filePath chunkSizeForReadingData:1024*1024 needCancelHandle:^BOOL{
        return self.needStop;
    } progressHandle:^(CGFloat progress) {
        NSLog(@"%f",progress);
//        printf("progress:%f\n",progress);
    } calculateDoneHandle:^(NSString *result) {
        NSLog(@"done:%@",result);
    } errorHandle:^(NSString *errString) {
        NSLog(@"error:%@",errString);
    }];*/
    
    [SHA1Helper calculateFileSM3WithPath:filePath chunkSizeForReadingData:1024*1024 needCancelHandle:^BOOL{
        return self.needStop;
    } progressHandle:^(CGFloat progress) {
        self.lbResult.text = [NSString stringWithFormat:@"%f",progress];
//        NSLog(@"%f",progress);
//        printf("progress:%f\n",progress);
    } calculateDoneHandle:^(NSString *result) {
//        NSLog(@"done:%@",result);
        self.lbResult.text = result;
    } errorHandle:^(NSString *errString) {
        NSLog(@"error:%@",errString);
    }];
     
}
- (IBAction)stop:(id)sender {
    self.needStop = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
