//
//  WifiCamPropertyControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiCamAlertTable.h"
#import "WifiCamAVData.h"

@interface WifiCamPropertyControl : NSObject

// Inquire state info
//- (BOOL)isMediaStreamRecording;
//-(BOOL)isVideoTimelapseOn;
//-(BOOL)isStillTimelapseOn;
- (BOOL)connected;
- (BOOL)checkSDExist;
- (BOOL)videoStreamEnabled;
- (BOOL)audioStreamEnabled;

// Change those property value
// TODO: Please refactor those function definetion!!!
- (int)changeImageSize:(string)size;
- (int)changeVideoSize:(string)size;
- (int)changeDelayedCaptureTime:(unsigned int)time;
- (int)changeWhiteBalance:(unsigned int)value;
- (int)changeLightFrequency:(unsigned int)value;
- (int)changeBurstNumber:(unsigned int)value;
- (int)changeDateStamp:(unsigned int)value;
- (int)changeTimelapseInterval:(unsigned int)value;
- (int)changeTimelapseDuration:(unsigned int)value;
- (int)changeUpsideDown:(uint)value;
- (int)changeSlowMotion:(uint)value;
- (BOOL)changeSSID:(NSString *)ssid;
- (BOOL)changePassword:(NSString *)password;

- (unsigned int)retrieveDelayedCaptureTime;
- (unsigned int)retrieveBurstNumber;
   
// Figure out property value using index value within array
- (unsigned int)parseDelayCaptureInArray:(NSInteger)index;
- (string)parseImageSizeInArray:(NSInteger)index;
- (string)parseVideoSizeInArray:(NSInteger)index;
- (unsigned int)parseWhiteBalanceInArray:(NSInteger)index;
- (unsigned int)parsePowerFrequencyInArray:(NSInteger)index;
- (unsigned int)parseBurstNumberInArray:(NSInteger)index;
- (unsigned int)parseDateStampInArray:(NSInteger)index;
- (unsigned int)parseTimelapseIntervalInArray:(NSInteger)index;
- (unsigned int)parseTimelapseDurationInArray:(NSInteger)index;

// Assemble those infomation into an container
- (NSArray *)prepareDataForStorageSpaceOfImage:(string)imageSize;
- (NSArray *)prepareDataForStorageSpaceOfVideo:(string)videoSize;
- (WifiCamAlertTable *)prepareDataForDelayCapture:(unsigned int)curDelayCapture;
- (WifiCamAlertTable *)prepareDataForImageSize:(string)curImageSize;
- (WifiCamAlertTable *)prepareDataForVideoSize:(string)curVideoSize;
- (WifiCamAlertTable *)prepareDataForLightFrequency:(unsigned int)curLightFrequency;
- (WifiCamAlertTable *)prepareDataForWhiteBalance:(unsigned int)curWhiteBalance;
- (WifiCamAlertTable *)prepareDataForBurstNumber:(unsigned int)curBurstNumber;
- (WifiCamAlertTable *)prepareDataForDateStamp:(unsigned int)curDateStamp;
- (WifiCamAVData *)prepareDataForVideoFrame;
- (WifiCamAVData *)prepareDataForAudioTrack;
- (ICatchAudioFormat)retrieveAudioFormat;
- (WifiCamAVData *)prepareDataForPlaybackVideoFrame;
- (WifiCamAVData *)prepareDataForPlaybackAudioTrack;
- (ICatchAudioFormat)retrievePlaybackAudioFormat;
- (NSString *)prepareDataForBatteryLevel;

- (WifiCamAlertTable *)prepareDataForTimelapseInterval:(unsigned int)curVideoTimelapseInterval;
- (WifiCamAlertTable *)prepareDataForTimelapseDuration:(unsigned int)curVideoTimelapseDuration;

//
-(uint)retrieveMaxZoomRatio;
-(uint)retrieveCurrentZoomRatio;
-(uint)retrieveCurrentUpsideDown;
-(uint)retrieveCurrentSlowMotion;
-(uint)retrieveCurrentMoviceRecordElapsedTime;
-(uint)retrieveCurrentTimelapseInterval;
-(BOOL)isSupportMethod2ChangeVideoSize;

// Update
-(void)updateAllProperty:(WifiCamCamera *)camera;
@end
