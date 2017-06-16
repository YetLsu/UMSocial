//
//  OSDCommon.c
//  UdpEchoClient
//
//  Created by koupoo on 13-3-1.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#include "OSDCommon.h"
#include <vector>
#include <string>

#define kOsdInfoRequestListLen 2

using namespace std;



/*MSP_ATTITUDE
*/

//int mainInfoRequest[kOsdInfoRequestListLen]  = {MSP_IDENT, MSP_MOTOR_PINS, MSP_STATUS, MSP_RAW_IMU, MSP_SERVO, MSP_MOTOR, MSP_RC, MSP_RAW_GPS, MSP_COMP_GPS, MSP_ALTITUDE,MSP_ATTITUDE, MSP_BAT, MSP_DEBUG};
//int mainInfoRequest[kOsdInfoRequestListLen] = {MSP_RAW_GPS, MSP_COMP_GPS, MSP_ALTITUDE,MSP_BAT,MSP_ATTITUDE};



#ifdef __cplusplus
extern "C"{
#endif

/*向串口中发送请求
 *@param msp 所要发送的请求
 */
void sendRequestMSP(const vector<byte>& msp) {
  //  serialCon->write(msp); // send the complete byte sequence in one go
}





NSData *getSimpleCommand(unsigned char commandName){
    unsigned char package[6];

    package[0] = '$';
    package[1] = 'M';
    package[2] = '<';
    package[3] = 0;
    package[4] = commandName;
    
    unsigned char checkSum = 0;
    
    int dataSizeIdx = 3;
    int checkSumIdx = 5;
    
    checkSum ^= (package[dataSizeIdx] & 0xFF);
    checkSum ^= (package[dataSizeIdx + 1] & 0xFF);
    
    package[checkSumIdx] = checkSum;
    return [NSData dataWithBytes:package length:6];
}
    
    
#ifdef __cplusplus
}
#endif



