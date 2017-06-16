//
//  Settings.h
//  elf_share
//
//  Created by elecfreaks on 15/7/2.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Channel;

#define kKeySettingsInterfaceOpacity @"InterfaceOpacity"
#define kKeySettingsIsLeftHanded @"IsLeftHanded"
#define kKeySettingsIsAccMode @"IsAccMode"
#define kKeySettingsPpmPolarityIsNegative @"PpmPolarityIsNegative"
#define kKeySettingsIsHeadFreeMode @"IsHeadFreeMode"
#define kKeySettingsIsAltHoldMode @"IsAltHoldMode"
#define kKeySettingsIsBeginnerMode @"IsBeginnerMode"
#define kKeySettingsIsSelfMode     @"IsSelfMode"
#define kKeySettingsIsThrottleMode  @"IsThrottleMode"
#define kKeySettingsIsHDMode        @"IsHDMode"
#define kKeySettingsAileronDeadBand @"AileronDeadBand"
#define kKeySettingsElevatorDeadBand @"ElevatorDeadBand"
#define kKeySettingsRudderDeadBand @"RudderDeadBand"
#define kKeySettingsTakeOffThrottle @"TakeOffThrottle"
#define kKeySettingsRollPitchScale  @"RollPitchScale"
#define kKeySettingsYawScale        @"YawScale"
#define kKeySettingsChannels @"Channels"

@interface Settings : NSObject{
    NSString *_path;
    NSMutableArray *_channelArray;
}

@property(nonatomic, retain)NSMutableDictionary *settingData;

//改变一下值都不会自动保存到持久文件中，需要持久化，需要调用save方法

@property(nonatomic, assign) float interfaceOpacity;
@property(nonatomic, assign) BOOL isLeftHanded;
@property(nonatomic, assign) BOOL isAccMode;
@property(nonatomic, assign) BOOL isHeadFreeMode;
@property(nonatomic, assign) BOOL isAltHoldMode;
@property(nonatomic, assign) BOOL ppmPolarityIsNegative;
@property(nonatomic, assign) BOOL isBeginnerMode;
@property(nonatomic, assign) BOOL isSelfMode;
@property(nonatomic, assign) BOOL isThrottleMode;
@property(nonatomic, assign) BOOL isHDMode;
@property(nonatomic, assign) float aileronDeadBand;
@property(nonatomic, assign) float elevatorDeadBand;
@property(nonatomic, assign) float rudderDeadBand;
@property(nonatomic, assign) float takeOffThrottle;
@property(nonatomic, assign) float rollPitchScale;
@property(nonatomic, assign) float yawScale;

-(id)initWithSettingsFile:(NSString *)settingsFilePath;

-(int)channelCount;
-(Channel *)channelIndex:(int)i;
-(Channel *)channelByName:(NSString *)name;

-(void)changeChannelFrom:(int)from to:(int)to;


//存储
-(void)save;
-(void)resetToDefault;
@end
