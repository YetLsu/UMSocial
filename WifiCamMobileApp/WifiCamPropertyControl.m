//
//  WifiCamPropertyControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamPropertyControl.h"

@implementation WifiCamPropertyControl
/*
 - (BOOL)isMediaStreamRecording {
 return [[SDK instance] isMediaStreamRecording];
 }
 
 -(BOOL)isVideoTimelapseOn {
 return [[SDK instance] isVideoTimelapseOn];
 }
 -(BOOL)isStillTimelapseOn {
 return [[SDK instance] isStillTimelapseOn];
 }
 */
- (BOOL)connected
{
  return [[SDK instance] isConnected];
}

- (BOOL)checkSDExist
{
  return [[SDK instance] checkSDExist];
}

- (BOOL)videoStreamEnabled {
  return [[SDK instance] videoStreamEnabled];
}

- (BOOL)audioStreamEnabled {
  return [[SDK instance] audioStreamEnabled];
}

- (int)changeImageSize:(string)size{
  return [[SDK instance] changeImageSize:size];
}

- (int)changeVideoSize:(string)size{
  return [[SDK instance] changeVideoSize:size];
}

-(int)changeDelayedCaptureTime:(unsigned int)time{
  return [[SDK instance] changeDelayedCaptureTime:time];
}

-(int)changeWhiteBalance:(unsigned int)value{
  return [[SDK instance] changeWhiteBalance:value];
}

-(int)changeLightFrequency:(unsigned int)value {
  return [[SDK instance] changeLightFrequency:value];
}
-(int)changeBurstNumber:(unsigned int)value {
  return [[SDK instance] changeBurstNumber:value];
}
-(int)changeDateStamp:(unsigned int)value {
  return [[SDK instance] changeDateStamp:value];
}
-(int)changeTimelapseInterval:(unsigned int)value {
  return [[SDK instance] changeTimelapseInterval:value];
}
-(int)changeTimelapseDuration:(unsigned int)value {
  return [[SDK instance] changeTimelapseDuration:value];
}

- (int)changeUpsideDown:(uint)value {
  return [[SDK instance] changeUpsideDown:value];
}

- (int)changeSlowMotion:(uint)value {
  return [[SDK instance] changeSlowMotion:value];
}

- (BOOL)changeSSID:(NSString *)ssid {
  return [[SDK instance] setCustomizeStringProperty:0xD83C value:ssid];
}

- (BOOL)changePassword:(NSString *)password {
  return [[SDK instance] setCustomizeStringProperty:0xD83D value:password];
}



//

- (unsigned int)retrieveDelayedCaptureTime {
  return [[SDK instance] retrieveDelayedCaptureTime];
}

- (unsigned int)retrieveBurstNumber {
  return [[SDK instance] retrieveBurstNumber];
}

- (unsigned int)parseDelayCaptureInArray:(NSInteger)index
{
  vector<unsigned int> vCDs = [[SDK instance] retrieveSupportedCaptureDelays];
  return vCDs.at(index);
}

- (string)parseImageSizeInArray:(NSInteger)index
{
  vector<string> vISs = [[SDK instance] retrieveSupportedImageSizes];
  return vISs.at(index);
}

- (string)parseVideoSizeInArray:(NSInteger)index
{
  vector<string> vVSs = [[SDK instance] retrieveSupportedVideoSizes];
  return vVSs.at(index);
}

- (unsigned int)parseWhiteBalanceInArray:(NSInteger)index
{
  vector<unsigned int> vWBs = [[SDK instance] retrieveSupportedWhiteBalances];
  return vWBs.at(index);
}

- (unsigned int)parsePowerFrequencyInArray:(NSInteger)index
{
  vector<unsigned int> vLFs = [[SDK instance] retrieveSupportedLightFrequencies];
  return vLFs.at(index);
}

- (unsigned int)parseBurstNumberInArray:(NSInteger)index
{
  vector<unsigned int> vBNs = [[SDK instance] retrieveSupportedBurstNumbers];
  return vBNs.at(index);
}

- (unsigned int)parseDateStampInArray:(NSInteger)index
{
  vector<unsigned int> vDSs = [[SDK instance] retrieveSupportedDateStamps];
  return vDSs.at(index);
}

- (unsigned int)parseTimelapseIntervalInArray:(NSInteger)index
{
  vector<unsigned int> vVTIs = [[SDK instance] retrieveSupportedTimelapseInterval];
  return vVTIs.at(index);
}

- (unsigned int)parseTimelapseDurationInArray:(NSInteger)index
{
  vector<unsigned int> vVTDs = [[SDK instance] retrieveSupportedTimelapseDuration];
  return vVTDs.at(index);
}

/*
- (NSArray *)prepareDataForStorageSpaceOfImage:(string)imageSize
{
  NSDictionary *curStaticImageSizeDict = [[WifiCamStaticData instance] imageSizeDict];
  NSString *key = [NSString stringWithFormat:@"%s", imageSize.c_str()];
  NSString *title = [curStaticImageSizeDict objectForKey:key];
  unsigned int n = [[SDK instance] retrieveFreeSpaceOfImage];
  
  return [NSArray arrayWithObjects:title, @(MAX(0, n)), nil];
}
*/

- (NSArray *)prepareDataForStorageSpaceOfVideo:(string)videoSize
{
  NSDictionary *curStaticVideoSizeDict = [[WifiCamStaticData instance] videoSizeDict];
  NSString *key = [NSString stringWithFormat:@"%s", videoSize.c_str()];
  NSArray *curStaticVideoSizeArray = [curStaticVideoSizeDict objectForKey:key];
  NSString *title = [curStaticVideoSizeArray firstObject];
  unsigned int iStorage = [[SDK instance] retrieveFreeSpaceOfVideo];
  
  return [NSArray arrayWithObjects:title, @(MAX(0, iStorage)), nil];
}


//
- (WifiCamAlertTable *)prepareDataForDelayCapture:(unsigned int)curDelayCapture
{
  int i = 0;
  SDK *sdk = [SDK instance];
  vector <unsigned int> v = [sdk retrieveSupportedCaptureDelays];
  NSDictionary *dict = [[WifiCamStaticData instance] captureDelayDict];
  
  
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:v.size()];
  [TAA.array removeAllObjects];
  
  
  for (vector <unsigned int>::iterator it = v.begin();
       it != v.end();
       ++it, ++i) {
    NSString *s = [dict objectForKey:@(*it)];
    
    if (s) {
      [TAA.array addObject:s];
    }
    
    if (*it == curDelayCapture) {
      TAA.lastIndex = i;
    }
  }
  
  AppLog(@"TAA.lastIndex: %lu", (unsigned long)TAA.lastIndex);
  return TAA;
}

// Modify by Allen.Chuang 2014.10.3
// parse imagesize string from camera and calucate as M size
- (WifiCamAlertTable *)prepareDataForImageSize:(string)curImageSize
{
  int i = 0;
  NSString *images = nil;
  NSString *sizeString = nil;
  SDK *sdk = [SDK instance];
  
  vector<string> vISs = [sdk retrieveSupportedImageSizes];
  for(vector<string>::iterator it = vISs.begin(); it != vISs.end(); ++it) {
    AppLog(@"%s", (*it).c_str());
  }
  
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:vISs.size()];
  
  for (vector <string>::iterator it = vISs.begin();
       it != vISs.end();
       ++it, ++i) {
    images = [NSString stringWithFormat:@"%s",(*it).c_str()];
    sizeString = [self calcImageSizeToNum:images];
    [TAA.array addObject:sizeString];
    if (*it == curImageSize) {
      TAA.lastIndex = i;
    }
  }
  
  return TAA;
}


- (NSArray *)prepareDataForStorageSpaceOfImage:(string)imageSize
{
  unsigned int freeSpace = [[SDK instance] retrieveFreeSpaceOfImage];
  NSString *images = [NSString stringWithFormat:@"%s",imageSize.c_str()];
  NSString *sizeString = [self calcImageSizeToNum:images];
  
  return [NSArray arrayWithObjects:sizeString, @(MAX(0, freeSpace)), nil];
}

-(NSString *)calcImageSizeToNum:(NSString *)size
{
  NSArray *xyArray = [size componentsSeparatedByString:@"x"];
  float imgX = [[xyArray objectAtIndex:0] floatValue];
  float imgY = [[xyArray objectAtIndex:1] floatValue];
  float numberToRound =(imgX*imgY/1000000);
  int sizeNum = (int) round(numberToRound);
  AppLog(@"roundf(%.2f) = %d",numberToRound, sizeNum);
  
  return sizeNum == 0 ? @"VGA" : [NSString stringWithFormat:@"%dM",sizeNum];
}

/*
- (WifiCamAlertTable *)prepareDataForImageSize:(string)curImageSize
{
  int i = 0;
  SDK *sdk = [SDK instance];
  
  vector<string> vISs = [sdk retrieveSupportedImageSizes];
  for(vector<string>::iterator it = vISs.begin(); it != vISs.end(); ++it) {
    AppLog(@"%s", (*it).c_str());
  }

  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:vISs.size()];
  NSDictionary *imageSizeDict = [[WifiCamStaticData instance] imageSizeDict];
  
  for (vector <string>::iterator it = vISs.begin();
       it != vISs.end();
       ++it, ++i) {
    NSString *key = [NSString stringWithFormat:@"%s", (*it).c_str()];
    NSString *size = [imageSizeDict objectForKey:key];
    size = [size stringByAppendingFormat:@"(%@)", key];
    [TAA.array addObject:size];
    if (*it == curImageSize) {
      TAA.lastIndex = i;
    }
  }
  
  return TAA;
}
 */

- (WifiCamAlertTable *)prepareDataForVideoSize:(string)curVideoSize
{
  int i = 0;
  SDK *sdk = [SDK instance];

  vector<string> vVSs = [sdk retrieveSupportedVideoSizes];
  //vVSs.push_back("3840x2160 10");
  //vVSs.push_back("2704x1524 15");
  for(vector<string>::iterator it = vVSs.begin();
      it != vVSs.end();
      ++it) {
    AppLog(@"%s", (*it).c_str());
  }

  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:vVSs.size()];
  NSDictionary *videoSizeDict = [[WifiCamStaticData instance] videoSizeDict];
  
  for (vector <string>::iterator it = vVSs.begin();
       it != vVSs.end();
       ++it, ++i) {
    NSString *key = [NSString stringWithFormat:@"%s", (*it).c_str()];
    NSArray   *a = [videoSizeDict objectForKey:key];
    NSString  *first = [a firstObject];
    NSString  *last = [a lastObject];
    
    if (last != nil) {
      NSString *s = [first stringByAppendingFormat:@" %@", last]; // Customize
      
      if (s != nil) {
        [TAA.array addObject:s];
      }
      
      if (*it == curVideoSize) {
        TAA.lastIndex = i;
      }
    }
  }
  
  return TAA;
}

- (WifiCamAlertTable *)prepareDataForLightFrequency:(unsigned int)curLightFrequency
{
  int i = 0;
  WifiCamAlertTable *TAA = nil;
  SDK *sdk = [SDK instance];
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vLFs = [sdk retrieveSupportedLightFrequencies];
  vector<ICatchLightFrequency> supportedEnumedLightFrequencies;
  ICatchWificamUtil::convertLightFrequencies(vLFs, supportedEnumedLightFrequencies);
  NSDictionary *dict = [[WifiCamStaticData instance] powerFrequencyDict];
  
  TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedLightFrequencies.size()];
  
  for (vector <ICatchLightFrequency>::iterator it = supportedEnumedLightFrequencies.begin();
       it != supportedEnumedLightFrequencies.end();
       ++it, ++i) {
    NSString *s = [dict objectForKey:@(*it)];
    
    if (s != nil && ![s isEqualToString:@""]) {
      [TAA.array addObject:s];
    }
    
    if (*it == curLightFrequency && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  if (!InvalidSelectedIndex) {
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}

- (WifiCamAlertTable *)prepareDataForWhiteBalance:(unsigned int)curWhiteBalance
{
  SDK *sdk = [SDK instance];
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vWBs = [sdk retrieveSupportedWhiteBalances];
  vector<ICatchWhiteBalance> supportedEnumedWhiteBalances;
  ICatchWificamUtil::convertWhiteBalances(vWBs, supportedEnumedWhiteBalances);
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedWhiteBalances.size()];
  int i = 0;
  NSDictionary *dict = [[WifiCamStaticData instance] whiteBalanceDict];
  
  for (vector <ICatchWhiteBalance>::iterator it = supportedEnumedWhiteBalances.begin();
       it != supportedEnumedWhiteBalances.end();
       ++it, ++i) {
    NSString *s = [dict objectForKey:@(*it)];
    
    if (s != nil) {
      [TAA.array addObject:s];
    }
    
    if (*it == curWhiteBalance && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  if (!InvalidSelectedIndex) {
    AppLog(@"Undefined Number");
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}

- (WifiCamAlertTable *)prepareDataForBurstNumber:(unsigned int)curBurstNumber
{
  SDK *sdk = [SDK instance];
  
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vBNs = [sdk retrieveSupportedBurstNumbers];
  AppLog(@"vBNs.size(): %lu", vBNs.size());
  vector<ICatchBurstNumber> supportedEnumedBurstNumbers;
  ICatchWificamUtil::convertBurstNumbers(vBNs, supportedEnumedBurstNumbers);
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedBurstNumbers.size()];
  AppLog("supportedEnumedBurstNumbers.size(): %lu", supportedEnumedBurstNumbers.size());
  int i = 0;
  NSDictionary *dict = [[WifiCamStaticData instance] burstNumberStringDict];
  
  for (vector <ICatchBurstNumber>::iterator it = supportedEnumedBurstNumbers.begin();
       it != supportedEnumedBurstNumbers.end();
       ++it, ++i) {
    NSString *s = [[dict objectForKey:@(*it)] firstObject];
    
    if (s != nil) {
      [TAA.array addObject:s];
    }
    
    if (*it == curBurstNumber && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  if (!InvalidSelectedIndex) {
    AppLog(@"Undefined Number");
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}

- (WifiCamAlertTable *)prepareDataForDateStamp:(unsigned int)curDateStamp
{
  SDK *sdk = [SDK instance];
  
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vDSs = [sdk retrieveSupportedDateStamps];
  vector<ICatchDateStamp> supportedEnumedDataStamps;
  ICatchWificamUtil::convertDateStamps(vDSs, supportedEnumedDataStamps);
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedDataStamps.size()];
  int i =0;
  NSDictionary *dict = [[WifiCamStaticData instance] dateStampDict];
  
  for(vector<ICatchDateStamp>::iterator it = supportedEnumedDataStamps.begin();
      it != supportedEnumedDataStamps.end();
      ++it, ++i) {
    NSString *s = [dict objectForKey:@(*it)];
    
    if (s != nil) {
      [TAA.array addObject:s];
    }
    
    if (*it == curDateStamp && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  
  if (!InvalidSelectedIndex) {
    AppLog(@"Undefined Number");
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}

- (WifiCamAlertTable *)prepareDataForTimelapseInterval:(unsigned int)curTimelapseInterval
{
  SDK *sdk = [SDK instance];
  
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vTIs = [sdk retrieveSupportedTimelapseInterval];
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  
  TAA.array = [[NSMutableArray alloc] initWithCapacity:vTIs.size()];
  int i =0;
  //    NSDictionary *dict = [[WifiCamStaticData instance] timelapseIntervalDict];
  
  AppLog(@"curTimelapseInterval: %d", curTimelapseInterval);
  for(vector<unsigned int>::iterator it = vTIs.begin();
      it != vTIs.end();
      ++it, ++i) {
    //AppLog(@"Interval Item Value: %d", *it);
    //        NSString *s = [dict objectForKey:@(*it)];
    NSString *s = nil;
    
    if (0 == *it) {
      s = NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_OFF", nil);
    } else if (*it >= 60 && *it < 3600) {
      s = [NSString stringWithFormat:@"%dm", (*it/60)];
    } else if (*it >= 3600) {
      s = [NSString stringWithFormat:@"%dhr", (*it/3600)];
    } else {
      s = [NSString stringWithFormat:@"%ds", *it];
    }
    
    if (s != nil) {
      [TAA.array addObject:s];
    }
    
    if (*it == curTimelapseInterval && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  
  if (!InvalidSelectedIndex) {
    AppLog(@"Undefined Number");
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}


- (WifiCamAlertTable *)prepareDataForTimelapseDuration:(unsigned int)curTimelapseDuration
{
  SDK *sdk = [SDK instance];
  
  BOOL InvalidSelectedIndex = NO;
  vector<unsigned int> vTDs = [sdk retrieveSupportedTimelapseDuration];
  WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
  
  TAA.array = [[NSMutableArray alloc] initWithCapacity:vTDs.size()];
  int i =0;
  //    NSDictionary *dict = [[WifiCamStaticData instance] timelapseDurationDict];
  
  AppLog(@"curTimelapseDuration: %d",curTimelapseDuration);
  for(vector<unsigned int>::iterator it = vTDs.begin();
      it != vTDs.end();
      ++it, ++i) {
    //AppLog(@"Duration Item Value:%d", *it);
    //        NSString *s = [dict objectForKey:@(*it)];
    NSString *s = nil;
    if (0xFFFF == *it) {
      s = NSLocalizedString(@"SETTING_CAP_TL_DURATION_Unlimited", nil);
    } else if (*it >= 60 && *it < 3600) {
      s = [NSString stringWithFormat:@"%dhr", (*it/60)];
    } else {
      s = [NSString stringWithFormat:@"%dm", *it];
    }
    
    if (s != nil) {
      [TAA.array addObject:s];
    }
    
    if (*it == curTimelapseDuration && !InvalidSelectedIndex) {
      TAA.lastIndex = i;
      InvalidSelectedIndex = YES;
    }
  }
  
  if (!InvalidSelectedIndex) {
    AppLog(@"Undefined Number");
    TAA.lastIndex = UNDEFINED_NUM;
  }
  
  return TAA;
}


///

- (WifiCamAVData *)prepareDataForVideoFrame
{
  return [[SDK instance] getFrameData];
}

- (WifiCamAVData *)prepareDataForAudioTrack
{
  return [[SDK instance] getAudioData];
}

- (WifiCamAVData *)prepareDataForPlaybackVideoFrame
{
  return [[SDK instance] getPlaybackFrameData];
}

- (WifiCamAVData *)prepareDataForPlaybackAudioTrack
{
  return [[SDK instance] getPlaybackAudioData];
}

- (NSString *)prepareDataForBatteryLevel
{
  uint level = [[SDK instance] retrieveBatteryLevel];
  return [self transBatteryLevel2NStr:level];
}

- (NSString *)transBatteryLevel2NStr:(unsigned int)value
{
  NSString *retVal = nil;
  
  if (value < 10) {
    retVal = @"battery_0";
  } else if (value < 40) {
    retVal = @"battery_1";
  } else if (value < 70) {
    retVal = @"battery_2";
  } else if (value <= 100) {
    retVal = @"battery_3";
  } else {
    AppLog(@"battery raw value: %d", value);
    retVal = @"battery_4";
  }
  
  return retVal;
}

//

-(uint)retrieveMaxZoomRatio
{
  return [[SDK instance] retrieveMaxZoomRatio];
}

-(uint)retrieveCurrentZoomRatio
{
  return [[SDK instance] retrieveCurrentZoomRatio];
}

-(uint)retrieveCurrentUpsideDown {
  return [[SDK instance] retrieveCurrentUpsideDown];
}

-(uint)retrieveCurrentSlowMotion {
  return [[SDK instance] retrieveCurrentSlowMotion];
}

-(uint)retrieveCurrentMoviceRecordElapsedTime {
  return [[SDK instance] getCustomizePropertyIntValue:0xD7FD];
}

-(uint)retrieveCurrentTimelapseInterval {
  return [[SDK instance] retrieveTimelapseInterval];
}
- (ICatchAudioFormat)retrieveAudioFormat {
    return [[SDK instance] getAudioFormat];
    /*
     __block ICatchAudioFormat format;
     dispatch_sync([[SDK instance] sdkQueue], ^{
     ICatchAudioFormat f([[SDK instance] getAudioFormat]);
     format = f;
     });
     return format;
     */
}
- (ICatchAudioFormat)retrievePlaybackAudioFormat {
    return [[SDK instance] getPlaybackAudioFormat];
    /*
     __block ICatchAudioFormat format;
     dispatch_sync([[SDK instance] sdkQueue], ^{
     ICatchAudioFormat f([[SDK instance] getPlaybackAudioFormat]);
     format = f;
     });
     return format;
     */
}
-(BOOL)isSupportMethod2ChangeVideoSize {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        if (([[SDK instance] getCustomizePropertyIntValue:0xD7FC] & 0x0001) == 1) {
            AppLog(@"D7FC is ON");
            retVal = YES;
        } else if (([[SDK instance] getCustomizePropertyIntValue:0xD7FC] & 0x0001) == 0){
            retVal = NO;
        } else {
            retVal = NO;
        }
    });
    
    return retVal;
}
-(void)updateAllProperty:(WifiCamCamera *)camera {
    
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        //camera.cameraMode = [sdk retrieveCurrentCameraMode];
        camera.curImageSize = [sdk retrieveImageSize];
        camera.curVideoSize = [sdk retrieveVideoSize];
        AppLog(@"video Size: %@", [NSString stringWithFormat:@"%s",camera.curVideoSize.c_str()]);
        camera.curCaptureDelay = [sdk retrieveDelayedCaptureTime];
        camera.curWhiteBalance = [sdk retrieveWhiteBalanceValue];
        camera.curSlowMotion = [sdk retrieveCurrentSlowMotion];
        camera.curInvertMode = [sdk retrieveCurrentUpsideDown];
        camera.curBurstNumber = [sdk retrieveBurstNumber];
        camera.storageSpaceForImage = [sdk retrieveFreeSpaceOfImage];
        camera.storageSpaceForVideo = [sdk retrieveFreeSpaceOfVideo];
        camera.curLightFrequency = [sdk retrieveLightFrequency];
        camera.curDateStamp = [sdk retrieveDateStamp];
        AppLog(@"date-stamp: %d", camera.curDateStamp);
        
        //camera.curTimelapseInterval = [sdk retrieveTimelapseInterval];
        //AppLog(@"timelapse-interval: %d", camera.curTimelapseInterval);
        
        //camera.curTimelapseDuration = [sdk retrieveTimelapseDuration];
        //        camera.cameraFWVersion = [sdk retrieveCameraFWVersion];
        //        camera.cameraProductName = [sdk retrieveCameraProductName];
        //        camera.ssid = [sdk getCustomizePropertyStringValue:0xD83C];
        //        camera.password = [sdk getCustomizePropertyStringValue:0xD83D];
        //camera.previewMode = WifiCamPreviewModeVideoOff;
        camera.movieRecording = [sdk isMediaStreamRecording];
        //camera.stillTimelapseOn = [sdk isStillTimelapseOn];
        //camera.videoTimelapseOn = [sdk isVideoTimelapseOn];
        //camera.timelapseType = WifiCamTimelapseTypeVideo;
    });
}
@end
