//
//  Connection.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-2-19.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "Connection.h"


@implementation Reachability(Connection)

+ (BOOL)didConnectedToCameraHotspot
{
  return [self isReachable:[Reachability reachabilityForLocalWiFi]];
}

+ (BOOL)isReachable:(Reachability *)reachability
{
  NetworkStatus netStatus = [reachability currentReachabilityStatus];
  BOOL retVal = NO;
  
  switch (netStatus) {
    case NotReachable:
      AppLog(@"NotReachable");
      break;
      
    case ReachableViaWWAN:
      AppLog(@"ReachableViaWWAN");
      break;
      
    case ReachableViaWiFi:
      AppLog(@"ReachableViaWiFi");
      retVal = YES;
      break;
  }
  
  return retVal;
}

@end
