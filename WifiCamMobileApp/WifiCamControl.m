//
//  WifiCamControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-30.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamControl.h"
#import "WifiCamFileTable.h"


@implementation WifiCamControl

+(BOOL)initSDK
{
  return [[SDK instance] initializeSDK];
}

+(void)scan
{
  //
  //
  //
  
  [self findOneWifiCam];
}

+(void)findOneWifiCam
{
  WifiCamManager *app = [WifiCamManager instance];

  
  WifiCamCommonControl *comCtrl = [[WifiCamCommonControl alloc] init];
  WifiCamPropertyControl *propCtrl = [[WifiCamPropertyControl alloc] init];
  WifiCamActionControl *actCtrl = [[WifiCamActionControl alloc] init];
  WifiCamFileControl *fileCtrl = [[WifiCamFileControl alloc] init];
  WifiCamPlaybackControl *pbCtrl = [[WifiCamPlaybackControl alloc] init];
  WifiCamControlCenter *ctrl = [[WifiCamControlCenter alloc] initWithParameters:comCtrl
                                                             andPropertyControl:propCtrl
                                                               andActionControl:actCtrl
                                                                 andFileControl:fileCtrl
                                                             andPlaybackControl:pbCtrl];
  
  // Package this WifiCam object using serverl components
  WifiCam *wifiCam1 = [[WifiCam alloc] initWithId:1
                                 andWifiCamCamera:nil
                           andWifiCamPhotoGallery:nil
                          andWifiCamControlCenter:ctrl];
  [app.wifiCams addObject:wifiCam1];
}

+(WifiCamCamera *)createOneCamera
{
  SDK *sdk = [SDK instance];
  NSUInteger abilities = 0;
  abilities = [self scanAbility];
  AppLog(@"ssid: %@", [sdk getCustomizePropertyStringValue:0xD83C]);
  AppLog(@"password: %@", [sdk getCustomizePropertyStringValue:0xD83D]);
  WifiCamCamera *camera = [[WifiCamCamera alloc] initWithParameters:abilities
                                                      andCameraMode:[sdk retrieveCurrentCameraMode]
                                                       andImageSize:[sdk retrieveImageSize]
                                                       andVideoSize:[sdk retrieveVideoSize]
                                                  andDelayedCapture:[sdk retrieveDelayedCaptureTime]
                                                    andWhiteBalance:[sdk retrieveWhiteBalanceValue]
                                                      andSlowMotion:[sdk retrieveCurrentSlowMotion]
                                                      andInvertMode:[sdk retrieveCurrentUpsideDown]
                                                     andBurstNumber:[sdk retrieveBurstNumber]
                                            andStorageSpaceForImage:[sdk retrieveFreeSpaceOfImage]
                                            andStorageSpaceForVideo:[sdk retrieveFreeSpaceOfVideo]
                                                  andLightFrequency:[sdk retrieveLightFrequency]
                                                       andDateStamp:[sdk retrieveDateStamp]
                                               andTimelapseInterval:[sdk retrieveTimelapseInterval]
                                               andTimelapseDuration:[sdk retrieveTimelapseDuration]
                                                       andFWVersion:[sdk retrieveCameraFWVersion]
                                                     andProductName:[sdk retrieveCameraProductName]
                                                            andSSID:[sdk getCustomizePropertyStringValue:0xD83C]
                                                        andPassword:[sdk getCustomizePropertyStringValue:0xD83D]
                                                     andPreviewMode:WifiCamPreviewModeVideoOff
                                                andIsMovieRecording:[sdk isMediaStreamRecording]
                                              andIsStillTimelapseOn:[sdk isStillTimelapseOn]
                                              andIsVideoTimelapseOn:[sdk isVideoTimelapseOn]
                                                   andTimelapseType:WifiCamTimelapseTypeVideo];
  return camera;
}

+(WifiCamPhotoGallery *)createOnePhotoGallery {
  vector<ICatchFile> allList;
  unsigned long long allKBytes = 0;
  
  vector<ICatchFile> photoList;
  unsigned long long totalPhotoKBytes = 0;
//  NSMutableDictionary *splitedPhotoDict = [[NSMutableDictionary alloc] init];
  
  vector<ICatchFile> videoList;
  unsigned long long totalVideoKBytes = 0;
//  NSMutableDictionary *splitedVideoDict = [[NSMutableDictionary alloc] init];

  
  allList = [[SDK instance] requestFileListOfType:WCFileTypeAll];
  unsigned long long fileSize = 0;
//  NSUInteger allListSize = allList.size();
  for(vector<ICatchFile>::iterator it = allList.begin();
      it != allList.end();
      ++it) {
    ICatchFile f = *it;
    switch (f.getFileType()) {
      case TYPE_IMAGE:
        photoList.push_back(f);
        fileSize = f.getFileSize()>>10;;
        allKBytes += fileSize;
        totalPhotoKBytes += fileSize;
        break;
      case TYPE_VIDEO:
        videoList.push_back(f);
        fileSize = f.getFileSize()>>10;
        allKBytes += fileSize;
        totalVideoKBytes += fileSize;
        break;
      default:
        break;
    }
  }

  WifiCamFileTable *imageTable = [[WifiCamFileTable alloc] initWithParameters:photoList
                                                               andFileStorage:totalPhotoKBytes];  
  WifiCamFileTable *videoTable = [[WifiCamFileTable alloc] initWithParameters:videoList
                                                               andFileStorage:totalVideoKBytes];
  WifiCamFileTable *allFileTable = [[WifiCamFileTable alloc] initWithParameters:allList
                                                                 andFileStorage:allKBytes];
  WifiCamPhotoGallery *gallery = [[WifiCamPhotoGallery alloc] initWithFileTables:imageTable
                                                                    andVideoTable:videoTable
                                                                  andAllFileTable:allFileTable];
  
  
  return gallery;
}

+ (NSUInteger)scanAbility {
  NSUInteger abilities = 0;
  SDK *sdk = [SDK instance];
  
  vector<ICatchMode>::iterator mit;
  vector <ICatchCameraProperty>::iterator pit;
  
  vector<ICatchMode> vModes = [sdk retrieveSupportedCameraModes];
  for (mit = vModes.begin(); mit != vModes.end(); ++mit) {
    switch (*mit) {
      case ICATCH_MODE_CAMERA:
        abilities |= WifiCamAbilityStillCapture;
        break;
      case ICATCH_MODE_VIDEO:
        abilities |= WifiCamAbilityMovieRecord;
        break;
      case ICATCH_MODE_TIMELAPSE:
        AppLog(@"ICATCH_MODE_TIMELAPSE");
        abilities |= WifiCamAbilityTimeLapse;
        break;
        
      default:
        break;
    }
  }
  vector <ICatchCameraProperty> vCaps = [sdk retrieveSupportedCameraCapabilities];
  for (pit = vCaps.begin(); pit != vCaps.end(); ++pit) {
    switch (*pit) {
      case ICH_CAP_WHITE_BALANCE:
        abilities |= WifiCamAbilityWhiteBalance;
        break;
        
      case ICH_CAP_CAPTURE_DELAY:
        if ((abilities & WifiCamAbilityStillCapture) == WifiCamAbilityStillCapture) {
          abilities |= WifiCamAbilityDelayCapture;
        }
        break;
        
      case ICH_CAP_IMAGE_SIZE:
        if ((abilities & WifiCamAbilityStillCapture) == WifiCamAbilityStillCapture) {
          abilities |= WifiCamAbilityImageSize;
        }
        break;
        
      case ICH_CAP_VIDEO_SIZE:
        if ((abilities & WifiCamAbilityMovieRecord) == WifiCamAbilityMovieRecord) {
          abilities |= WifiCamAbilityVideoSize;
        }
        break;
        
      case ICH_CAP_LIGHT_FREQUENCY:
        abilities |= WifiCamAbilityLightFrequency;
        break;
        
      case ICH_CAP_BATTERY_LEVEL:
        abilities |= WifiCamAbilityBatteryLevel;
        break;
        
      case ICH_CAP_PRODUCT_NAME:
        abilities |= WifiCamAbilityProductName;
        break;
        
      case ICH_CAP_FW_VERSION:
        abilities |= WifiCamAbilityFWVersion;
        break;
        
      case ICH_CAP_BURST_NUMBER:
        abilities |= WifiCamAbilityBurstNumber;
        break;
        
      case ICH_CAP_DATE_STAMP:
        abilities |= WifiCamAbilityDateStamp;
        break;
        
      case ICH_CAP_UPSIDE_DOWN:
        AppLog(@"ICH_CAP_UPSIDE_DOWN");
        abilities |= WifiCamAbilityUpsideDown;
        break;
        
      case ICH_CAP_SLOW_MOTION:
        AppLog(@"ICH_CAP_SLOW_MOTION");
        abilities |= WifiCamAbilitySlowMotion;
        break;
        
      case ICH_CAP_DIGITAL_ZOOM:
        abilities |= WifiCamAbilityZoom;
        break;
        
      case ICH_CAP_TIMELAPSE_STILL:
        abilities |= WifiCamAbilityStillTimelapse;
        break;
        
      case ICH_CAP_TIMELAPSE_VIDEO:
        abilities |= WifiCamAbilityVideoTimelapse;
        break;
        
      case ICH_CAP_UNDEFINED:
      default:
        abilities |= [self catCustomAbility:abilities prop:*pit];
        break;
    }
    
  }
  
  return abilities;
}

+ (NSUInteger)catCustomAbility: (NSUInteger)mainAbility prop:(ICatchCameraProperty)prop{
  SDK *sdk = [SDK instance];
  NSUInteger abilities = mainAbility;
  
  // Customize property
  // Date-Time Synchronization
  if (prop == 0x5011) {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyyMMdd"];
    NSString *dateTime = [dateformatter stringFromDate:date];
    [dateformatter setDateFormat:@"HHmmss.S"];
    dateTime = [dateTime stringByAppendingString:@"T"];
    dateTime = [dateTime stringByAppendingString:[dateformatter stringFromDate:date]];
    AppLog(@"current data & time : %@", dateTime);
    
    [sdk setCustomizeStringProperty:0x5011 value:dateTime];
    
  } else if (prop == 0xD83C) {
    AppLog(@"Enable to change SSID string.");
    abilities |= WifiCamAbilityChangeSSID;
  } else if (prop == 0xD83D) {
    AppLog(@"Enable to change Wi-Fi Password.");
    abilities |= WifiCamAbilityChangePwd;
  } else if (prop == 0xD7F0) {
    AppLog(@"Choose the latest delay capture method");
    abilities |= WifiCamAbilityLatestDelayCapture;
    [sdk setCustomizeIntProperty:prop value:1];
  } else if (prop == 0xD7FD) {
    AppLog(@"Get movie recorded time");
    abilities |= WifiCamAbilityGetMovieRecordedTime;
  }
  
  return abilities;
}

@end
