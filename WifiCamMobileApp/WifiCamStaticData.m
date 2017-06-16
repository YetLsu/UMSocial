//
//  WifiCamStaticData.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamStaticData.h"


@implementation WifiCamStaticData


+ (WifiCamStaticData *)instance {
  static WifiCamStaticData *instance = nil;
  /*
   @synchronized(self) {
   if(!instance) {
   instance = [[self alloc] init];
   }
   }
   */
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ instance = [[self alloc] initSingleton]; });
  return instance;
}

- (id)init {
  // Forbid calls to –init or +new
  //NSAssert(NO, @"Cannot create instance of Singleton");
  
  // You can return nil or [self initSingleton] here,
  // depending on how you prefer to fail.
  return [self initSingleton];
}

// Real (private) init method
- (id)initSingleton {
  if (self = [super init]) {
    // Init code
    //_session = new ICatchWificamSession();
  }
  return self;
}


#pragma mark - Global static table
-(NSDictionary *)captureDelayDict
{
  return @{@(CAP_DELAY_NO):@"Off",
           @(CAP_DELAY_2S):@"2s",
           @(5000):@"5s",
           @(CAP_DELAY_10S):@"10s"};
}

-(NSDictionary *)videoSizeDict
{
  return @{@"1920x1080 60":@[@"FHD60", @"1080P 60fps"],
           @"1920x1080 30":@[@"FHD30", @"1080P 30fps"],
           @"1280x720 120":@[@"HD120", @"720P 120fps"],
           @"1280x720 60": @[@"HD60", @"720P 60fps"],
           @"1280x720 30": @[@"HD30", @"720P 30fps"],
           @"1920x1440 30":@[@"FHD", @"1440P 30fps"],
           @"640x480 120": @[@"VGA120", @"480P 120fps"],
           @"640x480 30": @[@"VGA30", @"480P 30fps"],
           @"3840x2160 10": @[@"4K2K", @"4K2K 10fps(No Preview)"],
           @"2704x1524 15": @[@"2.7K", @"2.7K 15fps(No Preview)"]};
}

-(NSDictionary *)imageSizeDict
{
  return @{@"4640x3480":@"16M",
           @"3264x2448":@"8M",
           @"2560x1920":@"5M",
           @"2304x1728":@"4M",
           @"640x480":@"VGA"};
}

-(NSDictionary *)awbDict
{
  return @{@(WB_AUTO):@"awb_auto",
           @(WB_CLOUDY):@"awb_cloudy",
           @(WB_DAYLIGHT):@"awb_daylight",
           @(WB_FLUORESCENT):@"awb_fluoresecent",
           @(WB_TUNGSTEN):@"awb_incadescent"};
}

-(NSDictionary *)burstNumberDict
{
  return @{@(BRUST_NUMBER_HS):@(0),
           @(BURST_NUMBER_10):@(10),
           @(BURST_NUMBER_5):@(5),
           @(BURST_NUMBER_3):@(3)};
}

-(NSDictionary *)delayCaptureDict
{
  
  return @{@(CAP_DELAY_NO):@(0),
           @(CAP_DELAY_2S):@(3),
           @(5000):@(9),
           @(CAP_DELAY_10S):@(19)};
   /*
  return @{@(CAP_DELAY_NO):@(0),
           @(CAP_DELAY_2S):@(1.5),
           @(5000):@(4.5),
           @(CAP_DELAY_10S):@(9.5)};
   */
}

-(NSDictionary *)whiteBalanceDict
{
  return @{@(WB_AUTO):NSLocalizedString(@"SETTING_AWB_AUTO", @""),
           @(WB_CLOUDY):NSLocalizedString(@"SETTING_AWB_CLOUDY", @""),
           @(WB_DAYLIGHT):NSLocalizedString(@"SETTING_AWB_DAYLIGHT", @""),
           @(WB_FLUORESCENT):NSLocalizedString(@"SETTING_AWB_FLUORESECENT", @""),
           @(WB_TUNGSTEN):NSLocalizedString(@"SETTING_AWB_INCANDESCENT", @"")};
}

-(NSDictionary *)burstNumberStringDict
{
  return @{@(BRUST_NUMBER_HS):@[NSLocalizedString(@"SETTING_BURST_HIGHEST_SPEED", nil), @""],
           @(BURST_NUMBER_OFF):@[NSLocalizedString(@"SETTING_BURST_OFF", nil), @""],
           @(BURST_NUMBER_3):@[NSLocalizedString(@"SETTING_BURST_3_PHOTOS", nil), @"continuous_shot_1"],
           @(BURST_NUMBER_5):@[NSLocalizedString(@"SETTING_BURST_5_PHOTOS", nil), @"continuous_shot_2"],
           @(BURST_NUMBER_10):@[NSLocalizedString(@"SETTING_BURST_10_PHOTOS", nil), @"continuous_shot_3"]};
}

-(NSDictionary *)powerFrequencyDict
{
  return @{@(LIGHT_FREQUENCY_50HZ):NSLocalizedString(@"SETTING_POWER_SUPPLY_50", nil),
           @(LIGHT_FREQUENCY_60HZ):NSLocalizedString(@"SETTING_POWER_SUPPLY_60", nil)};
}

-(NSDictionary *)dateStampDict
{
  return @{@(DATE_STAMP_OFF):NSLocalizedString(@"SETTING_DATESTAMP_OFF", nil),
           @(DATE_STAMP_DATE):NSLocalizedString(@"SETTING_DATESTAMP_DATE", nil),
           @(DATE_STAMP_DATE_TIME):NSLocalizedString(@"SETTING_DATESTAMP_DATE_TIME", nil)};
}

-(NSDictionary *)timelapseIntervalDict
{
  return @{@(0x0000):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_OFF", nil),
           @(0x0001):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_2_S", nil),
           @(0x0002):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_5_S", nil),
           @(0x0003):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_10_S", nil),
           @(0x0004):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_20_S", nil),
           @(0x0005):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_30_S", nil),
           @(0x0006):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_1_M", nil),
           @(0x0007):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_5_M", nil),
           @(0x0008):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_10_M", nil),
           @(0x0009):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_30_M", nil),
           @(0x000A):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_1_HR", nil),};
}

-(NSDictionary *)timelapseDurationDict
{
  return @{@(0x0001):NSLocalizedString(@"SETTING_CAP_TL_DURATION_OFF", nil),
           @(0x0002):NSLocalizedString(@"SETTING_CAP_TL_DURATION_5_M", nil),
           @(0x0003):NSLocalizedString(@"SETTING_CAP_TL_DURATION_10_M", nil),
           @(0x0004):NSLocalizedString(@"SETTING_CAP_TL_DURATION_15_M", nil),
           @(0x0005):NSLocalizedString(@"SETTING_CAP_TL_DURATION_20_M", nil),
           @(0x0006):NSLocalizedString(@"SETTING_CAP_TL_DURATION_30_M", nil),
           @(0x0007):NSLocalizedString(@"SETTING_CAP_TL_DURATION_60_M", nil),
           @(0xFFFF):NSLocalizedString(@"SETTING_CAP_TL_DURATION_Unlimited", nil)};
}


-(NSDictionary *)noFileNoticeDict
{
  return @{@(WCFileTypeImage):NSLocalizedString(@"NoPhotos", nil),
           @(WCFileTypeVideo):NSLocalizedString(@"NoVideos", nil),
           @(WCFileTypeAudio):NSLocalizedString(@"NoAudioFiles", nil),
           @(WCFileTypeText):NSLocalizedString(@"NoTextFiles", nil)};
}

@end
