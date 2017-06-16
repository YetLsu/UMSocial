//
//  PPMTransmitter.h
//  RCTouch
//
//  Created by koupoo on 13-3-15.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BleSerialManager.h"
#import "OSDData.h"
enum PpmPolarity {
    PPM_POLARITY_POSITIVE,
    PPM_POLARITY_NEGATIVE
};

typedef enum {
    TransmitterStateError = 0,
    TransmitterStateOk = 1,
}TransmitterState;


#define kNotificationTransmitterStateDidChange @"NotificationTransmitterStateDidChange"
#define kNotificationBluetoothLinkDidChange @"NotificationBluetoothLinkDidChange"
//#define kNotificationLockStateDidChange @"NotificationLockStateDidChange"

@interface Transmitter: NSObject < BleSerialManagerDelegate,OSDDataDelegate> {
    OSDData *osdData;
}

+ (Transmitter *)sharedTransmitter;

//以下的方法均非线程安全
- (BOOL)start;
- (BOOL)stop;
- (void)setPpmValue:(float)value atChannel:(int)channelIdx;

- (BOOL)isConnected;

- (BOOL)transmmitData:(NSData *)data;
- (BOOL)transmmitSimpleCommand:(unsigned char)commandName;

- (BleSerialManager *)bleSerialManager;
//-(int)PowerValue;

@property(nonatomic, assign) TransmitterState outputState;
@property(nonatomic, assign) TransmitterState inputState ;
//@property(nonatomic, readonly) int powerValue;

@property(nonatomic, strong) OSDData *osdData;

@end
