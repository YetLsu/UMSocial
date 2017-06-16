//
//  Connection.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-2-19.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface Reachability(Connection)
+ (BOOL)didConnectedToCameraHotspot;
@end
