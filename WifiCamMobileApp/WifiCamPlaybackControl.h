//
//  WifiCamPlaybackControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WifiCamPlaybackControl : NSObject

- (double)play:(ICatchFile *)file;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)seek:(double)point;
- (BOOL)videoPlaybackStreamEnabled;
- (BOOL)audioPlaybackStreamEnabled;

@end
