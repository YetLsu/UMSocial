//
//  OSDData.m
//  UdpEchoClient
//
//  Created by koupoo on 13-2-28.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//


#import "OSDData.h"
#include "OSDCommon.h"
#include <vector>
#include <string>

#include "myTabBarController.h"

using namespace std;

#define OSD_UPDATE_REQUEST_FREQ 50

#define IDLE         0
#define HEADER_START 1
#define HEADER_M     2
#define HEADER_ARROW 3
#define HEADER_SIZE  4
#define HEADER_CMD   5
#define HEADER_ERR   6




int PowerValue;
int VersionNum;
int Process;//Calibration process


@interface OSDData(){
    int c_state;
    bool err_rcvd;
    byte checksum;
    byte cmd;
    int offset, dataSize;
    byte inBuf[256];
    int p;
    
    
    float mot[8], servo[8];
    long currentTime,mainInfoUpdateTime,attitudeUpdateTime;
}

@end

@implementation OSDData


@synthesize present;
@synthesize delegate = _delegate;
@synthesize armState = _armState;
//@synthesize powerValue = _powerValue;
- (id)init{
    if(self =[super init]){
        _armState = DISARMStateOK;
    }
    
    return self;
}

- (id)initWithOSDData:(OSDData *)osdData{
    if(self = [super init]){
//        _powerValue = osdData.powerValue;
    }
    
    return self;
}

//-(int)PowerValue {
//    NSLog(@"_powerValue = %d",_powerValue);
//    return _powerValue;
//}

- (Float32)read32{
    
    return (inBuf[p++]&0xff) + ((inBuf[p++]&0xff)<<8) + ((inBuf[p++]&0xff)<<16) + ((inBuf[p++]&0xff)<<24);
}

- (float)int32ToFloat:(int)intNum{
    float floatNum;
    
    memcpy((void *)(&floatNum), (void *)(&intNum), 4);
    
    return floatNum;
}

- (int16_t)read16{
    return (inBuf[p++]&0xff) + ((inBuf[p++])<<8);
}

- (int)read8 {
    return inBuf[p++]&0xff;
}

- (void)DecodeRawData:(NSData *)data{

//    NSLog(@"start here");
    int byteCount = (int)data.length;
    
    byte * dataPtr = (byte *)data.bytes;
    
    int idx;
    byte c;
    
    for (int byteIdx = 0; byteIdx < byteCount; byteIdx++) {
        c = dataPtr[byteIdx];
//        NSLog(@"c[%d] = %02x",byteIdx,c);
        if (c_state == IDLE) {
            c_state = (c=='$') ? HEADER_START : IDLE;
        } else if (c_state == HEADER_START) {
            c_state = (c=='M') ? HEADER_M : IDLE;
        } else if (c_state == HEADER_M) {
//            if (c == '>') {
            if (c == '>') {
                c_state = HEADER_ARROW;
            } else if (c == '!') {
                c_state = HEADER_ERR;
            } else {
                c_state = IDLE;
            }
        } else if (c_state == HEADER_ARROW || c_state == HEADER_ERR) {
            /* is this an error message? */
            err_rcvd = (c_state == HEADER_ERR);        /* now we are expecting the payload size */
            dataSize = (c&0xFF);
            /* reset index variables */
            p = 0;
            offset = 0;
            checksum = 0;
            checksum ^= (c&0xFF);
            /* the command is to follow */
            c_state = HEADER_SIZE;
        } else if (c_state == HEADER_SIZE) {
            cmd = (byte)(c&0xFF);
            checksum ^= (c&0xFF);
            c_state = HEADER_CMD;
        } else if (c_state == HEADER_CMD && offset < dataSize) {
            checksum ^= (c&0xFF);
            inBuf[offset++] = (byte)(c&0xFF);
        } else if (c_state == HEADER_CMD && offset >= dataSize) {
            /* compare calculated and transferred checksum */
            if ((checksum&0xFF) == (c&0xFF)) {
                if (err_rcvd) {
                    //printf("Copter did not understand request type %d\n", c);
                     c_state = IDLE;
                    
                } else {
                    /* we got a valid response packet, evaluate it */
                    [self evaluateCommand:cmd dataSize:dataSize];
                }
            } else {
                printf("invalid checksum for command %d: %d expected, got %d\n", ((int)(cmd&0xFF)), (checksum&0xFF), (int)(c&0xFF));
                printf("<%d %d> {",(cmd&0xFF), (dataSize&0xFF));
                
                for (idx = 0; idx < dataSize; idx++) {
                    if (idx != 0) { 
                        printf(" ");   
                    }
                    printf("%d",(inBuf[idx] & 0xFF));
                }
                
                printf("} [%d]\n", c);
                
                string data((char *)inBuf, dataSize);
                
                printf("%s\n", data.c_str());
                
            }
            c_state = IDLE;
        }

    }
}

- (void)evaluateCommand:(byte)cmd_ dataSize:(int)DataSize{
//    NSLog(@"evaluateCommand");
    int icmd = (int)(cmd_ & 0xFF);
    switch(icmd) {
        case MSP_BATTERY_VOLTAGE:
//            NSLog(@"check battery voltage");
//            NSLog(@"powerValue = %d",[self read8]);
//            _powerValue = [self read8];
            PowerValue = [self read8];
//            NSLog(@"powerValue = %d",PowerValue);
            [self sendMainPowerValueDidChangeNotification];
            [self sendControlPowerValueDidChangeNotification];
            break;
        case MSP_ARM:
            NSLog(@"---  _ARM");
//            _armState = ARMStateOK;
//            NSLog(@"_armState = %d",_armState);
//            [self sendLockStateDidChangeNotification];
            Arm_status = 1;
            [self sendArmStateDidChangeNotification];
            [self sendMainArmStateDidChangeNotification];
//            NSLog(@"MSP_ARM.........");
//            NSLog(@"Arm_status = %d",Arm_status);
            //unlock
            //TODO add notification
            break;
        case MSP_ARMING:
            NSLog(@"--- _ARMING");
//            _armState = ARMingStateOK;
//            NSLog(@"_armState = %d",_armState);
//            [self sendLockStateDidChangeNotification];
            [self sendArmingStateDidChangeNotification];
            [self sendMainArmingStateDidChangeNotification];
//            NSLog(@"MSP_ARMING......");
            break;
        case MSP_DISARM:
            NSLog(@"--- _DISARM");
//            _armState = DISARMStateOK;
//            NSLog(@"_armState = %d",_armState);
//            [self sendLockStateDidChangeNotification];
            //lock
            //TODO add notification
            Arm_status = 0;
            [self sendDisarmStateDidChangeNotification];
            [self sendMainDisarmStateDidChangeNotification];
//            NSLog(@"MSP_DISARM......");
//            NSLog(@"Arm_status = %d",Arm_status);
            break;
        case MSP_GET_VERSION:
            NSLog(@"get Version");
//            NSLog(@"xxx = %d",[self read8]);
            VersionNum = [self read8];
            [self sendMainGetVersionNotification];
            [self sendControlGetVersionNotification];
            break;
        case MSP_TAKEOFF_FINISH:
            NSLog(@"take-off ok");
            TakeOff_status = 1;//一键起飞完成
            [self sendMainTakeOffNotification];
            [self sendControlTakeOffNotification];
            break;
        case MSP_LANDING_FINISH:
            NSLog(@"landing finish ok");
            TakeOff_status = 0;
            [self sendMainLandNotification];
            [self sendControlLandNotification];
            break;
        case MSP_CALIBRATION:
            NSLog(@"CaliBration...");
            Process = [self read8];
            NSLog(@"Process = %d",Process);
            [self sendSetCalibrationDidChangeNotification];
            break;
        default:
            printf("\n***error: Don't know how to handle reply:%d\n datasize:%d", icmd, DataSize);
            break;
           
    }
}

-(void)sendMainTakeOffNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainTakeOffDidChange object:self userInfo:nil];
}

-(void)sendControlTakeOffNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kControlTakeOffDidChange object:self userInfo:nil];
}

-(void)sendMainLandNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainLandDidChange object:self userInfo:nil];
}

-(void)sendControlLandNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kControlLandDidChange object:self userInfo:nil];
}

- (void)sendLockStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationLockStateDidChange object:self userInfo:nil];
}

- (void)sendArmStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationArmStateDidChange object:self userInfo:nil];
}

- (void)sendArmingStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationArmingStateDidChange object:self userInfo:nil];
}

- (void)sendDisarmStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDisarmStateDidChange object:self userInfo:nil];
}

- (void)sendMainArmStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainNotificationArmStateDidChange object:self userInfo:nil];
}

- (void)sendMainGetVersionNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainGetVersionDidChange object:self userInfo:nil];
}

- (void)sendControlGetVersionNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kControlGetVersionDidChange object:self userInfo:nil];
}


- (void)sendMainArmingStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainNotificationArmingStateDidChange object:self userInfo:nil];
}

- (void)sendMainDisarmStateDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainNotificationDisarmStateDidChange object:self userInfo:nil];
}

- (void)sendMainPowerValueDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainNotificationPowerValueDidChange object:self userInfo:nil];
}

- (void)sendControlPowerValueDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kControlNotificationPowerValueDidChange object:self userInfo:nil];
}

- (void)sendSetCalibrationDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSetCalibrationDidChange object:self userInfo:nil];
}

- (void)print {
    NSLog(@"printfxxxxxxxx");
}

@end
