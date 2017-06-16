//
//  VideoPlaybackViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-3-10.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoPlaybackViewController;

@protocol VideoPlaybackControllerDelegate <NSObject>
- (BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller
             deleteVideoAtIndex:(NSUInteger)index;
@end

@interface VideoPlaybackViewController : UIViewController<UIActionSheetDelegate, UIPopoverControllerDelegate>
@property (nonatomic, weak) IBOutlet id<VideoPlaybackControllerDelegate> delegate;
@property (nonatomic) UIImage *previewImage;
@property (nonatomic) NSUInteger index;

//
- (void)updateVideoPbProgress:(double)value;
- (void)updateVideoPbProgressState:(BOOL)caching;
- (void)stopVideoPb;
- (void)showServerStreamError;
@end
