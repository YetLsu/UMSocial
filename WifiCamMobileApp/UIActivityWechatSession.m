//
//  UIActivityWechatSession.m
//  WifiCamMobileApp
//
//  Created by Guo on 6/9/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import "UIActivityWechatSession.h"
#import "UIActivityItemImage.h"
#import "UMSocial.h"
@interface UIActivityWechatSession ()
@property (nonatomic) UIImage *imageForShare;
@property (nonatomic) NSString *messageForShare;
@end

@implementation UIActivityWechatSession
- (id)initWithDelegate:(id <ActivityWrapperDelegate>)delegate {
    if ((self = [self init])) {
        _delegate = delegate;
    }
    return self;
}

-(NSString *)activityType
{
    return NSStringFromClass([self class]);
}

-(NSString *)activityTitle
{
    return NSLocalizedString(@"Wechat", nil);
}

-(UIImage *)_activityImage
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return [UIImage imageNamed:@"UMS_wechat_session_icon"];
    } else {
        return [UIImage imageNamed:@"UMS_wechat_session_icon"];
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    if (activityItems.count != 1) {
        return NO;
    }
    for (id item in activityItems) {
        if (![item isKindOfClass:[UIActivityItemImage class]]) {
            return NO;
        }
    }
    return YES;
}

-(void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems) {
        if ([item isKindOfClass:[UIImage class]]) {
            _imageForShare =item;
            
        }
        else if([item isKindOfClass:[NSString class]]) {
            _messageForShare =item;
            
        }
        
    }
}

-(void)performActivity
{
    NSLog(@"%s", __func__);
    
    
    //[self activityDidFinish:YES];
    
    if ([_delegate respondsToSelector:@selector(showSLComposeViewController:)]) {
        [_delegate showSLComposeViewController:UMShareToWechatSession];
    }
    
}
@end
