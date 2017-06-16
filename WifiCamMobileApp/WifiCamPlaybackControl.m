//
//  WifiCamPlaybackControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamPlaybackControl.h"

@implementation WifiCamPlaybackControl

- (double)play:(ICatchFile *)f
{
  return [[SDK instance] play:f];
}

- (void)pause
{
  [[SDK instance] pause];
}

- (void)resume
{
  [[SDK instance] resume];
}

- (void)stop
{
  [[SDK instance] stop];
}

- (void)seek:(double)point
{
  [[SDK instance] seek:point];
}

- (BOOL)videoPlaybackStreamEnabled {
  return [[SDK instance] videoPlaybackStreamEnabled];
}

- (BOOL)audioPlaybackStreamEnabled {
  return [[SDK instance] audioPlaybackStreamEnabled];
}

@end
