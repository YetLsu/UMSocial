//
//  OSDData.h
//  UdpEchoClient
//
//  Created by koupoo on 13-2-28.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OSDData;

@protocol OSDDataDelegate <NSObject>

//- (void)OSDDataDidUpdateTimeOut:(OSDData *)osdData;

- (void)osdDataDidUpdateOneFrame:(OSDData *)osdData;

@end

typedef enum {
    ARMStateOK = 0,
    ARMingStateOK = 1,
    DISARMStateOK = 2,
}ARMState;

#define kNotificationLockStateDidChange @"NotificationLockStateDidChange"
#define kNotificationArmStateDidChange @"NotificationArmStateDidChange"
#define kNotificationArmingStateDidChange @"NotificationArmingStateDidChange"
#define kNotificationDisarmStateDidChange @"NotificationDisarmStateDidChange"


#define kMainNotificationArmStateDidChange @"MainNotificationArmStateDidChange"
#define kMainNotificationArmingStateDidChange @"MainNotificationArmingStateDidChange"
#define kMainNotificationDisarmStateDidChange @"MainNotificationDisarmStateDidChange"

#define kMainNotificationPowerValueDidChange @"MainNotificationPowerValueDidChange"
#define kControlNotificationPowerValueDidChange @"ControlNotificationPowerValueDidChange"

#define kMainGetVersionDidChange @"MainNotificationGetVersionDidChange"
#define kControlGetVersionDidChange @"ControlNotificationGetVersionDidChange"

#define kMainTakeOffDidChange   @"MainNotificationTakeOffDidChange"
#define kControlTakeOffDidChange @"ControlNotificationTakeOffDidChange"

#define kMainLandDidChange      @"MainNotificationLandDidChange"
#define kControlLandDidChange   @"ControlNotificationLandDidChange"

#define kSetCalibrationDidChange @"SetCalibrationDidChange"

extern int PowerValue;
extern int VersionNum;
extern int Process;

@interface OSDData : NSObject{
    int present;
}


@property(nonatomic, assign) ARMState armState;
@property(nonatomic, readonly) int version;

@property(nonatomic, readonly) int multiType;

@property(nonatomic, readonly) float gyroX;
@property(nonatomic, readonly) float gyroY;
@property(nonatomic, readonly) float gyroZ;

@property(nonatomic, readonly) float accX;
@property(nonatomic, readonly) float accY;
@property(nonatomic, readonly) float accZ;

@property(nonatomic, readonly) float magX;
@property(nonatomic, readonly) float magY;
@property(nonatomic, readonly) float magZ;

@property(nonatomic, readonly) float altitude;
@property(nonatomic, readonly) float head;
@property(nonatomic, readonly) float angleX;
@property(nonatomic, readonly) float angleY;

@property(nonatomic, readonly) int gpsSatCount;
@property(nonatomic, readonly) int gpsLongitude;
@property(nonatomic, readonly) int gpsLatitude;
@property(nonatomic, readonly) int gpsAltitude;
@property(nonatomic, readonly) int gpsDistanceToHome;
@property(nonatomic, readonly) int gpsDirectionToHome;
@property(nonatomic, readonly) int gpsFix;
@property(nonatomic, readonly) int gpsUpdate;
@property(nonatomic, readonly) int gpsSpeed;

@property(nonatomic, readonly) float rcThrottle;
@property(nonatomic, readonly) float rcYaw;
@property(nonatomic, readonly) float rcRoll;
@property(nonatomic, readonly) float rcPitch;
@property(nonatomic, readonly) float rcAux1;
@property(nonatomic, readonly) float rcAux2;
@property(nonatomic, readonly) float rcAux3;
@property(nonatomic, readonly) float rcAux4;

@property(nonatomic, readonly) float debug1;
@property(nonatomic, readonly) float debug2;
@property(nonatomic, readonly) float debug3;
@property(nonatomic, readonly) float debug4;


@property(nonatomic, readonly) int pMeterSum;
@property(nonatomic, readonly) int byteVbat;

@property(nonatomic, readonly) int cycleTime;
@property(nonatomic, readonly) int i2cError;

@property(nonatomic, readonly) int mode;
@property(nonatomic, readonly) int present;

//@property(nonatomic, readwrite) int powerValue;


@property(nonatomic, assign) id<OSDDataDelegate> delegate;

- (id)initWithOSDData:(OSDData *)osdData;
- (void)DecodeRawData:(NSData *)data;
- (void)print;
//- (int)PowerValue;

@end
