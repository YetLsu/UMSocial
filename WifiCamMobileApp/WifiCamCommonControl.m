//
//  WifiCamCommonControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamCommonControl.h"
// struct statfs
#include <sys/param.h>
#include <sys/mount.h>

@implementation WifiCamCommonControl


- (void)addObserver:(ICatchEventID)eventTypeId
           listener:(ICatchWificamListener *)listener
        isCustomize:(BOOL)isCustomize {
  AppLog(@"listener: %p", listener);
  [[SDK instance] addObserver:eventTypeId listener:listener isCustomize:isCustomize];
}

- (void)removeObserver:(ICatchEventID)eventTypeId
              listener:(ICatchWificamListener *)listener
           isCustomize:(BOOL)isCustomize {
  [[SDK instance] removeObserver:eventTypeId listener:listener isCustomize:isCustomize];
}

- (void)scheduleLocalNotice:(NSString *)message
{
  UIApplication  *app = [UIApplication sharedApplication];
  UILocalNotification *alarm = [[UILocalNotification alloc] init];
  if (alarm) {
    alarm.fireDate = [NSDate date];
    alarm.timeZone = [NSTimeZone defaultTimeZone];
    alarm.repeatInterval = 0;
    alarm.alertBody = message;
    alarm.soundName = UILocalNotificationDefaultSoundName;
    
    [app scheduleLocalNotification:alarm];
  }
}

- (double)freeDiskSpaceInKBytes
{
  struct statfs buf;
  long long freeSpace = -1;
  if (statfs("/var", &buf) >= 0) {
    freeSpace = buf.f_bsize * buf.f_bfree / 1024 - 204800; // Minus 200MB to adjust the true size
  }
  
  return freeSpace;
}

-(NSString *)translateSize:(unsigned long long)sizeInKB
{
  NSString *humanDownloadFileSize = nil;
  double temp = (double)sizeInKB/1024; // MB
  if (temp > 1024) {
    temp /= 1024;
    humanDownloadFileSize = [NSString stringWithFormat:@"%.2fGB", temp];
  } else {
    humanDownloadFileSize = [NSString stringWithFormat:@"%.2fMB", temp];
  }
  return humanDownloadFileSize;
}


@end
