//
//  BleSerialManager.m
//  RCTouch
//
//  Created by koupoo on 13-4-17.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import "BleSerialManager.h"
#import <AudioToolbox/AudioToolbox.h>
#define kServiceID               @"fff0"
#define kSerialService           0xFFF0
#define kSerialCharacteristic    0xFFF1
#define kSerialNotify            0xFFF4

@interface BleSerialManager(){
    BOOL isTryingConnect;
    CBCharacteristic  *serialCharacteristic;
}

@end

@implementation BleSerialManager

- (id)init{
    if(self = [super init]){
       _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
       _bleSerialList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isConnected{
    //return [_currentBleSerial isConnected];
    return _currentBleSerial.state == CBPeripheralStateConnected;
    
}
//扫描时调用kNotificationPeripheralListDidChange
- (void)scan{
    if (_isAvailabel == YES && _isScanning == NO) {
        _isScanning = YES;
        
        [(NSMutableArray *)_bleSerialList removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPeripheralListDidChange object:self userInfo:nil];
        if ([_delegate respondsToSelector:@selector(bleSerialManager:didDiscoverBleSerial:)]) {
            [_delegate bleSerialManager:self didDiscoverBleSerial:nil];
        }
        //CBUUID *serialServiceUUID = [self getSerialServiceUUID];//get service UUID
        //NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CBCentralManagerScanOptionAllowDuplicatesKey, @"YES", nil];
        //NSLog(@"options :%@",options);
       // [_centralManager scanForPeripheralsWithServices:[NSArray arrayWithObject:serialServiceUUID]
                                                    //options:options];
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        
//        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        NSLog(@"Scanning started");
    }
}

-(void)stopScan{
    if (_centralManager != nil) {
        [_centralManager stopScan];
    }
    _isScanning = NO;
}

-(void)connect:(CBPeripheral *)peripheral{
    if (peripheral == _currentBleSerial) {
        if ([self isConnected]) {
            return;
        }
        if (isTryingConnect) {
            return;
        }
        
        isTryingConnect = YES;
        [_centralManager connectPeripheral:peripheral options:nil];
    }
    else{        
        [self disconnect];
        isTryingConnect = YES;
        _currentBleSerial = peripheral;
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)disconnect{
    if (_currentBleSerial != nil) {
        [_centralManager cancelPeripheralConnection:_currentBleSerial];
        _currentBleSerial = nil;
        serialCharacteristic = nil;
        //add by dragon
        _readCharacteristic = nil;
    }
}

-(void)sendData:(NSData *)data{
    if(serialCharacteristic == nil){
        if ([_delegate respondsToSelector:@selector(bleSerialManagerDidFailSendData:error:)]) {
            [_delegate bleSerialManagerDidFailSendData:self error:nil];
        }
    }
    else{
        [_currentBleSerial writeValue:data forCharacteristic:serialCharacteristic type:CBCharacteristicWriteWithoutResponse];
//        NSLog(@"data :%@",data);
        //NSLog(@"length : %d",[data length]);
        //[_currentBleSerial writeValue:data forCharacteristic:serialCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark CBPeripheralDelegate Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state == CBCentralManagerStatePoweredOn) {
        _isAvailabel = YES;
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceID]] options:nil];//scan service
    }
    else{
        _isAvailabel = NO;
        
    }
    
    if([_delegate respondsToSelector:@selector(bleSerialManager:didUpdateState:)]){
        [_delegate bleSerialManager:self didUpdateState:_isAvailabel];
    }
}
//发现从设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    // Reject any where the value is above reasonable range
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    

//    if([peripheral.name isEqualToString:@"BLE-HC V1.0"] || [peripheral.name isEqualToString:@"ELF-USB v2.0"] || [peripheral.name isEqualToString:@"ELF-Vrdrone"] || [peripheral.name isEqualToString:@"ELF-USB v20"] || [peripheral.name isEqualToString:@"BLE-HC V10"] || [peripheral.name isEqualToString:@"BLE-Elecfreaks"]) {
//    if([peripheral.name isEqualToString:@"ELF-Vrdrone"]|| [peripheral.name isEqualToString:@"BLE-Elecfreaks"]) {
    if([peripheral.name isEqualToString:@"ELF-Vrdrone"]) {
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
        self.currentBleSerial = peripheral;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPeripheralListDidChange object:self userInfo:nil];
        
        if ([_delegate respondsToSelector:@selector(bleSerialManager:didDiscoverBleSerial:)]) {//判断是否存在该方法
            [_delegate bleSerialManager:self didDiscoverBleSerial:nil];
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"connected" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"通知" message:@"蓝牙已经连上" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    isTryingConnect = NO;
    //_currentBleSerial = peripheral;
    
    [_centralManager stopScan];//stop scan
    _isScanning = NO;
    
    NSLog(@"Peripheral Connected");;
    NSLog(@"Scanning stopped");
    //peripheral.delegate = self;
    //CBUUID *serialServiceUUID = [self getSerialServiceUUID];
    NSLog(@"peripheral.name = %@",peripheral.name);
    //[peripheral discoverServices:[NSArray arrayWithObject:serialServiceUUID]];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceID]]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    isTryingConnect = NO;
    
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    
    _currentBleSerial = nil;
}

//当非正常断开（cancelPeripheralConnection）时，error为断开的原因，非正常断开的时候自动调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"disconnected" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
    
    NSLog(@"disconnect......");
    if (_currentBleSerial != nil && peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    [self.centralManager cancelPeripheralConnection:peripheral];
    isTryingConnect = NO;
    if (error != nil) {
        NSLog(@"disconnect error:%@. (%@)", peripheral, [error localizedDescription]);
    }
    
    _currentBleSerial = nil;
    
    if(_delegate != nil){
        if ([_delegate respondsToSelector:@selector(bleSerialManager:didDisconnectPeripheral:)]) {
            [_delegate bleSerialManager:self didDisconnectPeripheral:peripheral];
        }
    }
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceID]] options:nil];//重新连接
}
#pragma mark CBPeripheralDelegate Methods end


- (void)cleanup
{
//    // Don't do anything if we're not connected
//    if (!_currentBleSerial.isConnected) {
//        return;
//    }
//    
//    // See if we are subscribed to a characteristic on the peripheral
//    if (_currentBleSerial.services != nil) {
//        for (CBService *service in _currentBleSerial.services) {
//            if (service.characteristics != nil) {
//                for (CBCharacteristic *characteristic in service.characteristics) {
//                    
//                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
//                        if (characteristic.isNotifying) {
//                            // It is notifying, so unsubscribe
//                            [_currentBleSerial setNotifyValue:NO forCharacteristic:characteristic];
//                            
//                            // And we're done.
//                            return;
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
//    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


#pragma mark CBPeripheralDelegate Methods
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    //NSArray *characteristicList = [NSArray arrayWithObject:[self getSerialCharacteristicUUID]];
//    NSLog(@"Service Count:%lu",(unsigned long)[peripheral.services count]);
    NSArray *characteristicList = [NSArray arrayWithObjects:[self getSerialCharacteristicUUID],[self getSerialNotifyUUID], nil];
//    NSLog(@"characteristicList :%@",characteristicList);
    // Discover the characteristic we want...
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:characteristicList forService:service];
    }
    
//    NSLog(@"发现的服务");
//    int i=0;
//    for (CBService *s in peripheral.services) {
//        [self.nServices addObject:s];
//    }
//    for (CBService *s in peripheral.services) {
//        //[self updateLog:[NSString stringWithFormat:@"%d :服务 UUID: %@(%@)",i,s.UUID.data,s.UUID]];
//        NSLog(@"%d :服务 UUID: %@(%@)",i,s.UUID.data,s.UUID);
//        i++;
//        [peripheral discoverCharacteristics:nil forService:s];
//    }

}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }

    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        //NSLog(@"characteristic.UUID %@",characteristic.UUID);
        //if ([characteristic.UUID isEqual:[self getSerialCharacteristicUUID]]) {
        //if ([characteristic.UUID isEqual:[self getSerialNotifyUUID]]) {
        //NSLog(@"xxxx %@",[self getSerialServiceUUID]);
        //NSLog(@"yyyy %@",[self getSerialCharacteristicUUID]);
        //NSLog(@"zzzz %@",[self getSerialNotifyUUID]);
        //if ([service.UUID isEqual:[self getSerialServiceUUID]]) {
            
            //NSLog(@"characteristic %@",characteristic);
            //NSLog(@"service.UUID %@",service.UUID);
            //NSLog(@"getSerialServiceUUID %@",[self getSerialServiceUUID]);
//        NSLog(@"characteristicsxxxxxxxxx");
//            NSLog(@"****begin notify value for characteritic:%@", characteristic);
            //NSLog(@"特征 UUID: %@ (%@)",characteristic.UUID.data,characteristic.UUID);
            if([characteristic.UUID isEqual:[self getSerialCharacteristicUUID]]) {
                serialCharacteristic = characteristic;
//                NSLog(@"serialCharacteristic %@",serialCharacteristic);
            }
            if([characteristic.UUID isEqual:[self getSerialNotifyUUID]]) {
//                NSLog(@"yyyyyyyyyyyy");
                _readCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
            //NSLog(@"****begin notify value for characteritic:%@", characteristic);
            if(_delegate != nil){
                if ([_delegate respondsToSelector:@selector(bleSerialManager:didConnectPeripheral:)]) {
                    [_delegate bleSerialManager:self didConnectPeripheral:peripheral];
                }
            }
            
            //break;
        }
    //}
//    NSLog(@"xxxxxxxxxxxxxxxjdfaiwjefl");
//    NSLog(@"发现特征的服务:%@ (%@)",service.UUID.data ,service.UUID);
//    
//    for (CBCharacteristic *c in service.characteristics) {
//         NSLog(@"特征 UUID: %@ (%@)",c.UUID.data,c.UUID);
//            [_nCharacteristics addObject:c];
//    }
//    NSLog(@"_ncharacteristics %@",_nCharacteristics);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }

    if (error) {\
        NSLog(@"didUpdateValueForCharacteristic error: %@", [error localizedDescription]);
        return;
    }
    
//    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
//    NSLog(@"Received: %@", stringFromData);
//    NSLog(@"data = %@",characteristic.value);

    if ([_delegate respondsToSelector:@selector(bleSerialManager:didReceiveData:)]) {
        [_delegate bleSerialManager:self didReceiveData:characteristic.value];
//        [_delegate bleserialManager:self didReceiveData:stringFromData];
    }
    
//    // Have we got everything we need?
//    if ([stringFromData isEqualToString:@"EOM"]) {
//        
//        // We have, so show the data,
//        [self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
//        
//        // Cancel our subscription to the characteristic
//        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
//        
//        // and disconnect from the peripehral
//        [self.centralManager cancelPeripheralConnection:peripheral];
//    }
//    
//    // Otherwise, just add the data on to what we already have
//    [self.data appendData:characteristic.value];
//    
//    // Log it
}

//Invoked upon completion of a -[setNotifyValue:forCharacteristic:] request.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (peripheral != _currentBleSerial || characteristic != serialCharacteristic) {  //old, just do nothing
        return;
    }
    NSLog(@"zzzzzzzzzzzzz");
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self disconnect];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (peripheral != _currentBleSerial || characteristic != serialCharacteristic) { //old do nothing
        return;
    }
    NSLog(@"xxxxxxx");
    if (error != nil) {
        if ([_delegate respondsToSelector:@selector(bleSerialManagerDidFailSendData:error:)]) {
            [_delegate bleSerialManagerDidFailSendData:self error:error];
        }
    }
    else{
        NSLog(@"发送数据成功");
        if ([_delegate respondsToSelector:@selector(bleSerialManagerDidSendData:)]) {
            [_delegate bleSerialManagerDidSendData:self];
        }
    }
}

#pragma mark CBPeripheralDelegate Methods end

/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (CBUUID *)getSerialServiceUUID{
    UInt16 serialService = [self swap:kSerialService];
    //NSLog(@"serialService %d",serialService);
    NSData *serialServiceData = [[NSData alloc] initWithBytes:(char *)&serialService length:2];
    return [CBUUID UUIDWithData:serialServiceData];
}

- (CBUUID *)getSerialCharacteristicUUID{
    UInt16 serialCharacteristic_ = [self swap:kSerialCharacteristic];
    //NSLog(@"serialCharacteristic %d",serialCharacteristic_);
    NSData *serialCharacteristicData = [[NSData alloc] initWithBytes:(char *)&serialCharacteristic_ length:2];
    //NSLog(@"serialCharacteristicData %@",serialCharacteristicData);
    return [CBUUID UUIDWithData:serialCharacteristicData];
}

-(CBUUID *)getSerialNotifyUUID{
    UInt16 serialNotify = [self swap:kSerialNotify];
    NSData *serialNotifyData = [[NSData alloc]initWithBytes:(char *)&serialNotify length:2];
    return [CBUUID UUIDWithData:serialNotifyData];
}

//- (void)dealloc{
//    [self disconnect];
//}

@end
