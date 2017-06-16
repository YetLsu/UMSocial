//
//  Channel.m
//  elf_share
//
//  Created by elecfreaks on 15/7/2.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "Channel.h"
#import "Transmitter.h"
#import "util.h"
#import "Settings.h"

@interface Channel()

@property(nonatomic, retain) NSMutableDictionary *data;

@end
@implementation Channel

@synthesize data = _data;
@synthesize name = _name;
@synthesize isReversing = _isReversing;
@synthesize trimValue = _trimValue;
@synthesize outputAdjustableRange = _outputAdjustableRange;
@synthesize defaultOutputValue = _defaultOutputValue;
@synthesize value = _value;
@synthesize index = _index;
@synthesize ownerSettings = _ownerSettings;

-(id)initWithSetting:(Settings *)setting idx:(int)index {
    self = [super init];
    if(self){

        _ownerSettings = setting;
        _index = index;
        
        _data = [[setting.settingData valueForKey:kKeySettingsChannels] objectAtIndex:index];
        
        _name = [_data valueForKey:kKeyChannelName];
        _isReversing = [[_data valueForKey:kKeyChannelIsReversed] boolValue];
        _trimValue = [[_data valueForKey:kKeyChannelTrimValue] floatValue];
        _outputAdjustableRange = [[_data valueForKey:kKeyChannelOutputAdjustableRange] floatValue];
        _defaultOutputValue = [[_data valueForKey:kKeyChannelDefaultOutputValue] floatValue];
//        NSLog(@"_defaultOutputValue = %f",_defaultOutputValue);
        [self setValue:_defaultOutputValue];
    }
    return self;
}

-(void)setValue:(float)value {
    _value = clip(value, -1.0, 1.0);
    float outputValue = clip(value + _trimValue, -1.0, 1.0);
    if(_isReversing) {
        outputValue = -outputValue;
    }
    
    outputValue *= _outputAdjustableRange;
    [[Transmitter sharedTransmitter] setPpmValue:outputValue atChannel:_index];
}

-(void)setIsReversing:(BOOL)isReversing {
    _isReversing = isReversing;
    [_data setValue:[NSNumber numberWithBool:isReversing] forKey:kKeyChannelIsReversed];
}

-(void)setTrimValue:(float)trimValue {
    _trimValue = trimValue;
    [_data setValue:[NSNumber numberWithFloat:trimValue] forKey:kKeyChannelTrimValue];
}

-(void)setOutputAdjustableRange:(float)outputAdjustableRange {
    _outputAdjustableRange = outputAdjustableRange;
    [_data setValue:[NSNumber numberWithFloat:outputAdjustableRange] forKey:kKeyChannelOutputAdjustableRange];
}

-(void)setDefaultOutputValue:(float)defaultOutputValue {
    _defaultOutputValue = defaultOutputValue;
    [_data setValue:[NSNumber numberWithFloat:defaultOutputValue] forKey:kKeyChannelDefaultOutputValue];
}
@end
