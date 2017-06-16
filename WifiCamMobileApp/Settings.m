//
//  Settings.m
//  elf_share
//
//  Created by elecfreaks on 15/7/2.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "Settings.h"
#import "Channel.h"
@implementation Settings
@synthesize settingData = _settingData;
@synthesize interfaceOpacity = _interfaceOpacity;
@synthesize isLeftHanded = _isLeftHanded;
@synthesize ppmPolarityIsNegative = _ppmPolarityIsNegative;
@synthesize isHeadFreeMode = _isHeadFreeMode;
@synthesize isAltHoldMode = _isAltHoldMode;
@synthesize isBeginnerMode = _isBeginnerMode;
@synthesize isSelfMode = _isSelfMode;
@synthesize isThrottleMode = _isThrottleMode;
@synthesize isHDMode = _isHDMode;
@synthesize aileronDeadBand = _aileronDeadBand;
@synthesize elevatorDeadBand = _elevatorDeadBand;
@synthesize rudderDeadBand = _rudderDeadBand;
@synthesize takeOffThrottle = _takeOffThrottle;
@synthesize isAccMode = _isAccMode;
@synthesize rollPitchScale = _rollPitchScale;
@synthesize yawScale = _yawScale;

-(id)initWithSettingsFile:(NSString *)settingsFilePath {
    self = [super init];
    
    if(self){
        _path = settingsFilePath;
        
        _settingData = [[NSMutableDictionary alloc] initWithContentsOfFile:_path];
        _interfaceOpacity = [[_settingData objectForKey:kKeySettingsInterfaceOpacity]floatValue];
        _isLeftHanded = [[_settingData objectForKey:kKeySettingsIsLeftHanded]boolValue];
        _isAccMode = [[_settingData objectForKey:kKeySettingsIsAccMode]boolValue];
        _ppmPolarityIsNegative = [[_settingData objectForKey:kKeySettingsPpmPolarityIsNegative]boolValue];
        _isHeadFreeMode = [[_settingData objectForKey:kKeySettingsIsHeadFreeMode]boolValue];
        _isAltHoldMode = [[_settingData objectForKey:kKeySettingsIsAltHoldMode]boolValue];
        _isBeginnerMode = [[_settingData objectForKey:kKeySettingsIsBeginnerMode]boolValue];
        _isSelfMode = [[_settingData objectForKey:kKeySettingsIsSelfMode]boolValue];
        _isThrottleMode = [[_settingData objectForKey:kKeySettingsIsThrottleMode]boolValue];
        _isHDMode = [[_settingData objectForKey:kKeySettingsIsHDMode]boolValue];
        _aileronDeadBand = [[_settingData objectForKey:kKeySettingsAileronDeadBand]floatValue];
        _elevatorDeadBand = [[_settingData objectForKey:kKeySettingsElevatorDeadBand]floatValue];
        _rudderDeadBand = [[_settingData objectForKey:kKeySettingsRudderDeadBand]floatValue];
        _takeOffThrottle = [[_settingData objectForKey:kKeySettingsTakeOffThrottle]floatValue];
        _rollPitchScale = [[_settingData objectForKey:kKeySettingsRollPitchScale]floatValue];
        _yawScale = [[_settingData objectForKey:kKeySettingsYawScale]floatValue];
        NSArray *channelDataArray = [_settingData objectForKey:kKeySettingsChannels];
//        NSLog(@"channelDataArray = %@",channelDataArray);
        int channelCount = (int)[channelDataArray count];
        _channelArray = [[NSMutableArray alloc]initWithCapacity:channelCount];
        
        for(int channelIndex = 0;channelIndex < channelCount;channelIndex++) {
            Channel *channel = [[Channel alloc]initWithSetting:self idx:channelIndex];
            [_channelArray addObject:channel];
        }
    }
    
    return self;
}

-(void)setInterfaceOpacity:(float)interfaceOpacity {
    _interfaceOpacity = interfaceOpacity;
    [_settingData setObject:[NSNumber numberWithFloat:_interfaceOpacity] forKey:kKeySettingsInterfaceOpacity];
}

-(void)setIsLeftHanded:(BOOL)isLeftHanded {
    _isLeftHanded = isLeftHanded;
    [_settingData setObject:[NSNumber numberWithBool:_isLeftHanded] forKey:kKeySettingsIsLeftHanded];
}

-(void)setIsAccMode:(BOOL)isAccMode {
    _isAccMode = isAccMode;
    [_settingData setObject:[NSNumber numberWithBool:_isAccMode] forKey:kKeySettingsIsAccMode];
}

-(void)setIsHeadFreeMode:(BOOL)isHeadFreeMode {
    _isHeadFreeMode = isHeadFreeMode;
    [_settingData setObject:[NSNumber numberWithBool:_isHeadFreeMode] forKey:kKeySettingsIsHeadFreeMode];
}

-(void)setIsAltHoldMode:(BOOL)isAltHoldMode {
    _isAltHoldMode = isAltHoldMode;
    [_settingData setObject:[NSNumber numberWithBool:_isAltHoldMode] forKey:kKeySettingsIsAltHoldMode];
}

-(void)setIsBeginnerMode:(BOOL)isBeginnerMode {
    _isBeginnerMode = isBeginnerMode;
    [_settingData setObject:[NSNumber numberWithBool:_isBeginnerMode] forKey:kKeySettingsIsBeginnerMode];
}

-(void)setIsSelfMode:(BOOL)isSelfMode {
    _isSelfMode = isSelfMode;
    [_settingData setObject:[NSNumber numberWithBool:_isSelfMode] forKey:kKeySettingsIsSelfMode];
}

-(void)setIsThrottleMode:(BOOL)isThrottleMode {
    _isThrottleMode = isThrottleMode;
    [_settingData setObject:[NSNumber numberWithBool:_isThrottleMode] forKey:kKeySettingsIsThrottleMode];
}

-(void)setIsHDMode:(BOOL)isHDMode {
    _isHDMode = isHDMode;
    [_settingData setObject:[NSNumber numberWithBool:_isHDMode] forKey:kKeySettingsIsHDMode];
}

-(void)setPpmPolarityIsNegative:(BOOL)ppmPolarityIsNegative {
    _ppmPolarityIsNegative = ppmPolarityIsNegative;
    [_settingData setObject:[NSNumber numberWithBool:_ppmPolarityIsNegative] forKey:kKeySettingsPpmPolarityIsNegative];
}

-(void)setAileronDeadBand:(float)aileronDeadBand {
    _aileronDeadBand = aileronDeadBand;
    [_settingData setObject:[NSNumber numberWithFloat:_aileronDeadBand] forKey:kKeySettingsAileronDeadBand];
}

-(void)setElevatorDeadBand:(float)elevatorDeadBand {
    _elevatorDeadBand = elevatorDeadBand;
    [_settingData setObject:[NSNumber numberWithFloat:_elevatorDeadBand] forKey:kKeySettingsElevatorDeadBand];
}

-(void)setRudderDeadBand:(float)rudderDeadBand {
    _rudderDeadBand = rudderDeadBand;
    [_settingData setObject:[NSNumber numberWithFloat:_rudderDeadBand] forKey:kKeySettingsRudderDeadBand];
}

-(void)setTakeOffThrottle:(float)takeOffThrottle {
    _takeOffThrottle = takeOffThrottle;
    [_settingData setObject:[NSNumber numberWithFloat:_takeOffThrottle] forKey:kKeySettingsTakeOffThrottle];
}

-(void)setRollPitchScale:(float)rollPitchScale {
    _rollPitchScale = rollPitchScale;
    [_settingData setObject:[NSNumber numberWithFloat:_rollPitchScale] forKey:kKeySettingsRollPitchScale];
}

-(void)setYawScale:(float)yawScale {
    _yawScale = yawScale;
    [_settingData setObject:[NSNumber numberWithFloat:_yawScale] forKey:kKeySettingsYawScale];
}

-(void)save {
    [_settingData writeToFile:_path atomically:YES];
}

-(int)channelCount {
    return (int)[_channelArray count];
}

-(Channel *)channelIndex:(int)i {
    if(i < [_channelArray count]) {
        return [_channelArray objectAtIndex:i];
    }
    else{
        return nil;
    }
}

-(Channel *)channelByName:(NSString *)name {
    for(Channel *channel in _channelArray) {
        if([name isEqualToString:[channel name]]) {
            return channel;
        }
    }
    return nil;
}

-(void)changeChannelFrom:(int)from to:(int)to {
    Channel *channel = [_channelArray objectAtIndex:from];
    [_channelArray removeObjectAtIndex:from];
    [_channelArray insertObject:channel atIndex:to];
    
    NSMutableArray *channelDataArray = (NSMutableArray *)[_settingData valueForKey:kKeySettingsChannels];
    
    id channelData = [channelDataArray objectAtIndex:from];
    [channelDataArray removeObjectAtIndex:from];
    [channelDataArray insertObject:channelData atIndex:to];
    
    int idx = 0;
    for(Channel *oneChannel in _channelArray) {
        oneChannel.index = idx++;
    }
}

-(void)resetToDefault {
    NSString *defaultSettingsFilePath = [[NSBundle mainBundle]pathForResource:@"Setting" ofType:@"plist"];
    Settings *defaultSetting = [[Settings alloc]initWithSettingsFile:defaultSettingsFilePath];
    
    NSDictionary *defaultSettingsData = defaultSetting.settingData;
    
    self.interfaceOpacity = [[defaultSettingsData objectForKey:kKeySettingsInterfaceOpacity] floatValue];
    self.isLeftHanded = [[defaultSettingsData objectForKey:kKeySettingsIsLeftHanded] boolValue];
    self.isAccMode = [[defaultSettingsData objectForKey:kKeySettingsIsAccMode] boolValue];
    self.ppmPolarityIsNegative = [[defaultSettingsData objectForKey:kKeySettingsPpmPolarityIsNegative]boolValue];
    self.isHeadFreeMode = [[defaultSettingsData objectForKey:kKeySettingsIsHeadFreeMode]boolValue];
    self.isAltHoldMode = [[defaultSettingsData objectForKey:kKeySettingsIsAltHoldMode]boolValue];
    self.isBeginnerMode = [[defaultSettingsData objectForKey:kKeySettingsIsBeginnerMode]boolValue];
    self.isSelfMode = [[defaultSettingsData objectForKey:kKeySettingsIsSelfMode]boolValue];
    self.isThrottleMode = [[defaultSettingsData objectForKey:kKeySettingsIsThrottleMode]boolValue];
    self.isHDMode = [[defaultSettingsData objectForKey:kKeySettingsIsHDMode]boolValue];
    self.aileronDeadBand = [[defaultSettingsData objectForKey:kKeySettingsAileronDeadBand]floatValue];
    self.elevatorDeadBand = [[defaultSettingsData objectForKey:kKeySettingsElevatorDeadBand]floatValue];
    self.rudderDeadBand = [[defaultSettingsData objectForKey:kKeySettingsRudderDeadBand]floatValue];
    self.takeOffThrottle = [[defaultSettingsData objectForKey:kKeySettingsTakeOffThrottle]floatValue];
    self.rollPitchScale = [[defaultSettingsData objectForKey:kKeySettingsRollPitchScale]floatValue];
    self.yawScale = [[defaultSettingsData objectForKey:kKeySettingsYawScale]floatValue];
    
    int channelCount = [defaultSetting channelCount];
    
    for(int defaultChannelIndex = 0;defaultChannelIndex < channelCount;defaultChannelIndex++) {
        Channel *defaultChannel = [[Channel alloc]initWithSetting:defaultSetting idx:defaultChannelIndex];
        
        Channel *channel = [self channelByName:defaultChannel.name];
        if(channel.index != defaultChannelIndex) {
            Channel *needsReordedChannel = [_channelArray objectAtIndex:defaultChannelIndex];
            needsReordedChannel.index = channel.index;
            
            [_channelArray exchangeObjectAtIndex:defaultChannelIndex withObjectAtIndex:channel.index];
            channel.index = defaultChannelIndex;
        }
        
        channel.isReversing = defaultChannel.isReversing;
        channel.trimValue = defaultChannel.trimValue;
        channel.outputAdjustableRange = defaultChannel.outputAdjustableRange;
        channel.defaultOutputValue = defaultChannel.defaultOutputValue;
        channel.value = defaultChannel.defaultOutputValue;
    }
}

@end













