//
//  StartViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-1-22.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "StartViewController.h"
#import "MBProgressHUD.h"
#import "Connection.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "WifiCamControl.h"
#include "PreviewSDKEventListener.h"

#include "ICatchWificamConfig.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Transmitter.h"
#import "OSDCommon.h"
#import "OSDData.h"

//#define TRANSFER_SERVICE_UUID @"fff0"
//#define TRANSFER_CHARACTERISTIC_UUID 0xFFF1
//#define TRANSFER_CHARACTERISTIC_UUID @"68:9E:19:CE:03:48"

@interface StartViewController () {
  ConnectionListener *connectionChangedListener;
}
@property(weak, nonatomic) IBOutlet UIButton  *reConnectButton;
@property(nonatomic) Reachability             *wifiReachability;
@property(strong, nonatomic) UIAlertView      *connErrAlert;
@property(strong, nonatomic) UIAlertView      *reconnAlert;
@property(strong, nonatomic) UIAlertView     *customerIDAlert;
@property(strong, nonatomic) UIAlertView      *demoAlert;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) NSInteger AppError;

//@property (nonatomic,strong) CBCentralManager *blueManager;
//@property (nonatomic,strong) CBPeripheral *peripheral;
//@property (nonatomic,strong) CBPeripheralManager *peripheralManager;

@end

@implementation StartViewController

#pragma mark - Lifecycle
- (void)viewDidLoad
{
  AppLog(@"%s", __func__);
  
  /*
   *   CFArrayRef myArray = CNCopySupportedInterfaces();
   *   CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(myArray, 0));
   *   AppLog(@"Connected at : %@", myDict);
   *   NSDictionary *myDictionary = (__bridge_transfer NSDictionary*)myDict;
   *   NSString *SSID = [myDictionary objectForKey:@"SSID"];
   *   AppLog(@"SSID is %@", SSID);
   */
  [self.reConnectButton setTitle:NSLocalizedString(@"STREAM_RECONNECT", nil)
                        forState:UIControlStateNormal];
  self.connErrAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
        message                                         :NSLocalizedString(@"NoWifiConnection", nil)
        delegate                                        :self
        cancelButtonTitle                               :NSLocalizedString(@"Sure", nil)
        otherButtonTitles                               :nil, nil];
  _connErrAlert.tag = APP_CONNECT_ERROR_TAG;
  
  self.reconnAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                     message           :NSLocalizedString(@"TimeoutError", nil)
                                     delegate          :self
                                     cancelButtonTitle :NSLocalizedString(@"STREAM_RECONNECT", nil)
                                     otherButtonTitles :nil, nil];
  _reconnAlert.tag = APP_RECONNECT_ALERT_TAG;
  
  self.customerIDAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError",nil)
                                                    message:NSLocalizedString(@"ALERT_DOWNLOAD_CORRECT_APP", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Exit", nil)
                                          otherButtonTitles:nil, nil];
  _customerIDAlert.tag = APP_CUSTOMER_ALERT_TAG;
    
//    self.demoAlert = [[UIAlertView alloc]initWithTitle:@"Warnning"
//                                               message:@"This is a Demo App" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    _demoAlert.tag = APP_DEMO_TAG;
    
  
  self.wifiReachability = [Reachability reachabilityForLocalWiFi];
  [self.wifiReachability startNotifier];
    
    
//    _blueManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
//    _blueManager.delegate = self;
//    _peripheral.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated{

    [self startTransmission];
    
}
-(OSStatus) startTransmission {
    BOOL s = [[Transmitter sharedTransmitter] start];
    return s;
}


- (void)viewDidAppear:(BOOL)animated
{
    // modify by allen.chuang - 20150129    show the demo app message
    dispatch_async(dispatch_get_main_queue(), ^{
        AppLog(@"show the demo app messge");
        if( ! _demoAlert.visible)
            [_demoAlert show];
    });
    // end of modify

  [super viewDidAppear:animated];
  [self connect];
}

-(void)dealloc
{
  AppLog(@"%s", __func__);
  _connErrAlert = nil;
  _reconnAlert = nil;
  
  /*
  AppLog(@"removeObserver: ICATCH_EVENT_CONNECTION_DISCONNECTED");
  [_ctrl.comCtrl removeObserver:ICATCH_EVENT_CONNECTION_DISCONNECTED
                       listener:connectionChangedListener
                    isCustomize:NO];
  if (connectionChangedListener) {
    delete connectionChangedListener;
    connectionChangedListener = NULL;
  }
  */
}

#pragma mark - Connection
/*!
 * Called by Reachability whenever status changes.
 */
/*
- (void)reachabilityChanged:(NSNotification *)note
{
  //Reachability* curReach = [note object];
  //NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
  
  if ([_ctrl.propCtrl connected]) {
    return;
  }
  
  if (![Reachability didConnectedToCameraHotspot] && !_camera.exceptionOccured) {
    if (_reconnAlert.hidden) {
      AppLog(@"show reconnAlert");
      [_reconnAlert show];
    } else {
      AppLog(@"_reconnAlert is visible");
    }
    
  }
}
*/

- (NSString *)checkSSID
{
  NSString *ssid = @"";
  //NSString *bssid = @"";
  CFArrayRef myArray = CNCopySupportedInterfaces();
  if (myArray) {
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(myArray, 0));
    /*
     Core Foundation functions have names that indicate when you own a returned object:
     
     Object-creation functions that have “Create” embedded in the name;
     Object-duplication functions that have “Copy” embedded in the name.
     If you own an object, it is your responsibility to relinquish ownership (using CFRelease) when you have finished with it.
     
     */
    CFRelease(myArray);
    if (myDict) {
      NSDictionary *dict = (NSDictionary *)CFBridgingRelease(myDict);
      ssid = [dict valueForKey:@"SSID"];
      //bssid = [dict valueForKey:@"BSSID"];
    }
  }
  NSLog(@"ssid : %@", ssid);
  //NSLog(@"bssid: %@", bssid);
  
  return ssid;
}

- (void)connect
{
    
  _AppError = 0;
  if (!_connErrAlert.hidden) {
    AppLog(@"dismiss connErrAlert");
    [_connErrAlert dismissWithClickedButtonIndex:0 animated:NO];
  }
  if (!_reconnAlert.hidden) {
    AppLog(@"dismiss reconnAlert");
    [_reconnAlert dismissWithClickedButtonIndex:0 animated:NO];
  }
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
  hud.labelText = NSLocalizedString(@"ConnectingPleaseWait", nil);
  hud.dimBackground = YES;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    int totalCheckCount = 4;
    while (totalCheckCount-- > 0) {
      if ([Reachability didConnectedToCameraHotspot]) {
        hud.detailsLabelText = [self checkSSID];
        // Try to connnect to all the cameras through router.
        if ([WifiCamControl initSDK]) {
        
          [WifiCamControl scan];
          
          WifiCamManager *app = [WifiCamManager instance];
          self.wifiCam = [app.wifiCams objectAtIndex:0];
          _wifiCam.camera = [WifiCamControl createOneCamera];
          self.camera = _wifiCam.camera;
          self.ctrl = _wifiCam.controler;
          dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view.window animated:YES];
            [self performSegueWithIdentifier:@"previewSegue" sender:nil];
              
            
          });
          break;
        }
      }
      
      AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
      [NSThread sleepForTimeInterval:0.5];
    }
    
    if (totalCheckCount <= 0 && _AppError == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view.window animated:YES];
        [_connErrAlert show];
        
//        [self performSegueWithIdentifier:@"panoSegue" sender:nil];
//          [self performSegueWithIdentifier:@"previewSegue" sender:nil];
          
      });
    }
  });
}

- (IBAction)reConnect:(id)sender
{
  [sender setHidden:YES];
  [self connect];

}


-(void)globalReconnect
{
  dispatch_async(dispatch_get_main_queue(), ^{

      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                      message:NSLocalizedString(@"Connecting", nil)
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:nil, nil];
      [alert show];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkDisconnectedNotification"
                                                            object:nil];
        [NSThread sleepForTimeInterval:1.0];
        
        int totalCheckCount = 60; // 60times : 30s
        while (totalCheckCount-- > 0) {
          if ([Reachability didConnectedToCameraHotspot]) {
            // Try to connnect to all the cameras through router.
            if ([WifiCamControl initSDK]) {
              
              // modify by allen.chuang - 20140703
              /*
              if( [[SDK instance] isValidCustomerID:0x0100] == false){
                dispatch_async(dispatch_get_main_queue(), ^{
                  AppLog(@"CustomerID mismatch");
                  [_customerIDAlert show];
                  _AppError=1;
                });
                break;
              }
               */
              
              [WifiCamControl scan];
              
              WifiCamManager *app = [WifiCamManager instance];
              self.wifiCam = [app.wifiCams objectAtIndex:0];
              _wifiCam.camera = [WifiCamControl createOneCamera];
              self.camera = _wifiCam.camera;
              self.ctrl = _wifiCam.controler;
              
              /*
              if (connectionChangedListener != NULL) {
                delete connectionChangedListener;
                connectionChangedListener = NULL;
              }
              connectionChangedListener = new ConnectionListener(self);
              AppLog(@"addObserver: ICATCH_EVENT_CONNECTION_DISCONNECTED");
              [_ctrl.comCtrl addObserver:ICATCH_EVENT_CONNECTION_DISCONNECTED
                                listener:connectionChangedListener
                             isCustomize:NO];
              */
              dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkConnectedNotification"
                                                                    object:nil];
              });
              break;
            }
          }
          
          AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
          [NSThread sleepForTimeInterval:0.5];
        }
        
        if (totalCheckCount <= 0 && _AppError == 0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissWithClickedButtonIndex:0 animated:NO];
            [_reconnAlert show];
          });
        }
        
      });
      
    
  });
  
}


- (void)showReconnectAlert
{
  if (!_reconnAlert.visible) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_reconnAlert show];
    });
  }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (alertView.tag) {
    case APP_CONNECT_ERROR_TAG:
      _reConnectButton.hidden = NO;
      break;
      
    case APP_RECONNECT_ALERT_TAG:
      //[self dismissViewControllerAnimated:YES completion:nil];
      //[self.navigationController popToRootViewControllerAnimated:YES];
      
      [self globalReconnect];
      break;
      
    case APP_CUSTOMER_ALERT_TAG:
      AppLog(@"dismissViewControllerAnimated - start");
      [self dismissViewControllerAnimated:YES completion:^{
        AppLog(@"dismissViewControllerAnimated - complete");
      }];
      _reConnectButton.hidden = NO;
      [[SDK instance] destroySDK];
      exit(0);
      break;

    default:
      break;
  }
}


@end
