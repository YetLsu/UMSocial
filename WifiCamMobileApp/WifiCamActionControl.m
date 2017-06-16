//
//  WifiCamActionControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamActionControl.h"

@implementation WifiCamActionControl

-(BOOL)startPreview:(ICatchPreviewMode)mode withAudioEnabled:(BOOL)enableAudio
{
    return [[SDK instance] startMediaStream:mode enableAudio:enableAudio];
}


-(BOOL)stopPreview
{
  BOOL retVal = NO;
  retVal = [[SDK instance] stopMediaStream];
  return retVal;
}

-(void)capturePhoto
{
  [[SDK instance] capturePhoto];
}
-(void)triggerCapturePhoto
{
  [[SDK instance] triggerCapturePhoto];
}

- (BOOL)formatSD
{
  return [[SDK instance] formatSD];
}

- (BOOL)startMovieRecord
{
  return [[SDK instance] startMovieRecord];
}

- (BOOL)stopMovieRecord
{
  return [[SDK instance] stopMovieRecord];
}

- (void)cleanUpDownloadDirectory
{
  [[SDK instance] cleanUpDownloadDirectory];
}

-(BOOL)startTimelapseRecord {
  return [[SDK instance] startTimelapseRecord];
}

-(BOOL)stopTimelapseRecord {
  return [[SDK instance] stopTimelapseRecord];
}

-(BOOL)zoomIn {
  return [[SDK instance] zoomIn];
}

-(BOOL)zoomOut {
  return [[SDK instance] zoomOut];
}
@end
