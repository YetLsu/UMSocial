//
//  Channel.h
//  elf_share
//
//  Created by elecfreaks on 15/7/2.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Settings;

#define kKeyChannelName @"Name"
#define kKeyChannelIsReversed @"IsReversed"
#define kKeyChannelTrimValue @"TrimValue"
#define kKeyChannelOutputAdjustableRange @"OutputAdjustableRange"
#define kKeyChannelDefaultOutputValue @"DefaultOutputValue"

#define kChannelNameAileron @"Aileron"
#define kChannelNameElevator @"Elevator"
#define kChannelNameRudder @"Rudder"
#define kChannelNameThrottle @"Throttle"
#define kChannelNameAUX1 @"AUX1"
#define kChannelNameAUX2 @"AUX2"
#define kChannelNameAUX3 @"AUX3"
#define kChannelNameAUX4 @"AUX4"

@interface Channel : NSObject

@property(nonatomic, readonly) NSString *name;

@property(nonatomic, assign) BOOL isReversing;

@property(nonatomic, assign) float trimValue;

@property(nonatomic, assign) float outputAdjustableRange;

@property(nonatomic, assign) float defaultOutputValue;

@property(nonatomic, assign) float  value;

@property(nonatomic, assign) int index;

@property(nonatomic, assign) Settings *ownerSettings;

-(id)initWithSetting:(Settings *)setting idx:(int) index;

@end
