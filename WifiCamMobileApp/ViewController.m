//
//  ViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "ViewController.h"
#import "SettingViewController.h"
#import "MBProgressHUD.h"
#import "CustomIOS7AlertView.h"
#import "Connection.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ViewControllerPrivate.h"
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import "WifiCamManager.h"
#import "WifiCamControl.h"
#include "ICatchWificamConfig.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#include "UtilsMacro.h"
#include "PreviewSDKEventListener.h"
#import <mach/mach_time.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "util.h"
#import "AccManager.h"
#import "Transmitter.h"
#import "MMProgressHUD.h"
#import "MMHud.h"
#import "OSDCommon.h"
#import "OSDData.h"
//#import "TabBarViewController.h"
#import "myTabBarController.h"

#define kPeripheralDeviceListTabelView 1

#define kThrottleFineTuningStep 0.03
#define kBeginnerElevatorChannelRatio  0.5
#define kBeginnerAileronChannelRatio   0.5
#define kBeginnerRudderChannelRatio    0.0
#define kBeginnerThrottleChannelRatio  0.8

float accelero_rotation[3][3];

static inline float sign(float value)
{
    float result = 1.0;
    if(value < 0)
        result = -1.0;
    
    return result;
}

@interface ViewController (){

    
    ConnectionListener *connectionChangedListener;
    NSThread *myThread;
    
    CGPoint ThrottleCurrentPosition;
    CGPoint ThrottleInitialPosition;
    CGPoint ThrottleCenter;
    float   ThrottleOperableRadius;
    BOOL    isTransmitting;
    BOOL    clickPressed;
    BOOL    firstTouch;
    BOOL    isThrottleBack;
    BOOL    isTryingConnect;
    BOOL    accModeEnabled;
    BOOL    accModeReady;
    BOOL    isArm;  //解锁标志
    BOOL    isTakeOff;//是否一键起飞
    UIBarButtonItem *photobtn;//照片按钮
    UIBarButtonItem *videobtn;//视频按钮
    UIBarButtonItem *lockbtn;//解锁按钮
    UIBarButtonItem *takeOffbtn;//一键起飞按钮
    
    NSString    *imagePath;//图片路径
    NSString    *videoPath;//录像路径
    NSString    *videoImagePath;//视频截图路径
    BOOL        isVideo;//是否打开视频
    BOOL        isRecording;//是否录制视频
//    VideoRecord *record;//录像
    int displayMode;//显示模式
    SystemSoundID myAlertSound;
    NSTimer *myTimer;//录像定时任务
    int main_rec_flag;
    NSTimer *VersionTimer;//检测版本定时器
    NSTimer *TakeOffTimer;//一键起飞定时器
    NSTimer *LandTimer;//已将降落定时器
    int check_flag;//版本检测次数
    int throttle_flag;

}
@property (weak, nonatomic) IBOutlet UIButton *videoBut;
@property (weak, nonatomic) IBOutlet UIView *settingBGView;

@property(nonatomic, retain) Channel *aileronChannel;
@property(nonatomic, retain) Channel *elevatorChannel;
@property(nonatomic, retain) Channel *rudderChannel;
@property(nonatomic, retain) Channel *throttleChannel;
@property(nonatomic, retain) Channel *aux1Channel;
@property(nonatomic, retain) Channel *aux2Channel;
@property(nonatomic, retain) Channel *aux3Channel;
@property(nonatomic, retain) Channel *aux4Channel;
@property(nonatomic, retain) Settings *setting;


@property(nonatomic) Reachability             *wifiReachability;
@property(strong, nonatomic) UIAlertView      *connErrAlert;
@property(strong, nonatomic) UIAlertView      *reconnAlert;
@property(strong, nonatomic) UIAlertView     *customerIDAlert;


@property(nonatomic) NSInteger AppError;

@end


@implementation ViewController {
    VideoRecOffListener *videoRecOffListener;
    VideoRecOnListener *videoRecOnListener;
    BatteryLevelListener *batteryLevelListener;
    StillCaptureDoneListener *stillCaptureDoneListener;
    //  SDCardFullListener *sdCardFullListener;
    TimelapseStopListener *timelapseStopListener;
    TimelapseCaptureStartedListener *timelapseCaptureStartedListener;
    TimelapseCaptureCompleteListener *timelapseCaptureCompleteListener;
    VideoRecPostTimeListener *videoRecPostTimeListener;
}


@synthesize background;
@synthesize point;
@synthesize click;
@synthesize aileronChannel = _aileronChannel;
@synthesize elevatorChannel = _elevatorChannel;
@synthesize rudderChannel = _rudderChannel;
@synthesize throttleChannel = _throttleChannel;
@synthesize aux1Channel = _aux1Channel;
@synthesize aux2Channel = _aux2Channel;
@synthesize aux3Channel = _aux3Channel;
@synthesize aux4Channel = _aux4Channel;
@synthesize setting = _setting;

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
     self.edgesForExtendedLayout = UIRectEdgeNone;
    self.settingBGView.hidden = YES;
//    WifiCamManager *app = [WifiCamManager instance];
//    self.wifiCam = [app.wifiCams objectAtIndex:0];
//    //_wifiCam.camera = [WifiCamControl createOneCamera];
//    self.camera = _wifiCam.camera;
//    self.ctrl = _wifiCam.controler;
//    self.staticData = [WifiCamStaticData instance];
//    
//    //  [_ctrl.propCtrl scanAbility];
//    [self p_constructPreviewData];
//    [self p_initPreviewGUI];
    [self.videoBut setTitle:NSLocalizedString(@"STREAM_RECONNECT", nil) forState:UIControlStateNormal];
    
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
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    
    
    _preview.contentMode = UIViewContentModeScaleAspectFit;
    
    _aileronChannel = [_setting channelByName:kChannelNameAileron];
    _elevatorChannel = [_setting channelByName:kChannelNameElevator];
    _rudderChannel = [_setting channelByName:kChannelNameRudder];
    _throttleChannel = [_setting channelByName:kChannelNameThrottle];
    _aux1Channel = [_setting channelByName:kChannelNameAUX1];
    _aux2Channel = [_setting channelByName:kChannelNameAUX2];
    _aux3Channel = [_setting channelByName:kChannelNameAUX3];
    _aux4Channel = [_setting channelByName:kChannelNameAUX4];
    
    //辅助通道设置
    if (_setting.isHeadFreeMode) {
        [_aux1Channel setValue:1];
    }else {
        [_aux1Channel setValue:-1];
    }
    
    if (_setting.isAltHoldMode) {
        [_aux2Channel setValue:1];
    }else {
        [_aux2Channel setValue:-1];
    }

    
    ThrottleOperableRadius = background.frame.size.width/2.0 - point.frame.size.width/2.0;
    //    NSLog(@"radius = %f",ThrottleOperableRadius);
    if (_setting.isThrottleMode) {
        ThrottleCenter = CGPointMake(background.frame.origin.x+background.frame.size.width/2, background.frame.origin.y+background.frame.size.height/2);
    }else{
        ThrottleCenter = CGPointMake(point.frame.origin.x+point.frame.size.width/2, point.frame.origin.y+point.frame.size.height/2);
    }
    ThrottleInitialPosition = CGPointMake(ThrottleCenter.x-background.frame.size.width/2, ThrottleCenter.y-background.frame.size.height/2);
    ThrottleCurrentPosition = ThrottleInitialPosition;
    [click setEnabled:NO];
    firstTouch = NO;
    [self updateThrottleCenter];
    myTimer = nil;
    VersionTimer = nil;
    VersionNum = 0;
    
    photobtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"IconPhoto"] style:UIBarButtonItemStylePlain target:self action:@selector(uiBarButtonAction:)];
    photobtn.tag = 200;
    
    videobtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"IconVideo"] style:UIBarButtonItemStylePlain target:self action:@selector(uiBarButtonAction:)];
    videobtn.tag = 201;
    
    lockbtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"IconLock"] style:UIBarButtonItemStylePlain target:self action:@selector(uiBarButtonAction:)];
    lockbtn.tag = 202;
    takeOffbtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"IconTakeOff"] style:UIBarButtonItemStylePlain target:self action:@selector(uiBarButtonAction:)];
    takeOffbtn.tag = 203;
    if (!_setting.isThrottleMode) {//非定高模式
            NSArray *array = [[NSArray alloc]initWithObjects:photobtn,videobtn,lockbtn, nil];
            self.navigationItem.rightBarButtonItems = array;
    }else{
            NSArray *array = [[NSArray alloc]initWithObjects:photobtn,videobtn,takeOffbtn,lockbtn, nil];
            self.navigationItem.rightBarButtonItems = array;
    }
    
    
    //增加拍照手势识别
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [click addGestureRecognizer:doubleTapGestureRecognizer];
    
}

-(void)doubleTap:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"------doubleTap---------");
    [self paizhao];

}

-(void)viewWillAppear:(BOOL)animated
{
    TRACE();
    [super viewWillAppear:animated];
    //当设置返回时需要重新加载视图
    [self viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    
    _preview.image = [UIImage imageNamed:@"MainImage"];
    isArm = NO;
    isTakeOff = NO;
    if (Arm_status) {
        [lockbtn setImage:[UIImage imageNamed:@"IconUnLock"]];
        isArm = YES;
    }else {
        [lockbtn setImage:[UIImage imageNamed:@"IconLock"]];
        isArm = NO;
    }
    if (TakeOff_status) {
        [takeOffbtn setImage:[UIImage imageNamed:@"IconLand"]];
        isTakeOff = YES;
    }else {
        [takeOffbtn setImage:[UIImage imageNamed:@"IconTakeOff"]];
        isTakeOff = NO;
    }
    isVideo = NO;
    isRecording = NO;
    myTimer = nil;
    VersionTimer = nil;
    isThrottleBack = _setting.isThrottleMode;
    displayMode = 0;
    main_rec_flag = 0;
    VersionNum = 0;
    check_flag = 0;
    throttle_flag = 0;
    


    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkarmState) name:kMainNotificationArmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkarmingState) name:kMainNotificationArmingStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkdisarmState) name:kMainNotificationDisarmStateDidChange object:nil];
    
    
    //bluetooth
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkunLinkState) name:kNotificationTransmitterStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkLinkState) name:kNotificationBluetoothLinkDidChange object:nil];
    
    //GetVersion
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkVersion) name:kMainGetVersionDidChange object:nil];
    //TakeOFF
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkTakeOff) name:kMainTakeOffDidChange object:nil];
    //Land
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkLanding) name:kMainLandDidChange object:nil];
    
    if(isTransmitting == NO) {
        isTransmitting = YES;
        accModeEnabled = YES;
        [self startTransmission];
    }
    _preview.contentMode = UIViewContentModeScaleToFill;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
    
    [self startTransmission];
}

-(void)viewWillLayoutSubviews {
    TRACE();
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && !_customIOS7AlertView.hidden) {
        [_customIOS7AlertView updatePositionForDialogView];
    }
    [super viewWillLayoutSubviews];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    TRACE();
    
    //[self showProgressHUDWithMessage:nil];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    // Retrieve something ...
    
//    [self connect];
    //dispatch_async(dispatch_get_main_queue(), ^{
    if (![_ctrl.propCtrl connected]
        || ![Reachability didConnectedToCameraHotspot]) {
        [self hideProgressHUD:YES];
        _settingButton.hidden = YES;
        return;
    }
    
    if ([self capableOf:WifiCamAbilityBatteryLevel]) {
        [self updateBatteryLevelIcon];
    }
    
    if (_camera.curDateStamp != DATE_STAMP_OFF) {
        _preview.userInteractionEnabled = NO;
    } else {
        _preview.userInteractionEnabled = YES;
    }
    
    // Update the AWB icon after setting new awb value
    if ([self capableOf:WifiCamAbilityWhiteBalance]) {
        [self updateWhiteBalanceIcon:_camera.curWhiteBalance];
    }
    
    // Update the Timelapse icon
    if ([self capableOf:WifiCamAbilityTimeLapse]
        && _camera.previewMode == WifiCamPreviewModeTimelapseOff
        && _camera.curTimelapseInterval != 0) {
        self.timelapseStateImageView.hidden = NO;
        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
            self.timelapseStateImageView.image = [UIImage imageNamed:@"timelapse_video"];
        } else {
            self.timelapseStateImageView.image = [UIImage imageNamed:@"timelapse_capture"];
        }
    } else {
        self.timelapseStateImageView.hidden = YES;
    }
    
    // Update the Slow-Motion icon
    if ([self capableOf:WifiCamAbilitySlowMotion]
        && _camera.previewMode == WifiCamPreviewModeVideoOff
        && _camera.curSlowMotion == 1) {
        AppLog(@"hidden: NO");
        self.slowMotionStateImageView.hidden = NO;
    } else {
        AppLog(@"hidden: YES");
        self.slowMotionStateImageView.hidden = YES;
    }
    
    // Update the Invert-Mode icon
    if ([self capableOf:WifiCamAbilityUpsideDown]
        && _camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Update delay capture icon after enable burst capture
    if ([self capableOf:WifiCamAbilityDelayCapture] && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateCaptureDelayItem:_camera.curCaptureDelay];
    }
    
    // Burst-capture icon
    if ([self capableOf:WifiCamAbilityBurstNumber] && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateBurstCaptureIcon:_camera.curBurstNumber];
    }
    
    // Movie Rec timer
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]
        && (_camera.previewMode == WifiCamPreviewModeVideoOn
            || (_camera.previewMode == WifiCamPreviewModeTimelapseOn && _camera.timelapseType == WifiCamTimelapseTypeVideo))) {
            self.movieRecordTimerLabel.hidden = NO;
        } else {
            self.movieRecordTimerLabel.hidden = YES;
        }
    
    // Update the size icon after delete or capture
    if ([self capableOf:WifiCamAbilityImageSize]
        && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateImageSizeOnScreen:_camera.curImageSize];
    } else if ([self capableOf:WifiCamAbilityVideoSize]
               && _camera.previewMode == WifiCamPreviewModeVideoOff) {
        [self updateVideoSizeOnScreen:_camera.curVideoSize];
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        if (_camera.timelapseType == WifiCamTimelapseTypeStill) {
            [self updateImageSizeOnScreen:_camera.curImageSize];
        } else {
            [self updateVideoSizeOnScreen:_camera.curVideoSize];
        }
    }
    
    // Movie rec
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        videoRecOnListener = new VideoRecOnListener(self);
        [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_ON listener:videoRecOnListener
                       isCustomize:NO];
    }
    
    // Zoom In/Out
    uint maxZoomRatio = [_ctrl.propCtrl retrieveMaxZoomRatio];
    uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
    AppLog(@"maxZoomRatio: %d", maxZoomRatio);
    AppLog(@"curZoomRatio: %d", curZoomRatio);
    self.zoomSlider.minimumValue = 1.0;
    self.zoomSlider.maximumValue = maxZoomRatio/10.0;
    self.zoomSlider.value = curZoomRatio/10.0;
    _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f",curZoomRatio/10.0];
    
    // Check SD card
    if (![_ctrl.propCtrl checkSDExist]) {
        [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
    } else if ((_camera.previewMode == WifiCamPreviewModeCameraOff
                && _camera.storageSpaceForImage <= 0)
               || (_camera.previewMode == WifiCamPreviewModeCameraOff
                   && _camera.storageSpaceForVideo==0)) {
                   [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                      showTime:2.0];
               }
    
    // Prepare preview
    self.PVRun = YES;
    /*
     if ([self capableOf:WifiCamAbilityMovieRecord]) {
     [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
     } else {
     [self runPreview:ICATCH_STILL_PREVIEW_MODE];
     }
     */
    
    switch (_camera.previewMode) {
        case WifiCamPreviewModeCameraOff:
        case WifiCamPreviewModeCameraOn:
            [self runPreview:ICATCH_STILL_PREVIEW_MODE];
            break;
            
        case WifiCamPreviewModeTimelapseOff:
        case WifiCamPreviewModeTimelapseOn:
            if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
            } else {
                [self runPreview:ICATCH_STILL_PREVIEW_MODE];
            }
            break;
            
        case WifiCamPreviewModeVideoOff:
        case WifiCamPreviewModeVideoOn:
            [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
            break;
            
        default:
            break;
    }
    
    
    //[self hideProgressHUD:YES];
    
    //});
    //});
    
}
//-(void)dealloc
//{
//    AppLog(@"%s", __func__);
//    _connErrAlert = nil;
//    _reconnAlert = nil;
//    
//    
//}

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
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        
                        WifiCamManager *app = [WifiCamManager instance];
                        self.wifiCam = [app.wifiCams objectAtIndex:0];
                        _wifiCam.camera = [WifiCamControl createOneCamera];
                
                        self.camera = _wifiCam.camera;
                        self.ctrl = _wifiCam.controler;
                        self.staticData = [WifiCamStaticData instance];
                        
                        //  [_ctrl.propCtrl scanAbility];
                        [self p_constructPreviewData];
                        [self p_initPreviewGUI];
                        
                    });
                    break;
                }
            }
            
            AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if (totalCheckCount <= 0 && _AppError == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [_connErrAlert show];
                NSLog(@"totalCheckCount <= 0 && _AppError == 0");
                
                //        [self performSegueWithIdentifier:@"panoSegue" sender:nil];
                
            });
        }
    });
    
    
}

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

- (void)viewWillDisappear:(BOOL)animated
{
    TRACE();
    [super viewWillDisappear:animated];
    [self hideZoomController:YES];
    _preview.image = [UIImage imageNamed:@"MainImage"];
    AppLog(@"self.PVRun = NO");
    // Stop preview
    self.PVRun = NO;
    
    [self removeObservers];
    
    if (!_customIOS7AlertView.hidden) {
        _customIOS7AlertView.hidden = YES;
    }
    if (!_sbTableAlert.hidden) {
        _sbTableAlert.hidden = YES;
    }
    if (!_normalAlert.hidden) {
        [_normalAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainNotificationArmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainNotificationArmingStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainNotificationDisarmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainNotificationPowerValueDidChange object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NetWorkLinkNotifacation object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NetWorkUnlinkNotifacation object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationTransmitterStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationBluetoothLinkDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainGetVersionDidChange object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainTakeOffDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMainLandDidChange object:nil];
    
    if (isTransmitting == YES) {
        [self stopTransmission];
        accModeEnabled = NO;
    }
    
//    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationBluetoothLinkDidChange object:nil];
    //[self removeObserver:[SDK instance] forKeyPath:@"connected"];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
}

- (void)dealloc
{
    [self p_deconstructPreviewData];
    _connErrAlert = nil;
    _reconnAlert = nil;
}
/*
 -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
 {
 AppLog(@"");
 }
 */


- (BOOL)capableOf:(WifiCamAbility)ability
{
    return (_camera.ability & ability) == ability ? YES : NO;
}


-(void)recoverFromDisconnection
{
    TRACE();
    
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self p_constructPreviewData];
    [self p_initPreviewGUI];
    
    [self viewDidAppear:YES];
}


#pragma mark - Initialization
- (void)p_constructPreviewData
{
    BOOL onlyStillFunction = YES;
    
    self.previewGroup = dispatch_group_create();
    self.audioQueue = dispatch_queue_create("WifiCam.GCD.Queue.Preview.Audio", 0);
    self.videoQueue = dispatch_queue_create("WifiCam.GCD.Queue.Preview.Video", 0);

    
    self.previewSemaphore = dispatch_semaphore_create(1);
    NSString *stillCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"shutter" ofType:@"wav"];
    id url = [NSURL fileURLWithPath:stillCaptureSoundUri];
    OSStatus errcode0 = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_stillCaptureSound);
    NSAssert1(errcode0 == 0, @"Failed to load sound ", @"shutter.wav");
    NSString *delayCaptureBeepUri = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    url = [NSURL fileURLWithPath:delayCaptureBeepUri];
    OSStatus errcode1 = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_delayCaptureBeep);
    NSAssert1(errcode1 == 0, @"Failed to load sound ", @"beep.wav");
    
    self.alertTableArray = [[NSMutableArray alloc] init];
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        [self p_initTimelapseRec];
        onlyStillFunction = NO;
    } else {
        [self.timelapseToggle removeFromSuperview];
        [self.timelapseStateImageView removeFromSuperview];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if ([self capableOf:WifiCamAbilityVideoSize]) {
            self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForVideoSize:_camera.curVideoSize];
        }
        [self p_initMovieRec];
        onlyStillFunction = NO;
    }
    
    if ([self capableOf:WifiCamAbilityStillCapture]){
        if ([self capableOf:WifiCamAbilityImageSize]) {
            self.tbPhotoSizeArray = [_ctrl.propCtrl prepareDataForImageSize:_camera.curImageSize];
        }
        if ([self capableOf:WifiCamAbilityDelayCapture]) {
            self.tbDelayCaptureTimeArray = [_ctrl.propCtrl prepareDataForDelayCapture:_camera.curCaptureDelay];
        }
        if (onlyStillFunction) {
            _camera.previewMode = WifiCamPreviewModeCameraOff;
        }
    }
    
    AppLog(@"_camera.cameraMode: %d", _camera.cameraMode);
    switch (_camera.cameraMode) {
        case MODE_VIDEO_OFF:
            _camera.previewMode = WifiCamPreviewModeVideoOff;
            break;
            
        case MODE_CAMERA:
            _camera.previewMode = WifiCamPreviewModeCameraOff;
            break;
            
        case MODE_IDLE:
            break;
            
        case MODE_SHARED:
            break;
            
        case MODE_TIMELAPSE_STILL:
            _camera.previewMode = WifiCamPreviewModeTimelapseOn;
            _camera.timelapseType = WifiCamTimelapseTypeStill;
            break;
            
        case MODE_TIMELAPSE_VIDEO:
            _camera.previewMode = WifiCamPreviewModeTimelapseOn;
            _camera.timelapseType = WifiCamTimelapseTypeVideo;
            break;
            
        case MODE_VIDEO_ON:
            _camera.previewMode = WifiCamPreviewModeVideoOn;
            break;
            
        case MODE_UNDEFINED:
        default:
            break;
    }
    
    [self updatePreviewSceneByMode:_camera.previewMode];
}

- (void)p_initMovieRec
{
    AppLog(@"%s", __func__);
    self.stopOn = [UIImage imageNamed:@"stop_on"];
    self.stopOff = [UIImage imageNamed:@"stop_off"];
    
    if (_camera.movieRecording) {
        [self addMovieRecListener];
        if (![_videoCaptureTimer isValid]) {
            self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target  :self
                                                                    selector:@selector(movieRecordingTimerCallback:)
                                                                    userInfo:nil
                                                                    repeats :YES];
            
            if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                self.movieRecordElapsedTimeInSeconds = [_ctrl.propCtrl retrieveCurrentMoviceRecordElapsedTime];
                AppLog(@"elapsedTimeInSeconds: %d", _movieRecordElapsedTimeInSeconds);
                self.movieRecordTimerLabel.text = [Tool translateSecsToString:_movieRecordElapsedTimeInSeconds];
            }
            
        }
        _camera.previewMode = WifiCamPreviewModeVideoOn;
    }
}

- (void)p_initTimelapseRec
{
    BOOL isTimelapseAlreadyStarted = NO;
    
    if (_camera.stillTimelapseOn) {
        AppLog(@"stillTimelapse On");
        _camera.timelapseType = WifiCamTimelapseTypeStill;
        isTimelapseAlreadyStarted = YES;
    } else if (_camera.videoTimelapseOn) {
        AppLog(@"videoTimelapseOn On");
        _camera.timelapseType = WifiCamTimelapseTypeVideo;
        isTimelapseAlreadyStarted = YES;
    }
    
    if (isTimelapseAlreadyStarted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![_videoCaptureTimer isValid]) {
                self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                        target  :self
                                                                        selector:@selector(movieRecordingTimerCallback:)
                                                                        userInfo:nil
                                                                        repeats :YES];
                if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                    self.movieRecordElapsedTimeInSeconds = [_ctrl.propCtrl retrieveCurrentMoviceRecordElapsedTime];
                    AppLog(@"elapsedTimeInSeconds: %d", _movieRecordElapsedTimeInSeconds);
                    self.movieRecordTimerLabel.text = [Tool translateSecsToString:_movieRecordElapsedTimeInSeconds];
                }
            }
        });
        [self addTimelapseRecListener];
        _camera.previewMode = WifiCamPreviewModeTimelapseOn;
    }
}

- (void)p_initPreviewGUI
{
    if ([self capableOf:WifiCamAbilityStillCapture
         && self.snapButton.hidden]) {
        self.snapButton.hidden = NO;
    }
    if (/* _wifiCam.gallery && */self.mpbToggle.hidden) {
        self.mpbToggle.hidden = NO;
    }
    
    self.snapButton.exclusiveTouch = YES;
    self.mpbToggle.exclusiveTouch = YES;
    self.cameraToggle.exclusiveTouch = YES;
    self.videoToggle.exclusiveTouch = YES;
    self.selftimerButton.exclusiveTouch = YES;
    self.sizeButton.exclusiveTouch = YES;
    self.settingButton.exclusiveTouch = YES;
    self.view.exclusiveTouch = YES;
}

- (void)p_deconstructPreviewData
{
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
    AudioServicesDisposeSystemSoundID(_delayCaptureBeep);
}

#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        _progressHUD.dimBackground = YES;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view.window addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time {
    TRACE();
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    TRACE();
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    TRACE();
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    TRACE();
    [self.progressHUD hide:animated];
}


#pragma mark - Preview

- (void)updateBatteryLevelIcon
{
    [self.batteryState setHidden:NO];
    
    NSString *imagePath = [_ctrl.propCtrl prepareDataForBatteryLevel];
    UIImage *batteryStatusImage = [UIImage imageNamed:imagePath];
    [self.batteryState setImage:batteryStatusImage];
    self.batteryLowAlertShowed = NO;
    
    batteryLevelListener = new BatteryLevelListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_BATTERY_LEVEL_CHANGED
                      listener:batteryLevelListener
                   isCustomize:NO];
}

- (void)updateWhiteBalanceIcon:(unsigned int)curWhiteBalance
{
    NSString  *imageName = [_staticData.awbDict objectForKey:@(curWhiteBalance)];
    [self.awbLabel setImage:[UIImage imageNamed:imageName]];
}

- (void)updateCaptureDelayItem:(unsigned int)curCaptureDelay
{
    /*
     if ((curCaptureDelay > 0 || curCaptureDelay == CAP_DELAY_NO) && curBurstNumber == BURST_NUMBER_OFF) {
     if (curCaptureDelay == CAP_DELAY_NO) {
     _tbDelayCaptureTimeArray.lastIndex = 0;
     }
     
     NSString *title = [_staticData.captureDelayDict objectForKey:@(curCaptureDelay)];
     [self.selftimerLabel setText:title];
     self.selftimerLabel.hidden = NO;
     [self.selftimerButton setImage:[UIImage imageNamed:@"btn_selftimer_n"]
     forState:UIControlStateNormal];
     self.selftimerButton.hidden = NO;
     self.selftimerButton.userInteractionEnabled = YES;
     } else {
     self.selftimerLabel.hidden = YES;
     NSDictionary *burstNumberStringTable = [[WifiCamStaticData instance] burstNumberStringDict];
     id imageName = [[burstNumberStringTable objectForKey:@(curBurstNumber)] lastObject];
     UIImage *continuousCaptureImage = [UIImage imageNamed:imageName];
     [self.selftimerButton setImage:continuousCaptureImage
     forState:UIControlStateNormal];
     self.selftimerButton.hidden = NO;
     self.selftimerButton.userInteractionEnabled = NO;
     }
     */
    
    if (curCaptureDelay == CAP_DELAY_NO) {
        _tbDelayCaptureTimeArray.lastIndex = 0;
    }
    
    NSString *title = [_staticData.captureDelayDict objectForKey:@(curCaptureDelay)];
    [self.selftimerLabel setText:title];
    [self.selftimerButton setImage:[UIImage imageNamed:@"btn_selftimer_n"]
                          forState:UIControlStateNormal];
    self.selftimerLabel.hidden = NO;
    self.selftimerButton.hidden = NO;
    
}

- (void)updateBurstCaptureIcon:(unsigned int)curBurstNumber
{
    if (curBurstNumber != BURST_NUMBER_OFF) {
        NSDictionary *burstNumberStringTable = [[WifiCamStaticData instance] burstNumberStringDict];
        id imageName = [[burstNumberStringTable objectForKey:@(curBurstNumber)] lastObject];
        UIImage *continuousCaptureImage = [UIImage imageNamed:imageName];
        _burstCaptureStateImageView.image = continuousCaptureImage;
        
        self.burstCaptureStateImageView.hidden = NO;
    } else {
        self.burstCaptureStateImageView.hidden = YES;
    }
}


- (void)updateSizeItemWithTitle:(NSString *)title
                     andStorage:(NSString *)storage
{
    if (title) {
        [self.sizeButton setTitle:title forState:UIControlStateNormal];
    }
    [self.sizeLabel setText:storage];
}

- (void)updateImageSizeOnScreen:(string)imageSize
{
    NSArray *imageArray = [_ctrl.propCtrl prepareDataForStorageSpaceOfImage: imageSize];
    _camera.storageSpaceForImage = [[imageArray lastObject] unsignedIntValue];
    NSString *storage = [NSString stringWithFormat:@"%d", _camera.storageSpaceForImage];
    [self updateSizeItemWithTitle:[imageArray firstObject]
                       andStorage:storage];
}

- (void)updateVideoSizeOnScreen:(string)videoSize
{
    NSArray *videoArray = [_ctrl.propCtrl prepareDataForStorageSpaceOfVideo: videoSize];
    _camera.storageSpaceForVideo = [[videoArray lastObject] unsignedIntValue];
    NSString *storage = [Tool translateSecsToString: _camera.storageSpaceForVideo];
    [self updateSizeItemWithTitle:[videoArray firstObject]
                       andStorage:storage];
}

- (void)setToCameraOffScene
{
    self.snapButton.enabled = YES;
    self.mpbToggle.enabled = YES;
    self.settingButton.enabled = YES;
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture]) {
        /*
         if ([self.selftimerButton isHidden]) {
         [self.selftimerButton setHidden:NO];
         [self.selftimerLabel setHidden:NO];œ
         }
         [self.selftimerButton setImage:[UIImage imageNamed:@"btn_selftimer_n"]
         forState:UIControlStateNormal];
         [self.selftimerButton setEnabled:YES];
         */
        [self updateCaptureDelayItem:_camera.curCaptureDelay];
    }
    
    // CaptureSize Item
    if ([self capableOf:WifiCamAbilityImageSize]) {
        if (self.sizeButton.hidden) {
            self.sizeButton.hidden = NO;
            self.sizeLabel.hidden = NO;
        }
        self.sizeButton.enabled = YES;
        [self updateImageSizeOnScreen:_camera.curImageSize];
        
    } else {
        self.sizeButton.hidden = YES;
        self.sizeLabel.hidden = YES;
    }
    
    // WhiteBalance
    if ([self capableOf:WifiCamAbilityWhiteBalance]
        && self.awbLabel.hidden) {
        self.awbLabel.hidden = NO;
    }
    
    // timelapse icon
    if (self.timelapseStateImageView.hidden == NO) {
        self.timelapseStateImageView.hidden = YES;
    }
    
    // slow-motion
    if (self.slowMotionStateImageView.hidden == NO) {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    // invert-mode
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Burst-Capture icon
    if ([self capableOf:WifiCamAbilityBurstNumber]) {
        //self.burstCaptureStateImageView.hidden = NO;
        [self updateBurstCaptureIcon:_camera.curBurstNumber];
    }
    
    // movie record timer label
    /*
     if (!self.movieRecordTimerLabel.hidden) {
     self.movieRecordTimerLabel.hidden = YES;
     }
     */
    
    
    // Video Toggle & Timelapse Toggle & Camera Toggle
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.hidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_off"]
                          forState:UIControlStateNormal];
        self.videoToggle.enabled = YES;
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.hidden) {
            self.timelapseToggle.hidden = NO;
        }
        
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_off"]
                              forState:UIControlStateNormal];
        self.timelapseToggle.enabled = YES;
    }
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.hidden) {
            self.cameraToggle.hidden = NO;
        }
        
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_on"]
                           forState:UIControlStateNormal];
        self.cameraToggle.enabled = YES;
        [self.snapButton setImage:[UIImage imageNamed:@"ic_camera1"]
                         forState:UIControlStateNormal];
    }
    
}
/*
 - (void)setToCameraOnScene
 {
 self.snapButton.enabled = NO;
 self.mpbToggle.enabled = NO;
 self.settingButton.enabled = NO;
 
 if ([self capableOf:WifiCamAbilityDelayCapture]
 && ![self.selftimerButton isHidden]) {
 self.selftimerButton.enabled = NO;
 }
 
 if ([self capableOf:WifiCamAbilityImageSize]
 && ![self.sizeButton isHidden]) {
 self.sizeButton.enabled = NO;
 }
 
 if ([self capableOf:WifiCamAbilityMovieRecord]) {
 self.cameraToggle.enabled = NO;
 self.videoToggle.enabled = NO;
 }
 }
 */

- (void)setToVideoOffScene
{
    [self.mpbToggle setEnabled:YES];
    [self.settingButton setEnabled:YES];
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture] && ![self.selftimerButton isHidden]) {
        [self.selftimerButton setHidden:YES];
        [self.selftimerLabel setHidden:YES];
        
    }
    
    // CaptureSize Item
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        if ([self.sizeButton isHidden]) {
            [self.sizeButton setHidden:NO];
            [self.sizeLabel setHidden:NO];
        }
        [self.sizeButton setEnabled:YES];
        [self updateVideoSizeOnScreen:_camera.curVideoSize];
    } else {
        [self.sizeButton setHidden:YES];
        [self.sizeLabel setHidden:YES];
    }
    
    // WhiteBalance
    if ([self capableOf:WifiCamAbilityWhiteBalance] && [self.awbLabel isHidden]) {
        [self.awbLabel setHidden:NO];
    }
    
    // timelapse icon
    if (self.timelapseStateImageView.hidden == NO) {
        self.timelapseStateImageView.hidden = YES;
    }
    
    // slow-motion
    if (_camera.curSlowMotion == 1) {
        self.slowMotionStateImageView.hidden = NO;
    } else {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    // invert-mode
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Burst-Capture icon
    if (!self.burstCaptureStateImageView.hidden) {
        self.burstCaptureStateImageView.hidden = YES;
    }
    
    // Camera Toggle &Timelapse Toggle & Video Toggle
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.isHidden) {
            self.cameraToggle.hidden = NO;
        }
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_off"]
                           forState:UIControlStateNormal];
        [self.cameraToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.isHidden) {
            self.timelapseToggle.hidden = NO;
        }
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_off"]
                              forState:UIControlStateNormal];
        [self.timelapseToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.isHidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_on"]
                          forState:UIControlStateNormal];
        [self.videoToggle setEnabled:YES];
        [self.snapButton setImage:[UIImage imageNamed:@"stop_on"]
                         forState:UIControlStateNormal];
        
        // movie record timer label
        
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            self.movieRecordTimerLabel.hidden = YES;
        }
        
    }
    
}

- (void)setToVideoOnScene
{
    [self setToVideoOffScene];
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        self.cameraToggle.enabled = NO;
    }
    self.videoToggle.enabled = NO;
    self.mpbToggle.enabled = NO;
    self.settingButton.enabled = NO;
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        self.timelapseToggle.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        self.sizeButton.enabled = NO;
    }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        self.movieRecordTimerLabel.hidden = NO;
    }
}

- (void)setToTimelapseOffScene
{
    [self.mpbToggle setEnabled:YES];
    [self.settingButton setEnabled:YES];
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture] && ![self.selftimerButton isHidden]) {
        [self.selftimerButton setHidden:YES];
        [self.selftimerLabel setHidden:YES];
    }
    
    // CaptureSize Item
    //  if (![self.sizeButton isHidden]) {
    //    [self.sizeButton setHidden:YES];
    //    [self.sizeLabel setHidden:YES];
    //  }
    if ([self capableOf:WifiCamAbilityVideoSize] || [self capableOf:WifiCamAbilityImageSize]) {
        if ([self.sizeButton isHidden]) {
            [self.sizeButton setHidden:NO];
            [self.sizeLabel setHidden:NO];
        }
        [self.sizeButton setEnabled:YES];
        
        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
            [self updateVideoSizeOnScreen:_camera.curVideoSize];
        } else {
            [self updateImageSizeOnScreen:_camera.curImageSize];
        }
    } else {
        self.sizeButton.hidden = NO;
        self.sizeLabel.hidden = NO;
    }
    
    
    // AWB
    if ([self capableOf:WifiCamAbilityWhiteBalance]
        && self.awbLabel.hidden) {
        self.awbLabel.hidden = NO;
    }
    
    // timelapse icon
    if (_camera.curTimelapseInterval != 0) {
        self.timelapseStateImageView.hidden = NO;
    }
    
    
    // slow-motion
    if (self.slowMotionStateImageView.hidden == NO) {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    //
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Burst-Capture icon
    if (!self.burstCaptureStateImageView.hidden) {
        self.burstCaptureStateImageView.hidden = YES;
    }
    
    // Camera Toggle & Video Toggle &Timelapse Toggle
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.isHidden) {
            self.cameraToggle.hidden = NO;
        }
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_off"]
                           forState:UIControlStateNormal];
        [self.cameraToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.isHidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_off"]
                          forState:UIControlStateNormal];
        [self.videoToggle setEnabled:YES];
        
        // movie record timer label
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            self.movieRecordTimerLabel.hidden = YES;
        }
        
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.isHidden) {
            self.timelapseToggle.hidden = NO;
        }
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_on"]
                              forState:UIControlStateNormal];
        [self.timelapseToggle setEnabled:YES];
        [self.snapButton setImage:[UIImage imageNamed:@"stop_on"]
                         forState:UIControlStateNormal];
    }
}

- (void)setToTimelapseOnScene
{
    [self setToTimelapseOffScene];
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        self.cameraToggle.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        self.videoToggle.enabled = NO;
    }
    self.mpbToggle.enabled = NO;
    self.settingButton.enabled = NO;
    self.timelapseToggle.enabled = NO;
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        self.sizeButton.enabled = NO;
    }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        self.movieRecordTimerLabel.hidden = NO;
    }
    
}

- (void)updatePreviewSceneByMode:(WifiCamPreviewMode)mode
{
    _camera.previewMode = mode;
    AppLog(@"camera.previewMode: %lu", (unsigned long)_camera.previewMode);
    switch (mode) {
        case WifiCamPreviewModeCameraOff:
            [self setToCameraOffScene];
            break;
        case WifiCamPreviewModeCameraOn:
            //[self setToCameraOnScene];
            break;
        case WifiCamPreviewModeVideoOff:
            [self setToVideoOffScene];
            break;
        case WifiCamPreviewModeVideoOn:
            [self setToVideoOnScene];
            break;
        case WifiCamPreviewModeTimelapseOff:
            [self setToTimelapseOffScene];
            break;
        case WifiCamPreviewModeTimelapseOn:
            [self setToTimelapseOnScene];
            break;
        default:
            break;
    }
}

- (void)runPreview:(ICatchPreviewMode)mode
{
    AppLog(@"%s start(%d)", __func__, mode);
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_time_t timeOutCount = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
    
    dispatch_async(globalQueue, ^{
        if (dispatch_semaphore_wait(_previewSemaphore, timeOutCount) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            return;
        }
        
        if (![_ctrl.actCtrl startPreview:mode withAudioEnabled:false ]) {
            AppLog(@"Failed to start media stream.");
            dispatch_semaphore_signal(_previewSemaphore);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:@"Failed to start media stream." showTime:1.1];
            });
            return;
        }
        
        self.PVRunning = YES;
       
        
        
        if ([_ctrl.propCtrl videoStreamEnabled]) {
            dispatch_group_async(_previewGroup, _videoQueue, ^{[self playbackVideo];});
        } else {
            AppLog(@"No Video");
        }
        
        dispatch_group_notify(_previewGroup, globalQueue, ^{
            [_ctrl.actCtrl stopPreview];
            self.PVRunning = NO;
            dispatch_semaphore_signal(_previewSemaphore);
        });
    });}


- (BOOL)isJPEGValid:(NSData *)jpeg {
    if ([jpeg length] < 4) return NO;
    const unsigned char * bytes = (const unsigned char *)[jpeg bytes];
    if (bytes[0] != 0xFF || bytes[1] != 0xD8) return NO;
    if (bytes[[jpeg length] - 2] != 0xFF ||
        bytes[[jpeg length] - 1] != 0xD9) return NO;
    return YES;
}

-(BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;
    
    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}


- (void)playbackVideo {
    
    NSMutableData *videoFrameData = nil;
    UIImage *receivedImage = nil;
    
    while (_PVRun) {
        videoFrameData = [[_ctrl.propCtrl prepareDataForVideoFrame] data];
        if (videoFrameData) {
            if (![self isJPEGValid:videoFrameData]) {
                AppLog(@"Invalid JPEG.");
                continue;
            }
            receivedImage = [[UIImage alloc] initWithData:videoFrameData];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (_PVRun && receivedImage) {
                    _preview.image = receivedImage;
                }
            });
            
            videoFrameData = nil;
            receivedImage = nil;
            
        } else {
            AppLog(@"videoFrameData is nil ...Check connection...");
            if (![_ctrl.propCtrl connected]) {
                AppLog(@"[%s]Ooops...disconnected.", __func__);
                
                self.PVRun = NO;
                
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
                
            } else {
                AppLog(@"It's still connected!");
            }
        }
    }
}


- (void)playbackAudio {
#ifdef DEBUG1
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *toFilePath = [cacheDirectory stringByAppendingPathComponent:@"test.raw"];
    AppLog(@"TO : %@", toFilePath);
    FILE *toFileHandle = fopen(toFilePath.UTF8String, "wb");
#endif
    
    NSData *audioBufferData = nil;
    self.al = [[HYOpenALHelper alloc] init];
    ICatchAudioFormat format = [_ctrl.propCtrl retrieveAudioFormat];
    
    AppLog(@"freq: %d, chl: %d, bit:%d", format.getFrequency(), format.getNChannels(), format.getSampleBits());
    [_al initOpenAL:format.getFrequency() channel:format.getNChannels() sampleBit:format.getSampleBits()];
    while (_PVRun) {
        if ([_al getInfo] > 25) {
            AppLog(@"Wait.");
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        audioBufferData = [[_ctrl.propCtrl prepareDataForAudioTrack] data];
        if(audioBufferData) {
#ifdef DEBUG1
            fwrite(audioBufferData.bytes, sizeof(char), audioBufferData.length, toFileHandle);
#endif
            [_al insertPCMDataToQueue:audioBufferData.bytes
                                 size:audioBufferData.length];
            
        } else if (![_ctrl.propCtrl connected]
                   /*|| ![Reachability didConnectedToCameraHotspot] */){
            AppLog(@"[%s]Ooops...disconnected.", __func__);
            self.PVRun = NO;
        } else {
            TRACE();
        }
    }
    [_al clean];
    self.al = nil;
#ifdef DEBUG1
    fclose(toFileHandle);
#endif
    
    AppLog(@"Break audio");
}

//--------拍照
- (IBAction)captureAction:(id)sender
{
    [self paizhao];
}
- (void)paizhao{

    // Check preview is still running
    if (!_PVRunning) {
        AppLog(@"PV is already dead..!");
        [self showProgressHUDNotice:@"摄像头离线" showTime:1.0];
        return;
    }
    // Check existence of SD card
    if (![_ctrl.propCtrl checkSDExist]) {
        [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil)
                           showTime:1.0];
        //return;
    }
    
    // Capture
    switch(_camera.previewMode) {
        case WifiCamPreviewModeCameraOff:
            [self stillCapture];
            break;
        case WifiCamPreviewModeVideoOff:
            [self startMovieRec];
            break;
        case WifiCamPreviewModeVideoOn:
            [self stopMovieRec];
            break;
        case WifiCamPreviewModeCameraOn:
            break;
        case WifiCamPreviewModeTimelapseOff:
            if (_camera.curTimelapseInterval != 0 && _camera.curTimelapseDuration>0) {
                [self startTimelapseRec];
            } else {
                [self showTimelapseOffAlert];
            }
            break;
        case WifiCamPreviewModeTimelapseOn:
            [self stopTimelapseRec];
            break;
        default:
            break;
    }
}
- (void)showTimelapseOffAlert
{
    /*
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert", nil)
     message           :NSLocalizedString(@"Timelapse is OFF", nil)
     delegate          :self
     cancelButtonTitle :NSLocalizedString(@"Cancel", nil)
     otherButtonTitles :nil, nil];
     [alert show];
     */
    [self showProgressHUDNotice:NSLocalizedString(@"Timelapse Interval is OFF", nil) showTime:1.0];
}

- (void)stillCapture
{
//    [self showProgressHUDWithMessage:nil];
    NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/photoShutter.caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound);
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"拍照完成";
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:0.5];
    
    // Check whether sd card is full
    if (_camera.storageSpaceForImage <= 0 && [_ctrl.propCtrl connected]) {
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:1.0];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![self capableOf:WifiCamAbilityDelayCapture]
            || _camera.curCaptureDelay == 0
            || ![self capableOf:WifiCamAbilityLatestDelayCapture]) {
            //AudioServicesPlaySystemSound(_stillCaptureSound);
            
            AppLog(@"Stop PV");
            self.PVRun = NO;
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC); //
            if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    [self showErrorAlertView];
                    [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
                });
                return;
            }
        }
        
        stillCaptureDoneListener = new StillCaptureDoneListener(self);
        [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_COMPLETE
                          listener:stillCaptureDoneListener
                       isCustomize:NO];
        
        // Capture
        [_ctrl.actCtrl triggerCapturePhoto];
        
        // Play sound for either burst capture or delay capture
        //uint curBurstNumber = _camera.curBurstNumber;
        //self.burstCaptureCount = [[_staticData.burstNumberDict objectForKey:@(curBurstNumber)] integerValue];
        uint curCaptureDelayTime = _camera.curCaptureDelay;
        NSInteger delayCaptureBeepCount = [[_staticData.delayCaptureDict objectForKey:@(curCaptureDelayTime)] integerValue];
        
        
        // Test only
        //NSTimeInterval delayTime = [[_staticData.delayCaptureDict objectForKey:@(curCaptureDelayTime)] doubleValue];
        //AppLog(@"delayTime: %f", delayTime);
        /*
         if ([self capableOf:WifiCamAbilityDelayCapture]
         && delayTime > 0
         && [self capableOf:WifiCamAbilityLatestDelayCapture]) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
         self.burstCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:delayTime
         target  :self
         selector:@selector(delayCaptureTimerCallback:)
         userInfo:nil
         repeats :NO];
         });
         
         }
         */
        
        if ([self capableOf:WifiCamAbilityDelayCapture]
            && delayCaptureBeepCount > 0
            && [self capableOf:WifiCamAbilityLatestDelayCapture]) {
            
            AppLog(@"Delay Capturing...");
            NSUInteger edgedCount = delayCaptureBeepCount/2;
            NSUInteger tempBeepCount = delayCaptureBeepCount;
            BOOL isRush = NO;
            while (delayCaptureBeepCount > 0) {
                //AudioServicesPlaySystemSound(_delayCaptureBeep);
                if (delayCaptureBeepCount > edgedCount && !isRush) {
                    [NSThread sleepForTimeInterval:0.5];
                    AppLog(@"sleep 0.5s");
                } else {
                    if (!isRush) {
                        delayCaptureBeepCount *= 2;
                    }
                    [NSThread sleepForTimeInterval:0.25];
                    AppLog(@"sleep 0.25s");
                    isRush = YES;
                }
                --delayCaptureBeepCount;
                AppLog(@"delayCaptureBeepCount is : %ld", (long)delayCaptureBeepCount);
            }
            if (tempBeepCount > 0) {
                //AudioServicesPlaySystemSound(_stillCaptureSound);
                
                self.PVRun = NO;
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC); //
                if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgressHUD:YES];
                        [self showErrorAlertView];
                        [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
                    });
                }
            }
        }
    
    });
}

- (void)startMovieRec
{
    AppLog(@"_camera.storageSpaceForVideo: %d", _camera.storageSpaceForVideo);
    if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                           showTime:2.0];
        return;
    }
    
    AudioServicesPlaySystemSound(_delayCaptureBeep);
    [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOn];
    [self showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            videoRecPostTimeListener = new VideoRecPostTimeListener(self);
            [_ctrl.comCtrl addObserver:(ICatchEventID)0x5001 listener:videoRecPostTimeListener
                           isCustomize:YES];
        }
        
        BOOL ret = [_ctrl.actCtrl startMovieRecord];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret) {
                [self addMovieRecListener];
                
                if (![self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                    if (![_videoCaptureTimer isValid]) {
                        self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                                target  :self
                                                                                selector:@selector(movieRecordingTimerCallback:)
                                                                                userInfo:nil
                                                                                repeats :YES];
                    }
                    [self hideProgressHUD:YES];
                }
                
            } else {
                [self showProgressHUDNotice:@"Failed to begin movie recording." showTime:2.0];
            }
            
        });
        
        
    });
}

- (void)stopMovieRec
{
    AudioServicesPlaySystemSound(_delayCaptureBeep);
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            [_ctrl.comCtrl removeObserver:(ICatchEventID)0x5001 listener:videoRecPostTimeListener
                              isCustomize:YES];
            if (videoRecPostTimeListener) {
                delete videoRecPostTimeListener;
                videoRecPostTimeListener = NULL;
            }
        }
        
        BOOL ret = [_ctrl.actCtrl stopMovieRecord];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_videoCaptureTimer isValid]) {
                [_videoCaptureTimer invalidate];
                self.movieRecordElapsedTimeInSeconds = 0;
            }
            
            if (ret) {
                [self remMovieRecListener];
                [self hideProgressHUD:YES];
            } else {
                [self showProgressHUDNotice:@"Failed to stop movie recording." showTime:2.0];
            }
            
            
            [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
        });
    });
}

- (void)startTimelapseRec
{
    AppLog(@"_camera.storageSpaceForVideo: %d", _camera.storageSpaceForVideo);
    if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                           showTime:2.0];
        return;
    }
    
    AudioServicesPlaySystemSound(_delayCaptureBeep);
    [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOn];
    [self showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL ret = [_ctrl.actCtrl startTimelapseRecord];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret) {
                [self addTimelapseRecListener];
                if (![_videoCaptureTimer isValid]) {
                    self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                            target  :self
                                                                            selector:@selector(movieRecordingTimerCallback:)
                                                                            userInfo:nil
                                                                            repeats :YES];
                }
                [self hideProgressHUD:YES];
                
            } else {
                [self showProgressHUDNotice:@"Failed to begin time-lapse recording" showTime:2.0];
            }
            
        });
        
        
    });
}

- (void)stopTimelapseRec
{
    AudioServicesPlaySystemSound(_delayCaptureBeep);
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL ret = [_ctrl.actCtrl stopTimelapseRecord];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret) {
                [self remTimelapseRecListener];
                [self hideProgressHUD:YES];
            } else {
                [self showProgressHUDNotice:@"Failed to stop time-lapse recording" showTime:2.0];
            }
            
            if ([_videoCaptureTimer isValid]) {
                [_videoCaptureTimer invalidate];
                self.movieRecordElapsedTimeInSeconds = 0;
            }
            [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
            
        });
    });
}

- (void)movieRecordingTimerCallback:(NSTimer *)sender
{
    UIImage *image = nil;
    
    if (_videoCaptureStopOn) {
        self.videoCaptureStopOn = NO;
        image = _stopOn;
    } else {
        self.videoCaptureStopOn = YES;
        image = _stopOff;
    }
    
    ++self.movieRecordElapsedTimeInSeconds;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.snapButton setImage:image forState:UIControlStateNormal];
    });
    
}

- (IBAction)swipe2settingAction:(UISwipeGestureRecognizer *)sender {
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOff
        || _camera.previewMode == WifiCamPreviewModeVideoOff
        || _camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        [self performSegueWithIdentifier:@"goSettingSegue"
                                  sender:self.settingButton];
    } else {
        [self showBusyNotice];
    }
}

- (IBAction)swipe2mpbAction:(UISwipeGestureRecognizer *)sender {
    if (_camera.previewMode == WifiCamPreviewModeCameraOff
        || _camera.previewMode == WifiCamPreviewModeVideoOff
        || _camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        [self mpbAction:self.mpbToggle];
    } else {
        [self showBusyNotice];
    }
    
}

- (IBAction)showZoomController:(UITapGestureRecognizer *)sender {
    if ([self capableOf:WifiCamAbilityZoom] && _zoomSlider.hidden) {
        [self hideZoomController:NO];
        if (![_hideZoomControllerTimer isValid]) {
            _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                        target:self
                                                                      selector:@selector(autoHideZoomController)
                                                                      userInfo:nil
                                                                       repeats:NO];
        }
    } else {
        [self hideZoomController:YES];
    }
}


- (void)hideZoomController: (BOOL)value {
    _zoomSlider.hidden = value;
    _zoomInButton.hidden = value;
    _zoomOutButton.hidden = value;
    _zoomValueLabel.hidden = value;
}

- (void)autoHideZoomController
{
    [self hideZoomController:YES];
}

- (IBAction)zoomCtrlBeenTouched:(id)sender {
    
    [_hideZoomControllerTimer invalidate];
}

- (IBAction)zoomValueChanged:(id)sender {
    __block BOOL err = NO;
    //[_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        AppLog(@"self.zoomSlider.value: %f", self.zoomSlider.value);
        if (self.zoomSlider.value*10.0 > curZoomRatio) {
            while (self.zoomSlider.value*10.0 > curZoomRatio) {
                AppLog(@"zoomIn:%d", curZoomRatio);
                [_ctrl.actCtrl zoomIn];
                uint r = [_ctrl.propCtrl retrieveCurrentZoomRatio];
                if (r <= curZoomRatio) {
                    AppLog(@"r, curZoomRatio: %d, %d", r, curZoomRatio);
                    err = YES;
                    break;
                } else {
                    curZoomRatio = r;
                }
            }
        } else if (self.zoomSlider.value*10.0  < curZoomRatio){
            while (self.zoomSlider.value*10.0 < curZoomRatio) {
                AppLog(@"zoomOut:%d", curZoomRatio);
                [_ctrl.actCtrl zoomOut];
                uint r = [_ctrl.propCtrl retrieveCurrentZoomRatio];
                if (r >= curZoomRatio) {
                    AppLog(@"r, curZoomRatio: %d, %d", r, curZoomRatio);
                    err = YES;
                    break;
                } else {
                    curZoomRatio = r;
                }
            }
            
        } else {
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err) {
                UISlider *slider = sender;
                slider.value = curZoomRatio / 10.0;
                [self showProgressHUDNotice:NSLocalizedString(@"Zoom In/Out failed.", nil) showTime:1.0];
            } else {
                _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f", curZoomRatio/10.0];
                [self hideProgressHUD:YES];
            }
            
            if (![_hideZoomControllerTimer isValid]) {
                _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                            target:self
                                                                          selector:@selector(autoHideZoomController)
                                                                          userInfo:nil
                                                                           repeats:NO];
            }
        });
    });
    
}

- (IBAction)zoomIn:(id)sender {
    [_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.actCtrl zoomIn];
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            [self updateZoomCtrl:curZoomRatio];
        });
    });
    
}

- (IBAction)zoomOut:(id)sender {
    [_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.actCtrl zoomOut];
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            [self updateZoomCtrl:curZoomRatio];
        });
    });
}

- (void)updateZoomCtrl: (uint)curZoomRatio {
    self.zoomSlider.value = curZoomRatio/10.0;
    _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f", curZoomRatio/10.0];
    
    if (![_hideZoomControllerTimer isValid]) {
        _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                    target:self
                                                                  selector:@selector(autoHideZoomController)
                                                                  userInfo:nil
                                                                   repeats:NO];
    }
}

- (void)showBusyNotice
{
    NSString *busyInfo = nil;
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOn) {
        busyInfo = @"STREAM_ERROR_CAPTURING";
    } else if (_camera.previewMode == WifiCamPreviewModeVideoOn) {
        busyInfo = @"STREAM_ERROR_RECORDING";
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOn) {
        busyInfo = @"STREAM_ERROR_CAPTURING";
    }
    [self showProgressHUDNotice:NSLocalizedString(busyInfo, nil) showTime:2.0];
}

//---------进入图库
- (IBAction)mpbAction:(id)sender
{
    AppLog(@"%s", __func__);
    if (!_PVRunning) {
        AppLog(@"PV is already dead..!");
        return;
    }
    
    self.PVRun = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    
    if (![_ctrl.propCtrl checkSDExist]) {
        [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                dispatch_semaphore_signal(_previewSemaphore);
                [self performSegueWithIdentifier:@"goMpbSegue" sender:sender];
                
            });
        }
    });
    
    AppLog(@"%s - Done", __func__);
}


//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//  if ([[segue identifier] isEqualToString:@"goSettingSegue"]) {
//    UINavigationController *nc = [segue destinationViewController];
//    SettingViewController *svc = [nc.viewControllers objectAtIndex:0];
//
//    svc.latestPVMode = _camera.previewMode;
//  }
//}

//----------切换到拍照状态
- (IBAction)changeToCameraState:(id)sender
{
    [self changeToCamera];
}

//----------切换到录像状态
- (IBAction)changeToVideoState:(id)sender{
    
    [self changeToVideo];
    
}

- (void)changeToCamera{
    if (_camera.previewMode != WifiCamPreviewModeCameraOff) {
        if (![_ctrl.propCtrl checkSDExist]) {
            [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:1.0];
            return;
        }
        
        //[self updatePreviewSceneByMode:WifiCamPreviewModeVideoOn];
        [self setButtonEnable:NO];
        self.PVRun = NO;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            [self showErrorAlertView];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_semaphore_signal(_previewSemaphore);
                //[self setPreviewStartToggle:YES];
                self.PVRun = YES;
                [self runPreview:ICATCH_STILL_PREVIEW_MODE]; // TODO:Make certain its' over
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
                    [self setButtonEnable:YES];
                });
                
            });
            
            
            if (_camera.storageSpaceForImage <= 0 && [_ctrl.propCtrl connected]) {
                AppLog(@"card full");
                [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:2.0];
            }
            
        }
        
    }
    
}

- (void)changeToVideo{

    if (_camera.previewMode != WifiCamPreviewModeVideoOff) {
        if (![_ctrl.propCtrl checkSDExist]) {
            [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:1.0];
            return;
        }
        
        [self setButtonEnable:NO];
        self.PVRun = NO;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            [self showErrorAlertView];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_semaphore_signal(_previewSemaphore);
                self.PVRun = YES;
                [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                    [self setButtonEnable:YES];
                });
                
            });
            if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
                AppLog(@"card full");
                [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:2.0];
            }
        }
        
    }
}

- (IBAction)changeToTimelapseState:(UIButton *)sender {
    if (_camera.previewMode != WifiCamPreviewModeTimelapseOff) {
        if (![_ctrl.propCtrl checkSDExist]) {
            [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
            return;
        }
        
        [self setButtonEnable:NO];
        self.PVRun = NO;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            [self showErrorAlertView];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_semaphore_signal(_previewSemaphore);
                self.PVRun = YES;
                if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                    [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
                } else {
                    [self runPreview:ICATCH_STILL_PREVIEW_MODE];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
                    [self setButtonEnable:YES];
                });
                
            });
            if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
                AppLog(@"card full");
                [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:2.0];
            }
        }
    }
}

- (void)setButtonEnable:(BOOL)value
{
    self.snapButton.enabled = value;
    self.mpbToggle.enabled = value;
    self.settingButton.enabled = value;
    self.cameraToggle.enabled = value;
    self.videoToggle.enabled = value;
    self.timelapseToggle.enabled = value;
    
}
//－－－－－－－设置计时
- (IBAction)changeDelayCaptureTime:(id)sender
{
    [_alertTableArray setArray:_tbDelayCaptureTimeArray.array];
    self.curSettingState = SETTING_DELAY_CAPTURE;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.customIOS7AlertView = [[CustomIOS7AlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_SET_SELF_TIMER", nil)];
        UIView      *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                              style:UITableViewStylePlain];
        [containerView addSubview:tableView];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _customIOS7AlertView.containerView = containerView;
        [_customIOS7AlertView setUseMotionEffects:TRUE];
        [_customIOS7AlertView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
        [_customIOS7AlertView show];
    } else {
        self.sbTableAlert = [[SBTableAlert alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_SET_SELF_TIMER", @"")
                                              cancelButtonTitle:NSLocalizedString(@"ALERT_CLOSE", @"")
                                                  messageFormat:nil];
        [_sbTableAlert setStyle:SBTableAlertStyleApple];
        [_sbTableAlert setDelegate:self];
        [_sbTableAlert setDataSource:self];
        [_sbTableAlert show];
    }
}
//－－－－－－－设置照片的分辨率
- (IBAction)changeCaptureSize:(id)sender
{
    NSString *alertTitle = nil;
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOff) {
        alertTitle = NSLocalizedString(@"SetPhotoResolution", @"");
        [_alertTableArray setArray:_tbPhotoSizeArray.array];
        self.curSettingState = SETTING_STILL_CAPTURE;
        
    } else if (_camera.previewMode == WifiCamPreviewModeVideoOff){
        alertTitle = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
        [_alertTableArray setArray:_tbVideoSizeArray.array];
        self.curSettingState = SETTING_VIDEO_CAPTURE;
        
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        if (_camera.timelapseType == WifiCamTimelapseTypeStill) {
            alertTitle = NSLocalizedString(@"SetPhotoResolution", @"");
            [_alertTableArray setArray:_tbPhotoSizeArray.array];
            self.curSettingState = SETTING_STILL_CAPTURE;
        } else {
            alertTitle = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
            [_alertTableArray setArray:_tbVideoSizeArray.array];
            self.curSettingState = SETTING_VIDEO_CAPTURE;
        }
        
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.customIOS7AlertView = [[CustomIOS7AlertView alloc] initWithTitle:alertTitle];
        UIView      *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                              style:UITableViewStylePlain];
        [demoView addSubview:tableView];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_customIOS7AlertView setContainerView:demoView];
        [_customIOS7AlertView setUseMotionEffects:TRUE];
        [_customIOS7AlertView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
        [_customIOS7AlertView show];
    } else {
        self.sbTableAlert = [[SBTableAlert alloc] initWithTitle:alertTitle
                                              cancelButtonTitle:NSLocalizedString(@"ALERT_CLOSE", @"")
                                                  messageFormat:nil];
        // [sbTableAlert.view setTag:2];
        [_sbTableAlert setStyle:SBTableAlertStyleApple];
        
        [_sbTableAlert setDelegate:self];
        [_sbTableAlert setDataSource:self];
        
        [_sbTableAlert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)showErrorAlertView
{
    self.normalAlert = [[UIAlertView alloc] initWithTitle:nil
                                       message           :NSLocalizedString(@"STREAM_FAILED", nil)
                                       delegate          :self
                                       cancelButtonTitle :NSLocalizedString(@"Exit", nil)
                                       otherButtonTitles :nil, nil];
    _normalAlert.tag = APP_RECONNECT_ALERT_TAG;
    [_normalAlert show];
}


- (void)addMovieRecListener
{
    videoRecOffListener = new VideoRecOffListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_OFF
                      listener:videoRecOffListener
                   isCustomize:NO];
    //  sdCardFullListener = new SDCardFullListener(self);
    //  [_ctrl.comCtrl addObserver:ICATCH_EVENT_SDCARD_FULL
    //                    listener:sdCardFullListener];
    
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self addObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds" options:0 context:nil];
    }
}

- (void)remMovieRecListener
{
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_OFF
                         listener:videoRecOffListener
                      isCustomize:NO];
    if (videoRecOffListener) {
        delete videoRecOffListener;
        videoRecOffListener = NULL;
    }
    //  [_ctrl.comCtrl removeObserver:ICATCH_EVENT_SDCARD_FULL
    //                       listener:sdCardFullListener];
    //  if (sdCardFullListener) {
    //    delete sdCardFullListener;
    //    sdCardFullListener = NULL;
    //  }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"movieRecordElapsedTimeInSeconds"]) {
        AppLog(@"movieRecordElapsedTimeInSeconds is changed.");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.movieRecordTimerLabel.text = [Tool translateSecsToString:_movieRecordElapsedTimeInSeconds];
        });
    }
}

- (void)addTimelapseRecListener
{
    timelapseStopListener = new TimelapseStopListener(self);
    /*
     timelapseCaptureStartedListener = new TimelapseCaptureStartedListener(self);
     timelapseCaptureCompleteListener = new TimelapseCaptureCompleteListener(self);
     */
    
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_TIMELAPSE_STOP
                      listener:timelapseStopListener
                   isCustomize:NO];
    /*
     [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_START
     listener:timelapseCaptureStartedListener];
     [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_COMPLETE
     listener:timelapseCaptureCompleteListener];
     */
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self addObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds" options:0 context:nil];
    }
}

- (void)remTimelapseRecListener
{
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_TIMELAPSE_STOP
                         listener:timelapseStopListener
                      isCustomize:NO];
    /*
     [_ctrl.comCtrl removeObserver:ICATCH_EVENT_CAPTURE_START
     listener:timelapseCaptureStartedListener];
     [_ctrl.comCtrl removeObserver:ICATCH_EVENT_CAPTURE_COMPLETE
     listener:timelapseCaptureCompleteListener];
     */
    if (timelapseStopListener) {
        delete timelapseStopListener; timelapseStopListener = NULL;
    }
    /*
     if (timelapseCaptureStartedListener) {
     delete timelapseCaptureStartedListener; timelapseCaptureStartedListener = NULL;
     }
     if (timelapseCaptureCompleteListener) {
     delete timelapseCaptureCompleteListener; timelapseCaptureCompleteListener = NULL;
     }
     */
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
    }
}

#pragma mark - ICatchWificamListener listener callback function

- (void)updateMovieRecState:(MovieRecState)state
{
    
    if (state == MovieRecStoped) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self remMovieRecListener];
            [_ctrl.actCtrl stopMovieRecord];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                }
            });
        });
    } else if (state == MovieRecStarted) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_ctrl.actCtrl startMovieRecord];
            [self addMovieRecListener];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOn];
                
                if (![_videoCaptureTimer isValid]) {
                    self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                            target  :self
                                                                            selector:@selector(movieRecordingTimerCallback:)
                                                                            userInfo:nil
                                                                            repeats :YES];
                }
            });
            
        });
    }
}

- (void)updateBatteryLevel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![_ctrl.propCtrl connected]) {
            return;
        }
        
        NSString *imagePath = [_ctrl.propCtrl prepareDataForBatteryLevel];
        UIImage *batteryStatusImage = [UIImage imageNamed:imagePath];
        [self.batteryState setImage:batteryStatusImage];
        
        if ([imagePath isEqualToString:@"battery_0"] && !_batteryLowAlertShowed) {
            self.batteryLowAlertShowed = YES;
            [self showProgressHUDNotice:NSLocalizedString(@"ALERT_LOW_BATTERY", nil) showTime:2.0];
            
        } else if ([imagePath isEqualToString:@"battery_4"]) {
            self.batteryLowAlertShowed = NO;
        }
    });
}

- (void)stopStillCapture
{
    TRACE();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_CAPTURE_COMPLETE
                             listener:stillCaptureDoneListener
                          isCustomize:NO];
        if (stillCaptureDoneListener) {
            delete stillCaptureDoneListener;
            stillCaptureDoneListener = NULL;
        }
        self.PVRun = YES;
        dispatch_semaphore_signal(_previewSemaphore);
        [self runPreview:ICATCH_STILL_PREVIEW_MODE];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
            TRACE();
            [self hideProgressHUD:YES];
        });
    });
    
    
}

- (void)stopTimelapse
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self remTimelapseRecListener];
        [_ctrl.actCtrl stopTimelapseRecord];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
            
            if ([_videoCaptureTimer isValid]) {
                [_videoCaptureTimer invalidate];
                self.movieRecordElapsedTimeInSeconds = 0;
            }
        });
    });
}

- (void)timelapseStartedNotice
{
    //AudioServicesPlaySystemSound(_stillCaptureSound);
}

- (void)timelapseCompletedNotice
{
    
    /*
     dispatch_async(dispatch_get_main_queue(), ^{
     [self showProgressHUDCompleteMessage:NSLocalizedString(@"Done", nil)];
     });
     */
}

- (void)postMovieRecordTime
{
    TRACE();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![_videoCaptureTimer isValid]) {
            self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target  :self
                                                                    selector:@selector(movieRecordingTimerCallback:)
                                                                    userInfo:nil
                                                                    repeats :YES];
        }
        
        [self hideProgressHUD:YES];
    });
    
    
}

- (void)postMovieRecordFileAddedEvent
{
    self.movieRecordElapsedTimeInSeconds = 0;
}

#pragma mark - SBTableAlertDataSource
- (UITableViewCell *)tableAlert:(SBTableAlert *)tableAlert
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[SBTableAlertCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:nil];
    [cell.textLabel setText:[_alertTableArray objectAtIndex:indexPath.row]];
    return cell;
}

- (NSInteger)tableAlert:(SBTableAlert *)tableAlert
  numberOfRowsInSection:(NSInteger)section
{
    return _alertTableArray.count;
}

#pragma mark - SBTableAlertDelegate
- (void)tableAlert:(SBTableAlert *)tableAlert
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            [self selectDelayCaptureTimeAtIndexPath:indexPath];
            break;
            
        case SETTING_STILL_CAPTURE:
            [self selectImageSizeAtIndexPath:indexPath];
            break;
            
        case SETTING_VIDEO_CAPTURE:
            [self selectVideoSizeAtIndexPath:indexPath];
            break;
            
        default:
            break;
    }
}

- (void)selectDelayCaptureTimeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbDelayCaptureTimeArray.lastIndex) {
        _tbDelayCaptureTimeArray.lastIndex = indexPath.row;
        
        unsigned int curCaptureDelay = [_ctrl.propCtrl parseDelayCaptureInArray:indexPath.row];
        /*
         if (curCaptureDelay != CAP_DELAY_NO) {
         // Disable burst capture
         _camera.curBurstNumber = BURST_NUMBER_OFF;
         [_ctrl.propCtrl changeBurstNumber:BURST_NUMBER_OFF];
         }
         */
        _camera.curCaptureDelay = curCaptureDelay;
        [_ctrl.propCtrl changeDelayedCaptureTime:curCaptureDelay];
        
        // Re-Get
        _camera.curBurstNumber = [_ctrl.propCtrl retrieveBurstNumber];
        _camera.curTimelapseInterval = [_ctrl.propCtrl retrieveCurrentTimelapseInterval];
        
        
        
        [self.selftimerLabel setText:[_staticData.captureDelayDict objectForKey:@(curCaptureDelay)]];
        [self updateBurstCaptureIcon:_camera.curBurstNumber];
    }
}

- (void)selectImageSizeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbPhotoSizeArray.lastIndex) {
        
        //self.PVRun = NO;
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            /*
             dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
             if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
             dispatch_async(dispatch_get_main_queue(), ^{
             [self hideProgressHUD:YES];
             [self showErrorAlertView];
             });
             
             } else {
             */
            
            _tbPhotoSizeArray.lastIndex = indexPath.row;
            string curImageSize = [_ctrl.propCtrl parseImageSizeInArray:indexPath.row];
            _camera.curImageSize = curImageSize;
            [_ctrl.propCtrl changeImageSize:curImageSize];
            
            //dispatch_semaphore_signal(_previewSemaphore);
            //self.PVRun = YES;
            //[self runPreview:ICATCH_STILL_PREVIEW_MODE];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self updateImageSizeOnScreen:curImageSize];
                
            });
            //}
        });
        
        
        /*
         _tbPhotoSizeArray.lastIndex = indexPath.row;
         
         string curImageSize = [_ctrl.propCtrl parseImageSizeInArray:indexPath.row];
         _camera.curImageSize = curImageSize;
         [_ctrl.propCtrl changeImageSize:curImageSize];
         [self updateImageSizeOnScreen:curImageSize];
         */
    }
}

- (void)selectVideoSizeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbVideoSizeArray.lastIndex) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if ([_ctrl.propCtrl isSupportMethod2ChangeVideoSize]) {
                AppLog(@"New Method");
                self.PVRun = NO;
                
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
                if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgressHUD:YES];
                        [self showErrorAlertView];
                    });
                    
                } else {
                    
                    dispatch_semaphore_signal(_previewSemaphore);
                    
                    [self runPreview:ICATCH_VIDEO_PREVIEW_MODE];
                    self.PVRun = YES;
                    
                    _tbVideoSizeArray.lastIndex = indexPath.row;
                    string curVideoSize = "";
                    curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                    //string curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                    
                    
                    [_ctrl.propCtrl changeVideoSize:curVideoSize];
                    [_ctrl.propCtrl updateAllProperty:_camera];
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateVideoSizeOnScreen:curVideoSize];
                        [self hideProgressHUD:YES];
                        _preview.userInteractionEnabled = YES;
                    });
                    
                    
                    // Is support Slow-Motion under this video size?
                    // Update the Slow-Motion icon
                    if ([self capableOf:WifiCamAbilitySlowMotion]
                        && _camera.previewMode == WifiCamPreviewModeVideoOff) {
                        
                        _camera.curSlowMotion = [_ctrl.propCtrl retrieveCurrentSlowMotion];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_camera.curSlowMotion == 1) {
                                self.slowMotionStateImageView.hidden = NO;
                            } else {
                                self.slowMotionStateImageView.hidden = YES;
                            }
                        });
                    }
                    
                }
            } else {
                AppLog(@"Old Method");
                
                _tbVideoSizeArray.lastIndex = indexPath.row;
                string curVideoSize;
                curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                
                [_ctrl.propCtrl changeVideoSize:curVideoSize];
                [_ctrl.propCtrl updateAllProperty:_camera];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    [self updateVideoSizeOnScreen:curVideoSize];
                });
            }
            
        });
        
    }
    
}

- (void)tableAlert:(SBTableAlert *)tableAlert
   willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastIndex = 0;
    
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            lastIndex = _tbDelayCaptureTimeArray.lastIndex;
            break;
            
        case SETTING_STILL_CAPTURE:
            lastIndex = _tbPhotoSizeArray.lastIndex;
            break;
            
        case SETTING_VIDEO_CAPTURE:
            lastIndex = _tbVideoSizeArray.lastIndex;
            break;
            
        default:
            break;
    }
    
    if (indexPath.row == lastIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _alertTableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    [cell.textLabel setText:[_alertTableArray objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            [self selectDelayCaptureTimeAtIndexPath:indexPath];
            break;
            
        case SETTING_STILL_CAPTURE:
            [self selectImageSizeAtIndexPath:indexPath];
            break;
            
        case SETTING_VIDEO_CAPTURE:
            [self selectVideoSizeAtIndexPath:indexPath];
            break;
            
        default:
            break;
    }
    
    [_customIOS7AlertView close];
}

- (void)tableView         :(UITableView *)tableView
        willDisplayCell   :(UITableViewCell *)cell
        forRowAtIndexPath :(NSIndexPath *)indexPath
{
    NSInteger lastIndex = 0;
    
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            lastIndex = _tbDelayCaptureTimeArray.lastIndex;
            break;
            
        case SETTING_STILL_CAPTURE:
            lastIndex = _tbPhotoSizeArray.lastIndex;
            break;
            
        case SETTING_VIDEO_CAPTURE:
            lastIndex = _tbVideoSizeArray.lastIndex;
            break;
            
        default:
            break;
    }
    
    if (indexPath.row == lastIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - UIAlertViewDelegate
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    switch (alertView.tag) {
//        case APP_RECONNECT_ALERT_TAG:
//            //[self dismissViewControllerAnimated:YES completion:^{}];
//            exit(0);
//            break;
//        default:
//            break;
//    }
//}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
            
            
        case APP_CONNECT_ERROR_TAG:
            //            _reConnectButton.hidden = NO;
            _videoBut.hidden = NO;
            break;
            
        case APP_RECONNECT_ALERT_TAG:
            //[self dismissViewControllerAnimated:YES completion:nil];
            //[self.navigationController popToRootViewControllerAnimated:YES];
            exit(0);
            [self globalReconnect];
            break;
            
        case APP_CUSTOMER_ALERT_TAG:
            AppLog(@"dismissViewControllerAnimated - start");
            [self dismissViewControllerAnimated:YES completion:^{
                AppLog(@"dismissViewControllerAnimated - complete");
            }];
            //            _reConnectButton.hidden = NO;
            _videoBut.hidden = NO;
            [[SDK instance] destroySDK];
            exit(0);
            break;
            
        default:
            break;
    }
}



-(void)removeObservers {
    if ([self capableOf:WifiCamAbilityBatteryLevel] && batteryLevelListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_BATTERY_LEVEL_CHANGED
                             listener:batteryLevelListener
                          isCustomize:NO];
        delete batteryLevelListener;
        batteryLevelListener = NULL;
    }
    if ([self capableOf:WifiCamAbilityMovieRecord] && videoRecOnListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_ON
                             listener:videoRecOnListener
                          isCustomize:NO];
        delete videoRecOnListener;
        videoRecOnListener = NULL;
    }
    
}


#pragma mark - AppDelegateProtocol

-(void)cleanContext {
    [self removeObservers];
    self.PVRun = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            
        } else {
            dispatch_async([[SDK instance] sdkQueue], ^{
                dispatch_semaphore_signal(_previewSemaphore);
                [[SDK instance] destroySDK];
            });
        }
    });
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [self removeObservers];
    self.PVRun = NO;

}

-(void)notifyConnectionBroken {
    [self cleanContext];
    
    switch(_camera.previewMode) {
        case WifiCamPreviewModeVideoOn: {
            if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                [_ctrl.comCtrl removeObserver:(ICatchEventID)0x5001
                                     listener:videoRecPostTimeListener
                                  isCustomize:YES];
                if (videoRecPostTimeListener) {
                    delete videoRecPostTimeListener;
                    videoRecPostTimeListener = NULL;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                [self remMovieRecListener];
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
            });
        }
            break;
        case WifiCamPreviewModeTimelapseOn: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self remTimelapseRecListener];
                
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
                [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
            });
        }
            
            break;
        default:
            break;
    }
}

#pragma mark - 油门操作

//－－－－－－－刷新油门
-(void)refreshThrottle {
    CGRect frame = background.frame;
    frame.origin = ThrottleCurrentPosition;
    background.frame = frame;

}
//更新摇杆点的位置，point是当前触摸点的位置
-(void)updateVelocity:(CGPoint)Point {
    
    CGPoint nextPoint = CGPointMake(Point.x, Point.y);
    CGPoint center = ThrottleCenter;
    UIImageView *pointImage = point;
    
    float dx = nextPoint.x - center.x;
    float dy = nextPoint.y - center.y;
    float len = sqrt(dx * dx + dy * dy);
    float point_radius = ThrottleOperableRadius;
    
    if(len > point_radius) {
        if(dx > 0) {
            
            nextPoint.x = center.x + fabsf(dx)*ThrottleOperableRadius/len;
        }else {
            
            nextPoint.x = center.x - fabsf(dx)*ThrottleOperableRadius/len;
        }
    }
    
    
    if(len > point_radius) {
        if(dy > 0) {
            
            nextPoint.y = center.y + fabsf(dy)*ThrottleOperableRadius/len;
            
        }else {
            
            nextPoint.y = center.y - fabsf(dy)*ThrottleOperableRadius/len;
        }
    }
    
    CGRect frame = pointImage.frame;
    frame.origin.x = nextPoint.x - pointImage.frame.size.width/2;
    frame.origin.y = nextPoint.y - pointImage.frame.size.height/2;
    pointImage.frame = frame;
}
- (void) setAcceleroRotationWithPhi:(float)phi withTheta:(float)theta withPsi:(float)psi
{
    accelero_rotation[0][0] = cosf(psi)*cosf(theta);
    accelero_rotation[0][1] = -sinf(psi)*cosf(phi) + cosf(psi)*sinf(theta)*sinf(phi);
    accelero_rotation[0][2] = sinf(psi)*sinf(phi) + cosf(psi)*sinf(theta)*cosf(phi);
    accelero_rotation[1][0] = sinf(psi)*cosf(theta);
    accelero_rotation[1][1] = cosf(psi)*cosf(phi) + sinf(psi)*sinf(theta)*sinf(phi);
    accelero_rotation[1][2] = -cosf(psi)*sinf(phi) + sinf(psi)*sinf(theta)*cosf(phi);
    accelero_rotation[2][0] = -sinf(theta);
    accelero_rotation[2][1] = cosf(theta)*sinf(phi);
    accelero_rotation[2][2] = cosf(theta)*cosf(phi);
    
}


-(IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event{
    
    UITouch *touch = [[event touchesForView:sender]anyObject];
    CGPoint current_location = [touch locationInView:self.view];
    static CGPoint previous_loaction;
    previous_loaction = current_location;
    
    if (sender == click) {
        //        NSLog(@"click down......");
        static uint64_t right_press_previous_time = 0;
        //        NSLog(@"time = %llu",mach_absolute_time());
        if(right_press_previous_time == 0) right_press_previous_time = mach_absolute_time();
        
        uint64_t current_time = mach_absolute_time();
        static mach_timebase_info_data_t sRightPressTimebaseInfo;
        uint64_t elapsedElf;
        float dt = 0;
        
        //dt calulus function of real elapsed time
        if(sRightPressTimebaseInfo.denom == 0) (void)mach_timebase_info(&sRightPressTimebaseInfo);
        elapsedElf = (current_time-right_press_previous_time)*(sRightPressTimebaseInfo.numer/sRightPressTimebaseInfo.denom);
        dt = elapsedElf/1000000000.0;
        right_press_previous_time = current_time;
        
        clickPressed = YES;
        ThrottleCurrentPosition.x = current_location.x - (background.frame.size.width / 2);
        CGPoint thumbCurrentLocation = CGPointZero;
        if (isThrottleBack) {
            [_throttleChannel setValue:0.0];
            ThrottleCurrentPosition.y = current_location.y - background.frame.size.height / 2 ;
        }else{
            float throttleValue = [_throttleChannel value];
            ThrottleCurrentPosition.y = current_location.y - background.frame.size.height / 2 + throttleValue * ThrottleOperableRadius;
        }
        [self refreshThrottle];
        ThrottleCenter = CGPointMake(background.frame.origin.x+background.frame.size.width/2, \
                                     background.frame.origin.y+background.frame.size.height/2);
        thumbCurrentLocation = CGPointMake(ThrottleCenter.x, current_location.y);
        [self updateVelocity:thumbCurrentLocation];
        //        NSLog(@"button down");
    }
    
    if (accModeEnabled) {
        if (sender == click) {
            accModeReady = YES;
        }
    }
    
    if (accModeEnabled && accModeReady) {
        NSLog(@"ACC Ready ok");
        // Start only if the first touch is within the pad's boundaries.
        // Allow touches to be tracked outside of the pad as long as the
        // screen continues to be pressed.
        CMMotionManager *motionManager = [[AccManager shareManager] motionManager];
        CMAcceleration current_acceleration;
        float phi, theta;
        
        //Get ACCELERO values－－－－加速度（值）
        if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1){
            //Only accelerometer (iphone 3GS)
            current_acceleration.x = motionManager.accelerometerData.acceleration.x;
            current_acceleration.y = motionManager.accelerometerData.acceleration.y;
            current_acceleration.z = motionManager.accelerometerData.acceleration.z;
        } else if (motionManager.deviceMotionAvailable == 1){
            //Accelerometer + gyro (iphone 4)
            current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
            current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
            current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
        }
        
        theta = atan2f(current_acceleration.x,sqrtf(current_acceleration.y*current_acceleration.y+current_acceleration.z*current_acceleration.z));
        phi = -atan2f(current_acceleration.y,sqrtf(current_acceleration.x*current_acceleration.x+current_acceleration.z*current_acceleration.z));
        
        //NSLog(@"Repere changed    ref_phi = %*.2f and ref_theta = %*.2f",4,phi * 180/PI,4,theta * 180/PI);
        
        [self setAcceleroRotationWithPhi:phi withTheta:theta withPsi:0];
    }

}
-(IBAction)joystickButtonDidTouchUp:(id)sender forEvent:(UIEvent *)event{
    
    if(sender == click) {
        clickPressed = NO;
        ThrottleCurrentPosition = ThrottleInitialPosition;
        
        [self refreshThrottle];
        
        [_rudderChannel setValue:0.0];
        if (isThrottleBack) {
            [_throttleChannel setValue:0.0];
            ThrottleCenter = CGPointMake(background.frame.origin.x+background.frame.size.width/2, \
                                         background.frame.origin.y+background.frame.size.height/2 );
        }else{
            float throttleValue = [_throttleChannel value];
            ThrottleCenter = CGPointMake(background.frame.origin.x+background.frame.size.width/2, \
                                         background.frame.origin.y+background.frame.size.height/2 - throttleValue * ThrottleOperableRadius);
        }
        
        //        NSLog(@"ThrottleCenter : %@",NSStringFromCGPoint(ThrottleCenter));
        accModeReady = NO;
        //        if (accModeEnabled) {
        //            [self setAcceleroRotationWithPhi:0.0 withTheta:0.0 withPsi:0.0];
        //        }
        if (accModeEnabled && !accModeReady) {
            [_aileronChannel setValue:0];//modify by dragon
            [_elevatorChannel setValue:0];
            [self setAcceleroRotationWithPhi:0.0 withTheta:0.0 withPsi:0.0];
        }
        [self updateVelocity:ThrottleCenter];
        
    }

}
-(IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event{
    
    BOOL _runOnce = YES;
    static float ThrottleBackgroundWidth = 0.0;
    static float ThrottleBackgroundHeight = 0.0;
    if(_runOnce) {
        ThrottleBackgroundWidth = background.frame.size.width;
        ThrottleBackgroundHeight = background.frame.size.height;
        _runOnce = NO;
    }
    
    UITouch *touch = [[event touchesForView:sender]anyObject];
    CGPoint Point = [touch locationInView:self.view];
    
    float rudderValidBandRation = 0.5 - _setting.rudderDeadBand / 2.0;
    if (sender == click && clickPressed) {
        
        float ThrottleXInput,ThrottleYInput;
        float ThrottleXValidBand;//右边摇杆X轴的无效区
        float ThrottleYValidBand;//右边摇杆y轴的无效区
        ThrottleXValidBand = rudderValidBandRation;
        ThrottleYValidBand = 0.5;
        
        if((ThrottleCenter.x - Point.x) > ((ThrottleBackgroundWidth / 2) - (ThrottleXValidBand * ThrottleBackgroundWidth))) {
            float percent = ((ThrottleCenter.x - Point.x) - ((ThrottleBackgroundWidth / 2) - (ThrottleXValidBand * ThrottleBackgroundWidth))) / (ThrottleXValidBand * ThrottleBackgroundWidth);
            if(percent > 1.0)
                percent = 1.0;
            ThrottleXInput = -percent;
        }
        else if((Point.x - ThrottleCenter.x) > ((ThrottleBackgroundWidth / 2) - (ThrottleXValidBand * ThrottleBackgroundWidth))) {
            float percent = ((Point.x - ThrottleCenter.x) - ((ThrottleBackgroundWidth / 2) - (ThrottleXValidBand * ThrottleBackgroundWidth))) / (ThrottleXValidBand * ThrottleBackgroundWidth);
            if(percent > 1.0)
                percent = 1.0;
            ThrottleXInput = percent;
        } else {
            ThrottleXInput = 0.0;
        }
        if (_setting.isBeginnerMode) {
            
            [_rudderChannel setValue:ThrottleXInput * kBeginnerRudderChannelRatio * _setting.yawScale];
        }else {
            
            [_rudderChannel setValue:ThrottleXInput * _setting.yawScale];
        }
        
        if((Point.y - ThrottleCenter.y) > ((ThrottleBackgroundHeight / 2) - (ThrottleYValidBand * ThrottleBackgroundHeight))) {
            float percent = ((Point.y - ThrottleCenter.y) - ((ThrottleBackgroundHeight / 2) - (ThrottleYValidBand * ThrottleBackgroundHeight))) / (ThrottleYValidBand * ThrottleBackgroundHeight);
            if(percent > 1.0)
                percent = 1.0;
            ThrottleYInput = -percent;
        } else if((ThrottleCenter.y - Point.y) > ((ThrottleBackgroundHeight / 2) - (ThrottleYValidBand * ThrottleBackgroundHeight))) {
            float percent = ((ThrottleCenter.y - Point.y) - ((ThrottleBackgroundHeight / 2) - (ThrottleYValidBand * ThrottleBackgroundHeight))) / (ThrottleYValidBand * ThrottleBackgroundHeight);
            if(percent > 1.0)
                percent = 1.0;
            ThrottleYInput = percent;
        } else {
            //            NSLog(@"xxxxxxxx");
            ThrottleYInput = 0.0;
        }
        if (_setting.isBeginnerMode) {
            [_throttleChannel setValue:(kBeginnerThrottleChannelRatio - 1) + ThrottleYInput * kBeginnerThrottleChannelRatio];
        }else {
            [_throttleChannel setValue:ThrottleYInput];
        }
        [self updateVelocity:Point];
    }

}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    if (firstTouch == NO) {
        firstTouch = YES;
        [self getThrottleInitialPosition];
        if(isThrottleBack) {
            [_throttleChannel setValue:0.0];
            //            [self refreshThrottle];
        }
        
    }
}
//－－－－－－－更新油门中心
-(void) updateThrottleCenter {
    ThrottleCenter = CGPointMake(ThrottleInitialPosition.x+background.frame.size.width/2, \
                                 ThrottleInitialPosition.y+background.frame.size.height/2);
    if(isThrottleBack){
        point.center = CGPointMake(ThrottleCenter.x, ThrottleCenter.y);
    }else{
        point.center = CGPointMake(ThrottleCenter.x, ThrottleCenter.y - _throttleChannel.value * ThrottleOperableRadius);
    }
    
}

//-----------------设置按钮
- (IBAction)settingAction:(UIButton *)sender {

    sender.selected = !sender.selected;
    if (sender.selected) {
        _settingBGView.hidden = NO;
    }else
    _settingBGView.hidden = YES;
    
}

- (IBAction)setIndexAction:(UIButton *)sender {
    
    switch (sender.tag) {
        case 100:
            NSLog(@"单手操控");
            break;
        case 101:
            NSLog(@"购买");
            break;
        case 102:
            NSLog(@"操控手册");
            break;
        case 103:
            NSLog(@"设置");
            [self performSegueWithIdentifier:@"setSegue" sender:nil];
            
            break;
        case 104:
            NSLog(@"关于ELF");
            break;
        case 105:
            NSLog(@"SD卡可用");
            break;
            
        default:
            break;
    }
}


//－－－－－－－－－视频接收
- (IBAction)videoButAction:(UIButton *)sender {
    [sender setHidden:YES];
    [self connect];

   
}

//－－－－－－－－－得到油门自定义位置
-(void) getThrottleInitialPosition {
    //    NSLog(@"get initvalue");
    ThrottleOperableRadius = background.frame.size.width/2.0 - point.frame.size.width/2.0;//更新点的操作半径
    ThrottleInitialPosition = CGPointMake(background.frame.origin.x, background.frame.origin.y);//
    //    NSLog(@"ThrottleInitialPosition : %@",NSStringFromCGPoint(ThrottleInitialPosition));
    if(firstTouch == YES) {
        [click setEnabled:YES];
    }
}

- (void)awakeFromNib{

    NSString *documentsDir= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    _setting = [[Settings alloc] initWithSettingsFile:userSettingsFilePath];
    
    //    NSLog(@"pathDocuments = %@",pathDocuments);
        //    record = [[VideoRecord alloc]init];//recording
    CMMotionManager *motionManager = [[AccManager shareManager]motionManager];
    if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
        //Only accelerometer
        motionManager.accelerometerUpdateInterval = 1.0 / 40;
        [motionManager startAccelerometerUpdates];
        NSLog(@"Accelero ok");
    }else if (motionManager.deviceMotionAvailable == 1) {
        motionManager.deviceMotionUpdateInterval = 1.0 / 40;
        [motionManager startDeviceMotionUpdates];
        NSLog(@"accelero   ok");
        NSLog(@"GYRO ok");
        //        accModeEnabled = YES;
        //accModeEnabled = YES;
    }else {
        NSLog(@"device motion error");
        accModeEnabled = FALSE;
    }
    [self setAcceleroRotationWithPhi:0.0 withTheta:0.0 withPsi:0.0];
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0 / 40) target:self selector:@selector(motionDataHandler) userInfo:nil repeats:YES];
}


//－－－－－－－－－－解锁、一键起飞、拍照、录制按钮事件－－－－－－－－－－－－
-(void) uiBarButtonAction:(id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if (firstTouch == NO) {
        firstTouch = YES;
        [self getThrottleInitialPosition];
    }
    switch (button.tag) {
            
        case 200://拍照状态
            
            [self changeToCamera];
        break;
        case 201://录像状态
            
            [self changeToVideo];
        break;
        case 202:
            NSLog(@"button3");
            //            [self ShowShareActionSheet];
            if ([[[Transmitter sharedTransmitter]bleSerialManager]isConnected]) {
                if (isArm == NO) {
                    [_aileronChannel setValue:-1];
                    _throttleChannel.value = -1;
                    [self updateThrottleCenter];
                }else {
                    [_aileronChannel setValue:1];
                    _throttleChannel.value = -1;
                    [self updateThrottleCenter];
                }
                //                [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_GET_VERSION)];
                
            }else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"蓝牙没有连接";
                hud.margin = 10.f;
                hud.yOffset = 150.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:1];
            }
            break;
            
            
        case 203:
            //            NSLog(@"button4 pressed");
            if ([[[Transmitter sharedTransmitter]bleSerialManager]isConnected]) {
                if (isArm == NO) {//没有解锁
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = @"没有解锁";
                    hud.margin = 10.f;
                    hud.yOffset = 150.f;
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES afterDelay:1];
                }else {
                    //发送一键起飞、降落命令
                    //                    NSLog(@"send land or take-off command");
                    if (isTakeOff == NO) {//发送一键起飞命令
                        //                        NSLog(@"Send TakeOff command");
                        //                        NSLog(@"TakeOff_data %@",getSimpleCommand(MSP_TAKEOFF));
                        //                        TakeOffTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(TakeOff_check) userInfo:Nil repeats:YES];
                        [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_TAKEOFF)];
                        [_throttleChannel setValue:0];
                    }else {//发送一键降落命令
                        //                        NSLog(@"Send Land command");
                        //                        NSLog(@"Land_data  %@",getSimpleCommand(MSP_LANDING));
                        [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_LANDING)];
                    }
                }
            }else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"蓝牙没有连接";
                hud.margin = 10.f;
                hud.yOffset = 150.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:1];
            }
            break;
    }
}

-(void) TakeOff_check {
    
    [_throttleChannel setValue:1];
    throttle_flag++;
    if (check_flag++ >20) {//停止定时器
        if (TakeOffTimer.isValid) {
            [TakeOffTimer invalidate];
            TakeOffTimer = nil;
            throttle_flag = 0;
            
        }
    }
    
}

-(void) checkTakeOff {
    //    NSLog(@"checkTakeff...");
    isTakeOff = YES;
    [takeOffbtn setImage:[UIImage imageNamed:@"IconLand"]];
    
}

-(void) checkLanding {
    //    NSLog(@"checkLanding...");
    isTakeOff = NO;
    [takeOffbtn setImage:[UIImage imageNamed:@"IconTakeOff"]];
    
}

-(void) checkarmState {
    NSLog(@"checkarmstate");
    isArm = YES;
    //SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"armed" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
    [lockbtn setImage:[UIImage imageNamed:@"IconUnLock"]];
    
    [_aileronChannel setValue:0];
}

-(void) checkarmingState {
    NSLog(@"checkarmingState");
}

-(void)checkdisarmState {
    NSLog(@"checkdisarmState");
    isArm = NO;
    isTakeOff = NO;
    //SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"disarmed" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound);
    [lockbtn setImage:[UIImage imageNamed:@"IconLock"]] ;
    
    [takeOffbtn setImage:[UIImage imageNamed:@"IconLock"]];
    
    [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_LANDING)];
    [_aileronChannel setValue:0];
}


//蓝牙连接上通知
-(void) checkLinkState {
    //TODO
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"蓝牙已连接";
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:0.5];
    
    [VersionTimer invalidate];
    [TakeOffTimer invalidate];
    VersionTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(mainCheckVersion) userInfo:nil repeats:YES];
    
}

-(void) mainCheckVersion {
    NSLog(@"check_flag = %d",check_flag);
    check_flag ++;
    [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_GET_VERSION)];//获取版本号
    NSLog(@"VersionTimer = %d",VersionTimer.isValid);
    NSLog(@"simpleCommand = %@",getSimpleCommand(MSP_GET_VERSION));
    if (check_flag++ >15) {//停止定时器
        if (VersionTimer.isValid) {
            [VersionTimer invalidate];
            VersionTimer = nil;
            check_flag = 0;
            [_setting setIsThrottleMode:NO];
            [_setting save];
            isThrottleBack = _setting.isThrottleMode;
            NSArray *array = [[NSArray alloc]initWithObjects:photobtn,videobtn,lockbtn, nil];
            self.navigationItem.rightBarButtonItems = array;
        }
    }
}

-(void) checkunLinkState {
    //TODO
    if (isArm) {
        isArm = NO;
        isTakeOff = NO;
        
        [lockbtn setImage:[UIImage imageNamed:@"IconLock"]];
        
        [takeOffbtn setImage:[UIImage imageNamed:@"IconTakeOff"]];
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"蓝牙断开连接";
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1];
    VersionNum = 0;
    
    if (VersionTimer.isValid) {
        [VersionTimer invalidate];
    }
    VersionTimer = nil;
    
    if (TakeOffTimer.isValid) {
        [TakeOffTimer invalidate];
    }
    TakeOffTimer = nil;
    check_flag = 0;
    throttle_flag = 0;
}

-(void) countCheckVersion {
    if (check_flag > 15) {
        check_flag = 0;
        if ([VersionTimer isValid]) {
            [VersionTimer invalidate];
        }
        VersionTimer = nil;
    }
}

-(void) checkVersion {
    NSLog(@"VersionNum = %d",VersionNum);
    //    NSLog(@"mainVersionxxxxx");
    if(VersionNum == 36){
        if (!_setting.isThrottleMode) {
            
            NSArray *array = [[NSArray alloc]initWithObjects:photobtn,videobtn,takeOffbtn,lockbtn, nil];
            self.navigationItem.rightBarButtonItems = array;
        }
        [_setting setIsThrottleMode:TRUE];
        [_setting save];
        isThrottleBack = _setting.isThrottleMode;
        if (VersionTimer.isValid) {
            NSLog(@"mainVersionxxxxx");
            [VersionTimer invalidate];
            VersionTimer = nil;
        }
        check_flag = 0;
    }
    
}


- (void)motionDataHandler
{
    
    static uint64_t previous_time = 0;
    if(previous_time == 0) previous_time = mach_absolute_time();
    
    uint64_t current_time = mach_absolute_time();
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t elapsedNano;
    float dt = 0;
    
    static float highPassFilterX = 0.0, highPassFilterY = 0.0, highPassFilterZ = 0.0;
    
    CMAcceleration current_acceleration = { 0.0, 0.0, 0.0 };
    static CMAcceleration last_acceleration = { 0.0, 0.0, 0.0 };
    
    static bool first_time_accelero = TRUE;
    static bool first_time_gyro = TRUE;
    
    static float angle_gyro_x, angle_gyro_y, angle_gyro_z;
    float current_angular_rate_x, current_angular_rate_y, current_angular_rate_z;
    
    static float hpf_gyro_x, hpf_gyro_y, hpf_gyro_z;
    static float last_angle_gyro_x, last_angle_gyro_y, last_angle_gyro_z;
    
    float phi, theta;
    
    //dt calculus function of real elapsed time
    if(sTimebaseInfo.denom == 0) (void) mach_timebase_info(&sTimebaseInfo);
    elapsedNano = (current_time-previous_time)*(sTimebaseInfo.numer / sTimebaseInfo.denom);
    previous_time = current_time;
    dt = elapsedNano/1000000000.0;
    
    //Execute this part of code only on the joystick button pressed
    CMMotionManager *motionManager = [[AccManager shareManager] motionManager];
    
    //Get ACCELERO values
    if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1)
    {
        //Only accelerometer (iphone 3GS)
        current_acceleration.x = motionManager.accelerometerData.acceleration.x;
        current_acceleration.y = motionManager.accelerometerData.acceleration.y;
        current_acceleration.z = motionManager.accelerometerData.acceleration.z;
    }
    else if (motionManager.deviceMotionAvailable == 1)
    {
        //Accelerometer + gyro (iphone 4)
        current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
        current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
        current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
    }
    
    //NSLog(@"Before Shake %f %f %f",current_acceleration.x, current_acceleration.y, current_acceleration.z);
    
    if( isnan(current_acceleration.x) || isnan(current_acceleration.y) || isnan(current_acceleration.z)
       || fabs(current_acceleration.x) > 10 || fabs(current_acceleration.y) > 10 || fabs(current_acceleration.z)>10)
    {
        static uint32_t count = 0;
        //        static BOOL popUpWasDisplayed = NO;
        NSLog (@"Accelero errors : %f, %f, %f (count = %d)", current_acceleration.x, current_acceleration.y, current_acceleration.z, count);
        NSLog (@"Accelero raw : %f/%f, %f/%f, %f/%f", motionManager.deviceMotion.gravity.x, motionManager.deviceMotion.userAcceleration.x, motionManager.deviceMotion.gravity.y, motionManager.deviceMotion.userAcceleration.y, motionManager.deviceMotion.gravity.z, motionManager.deviceMotion.userAcceleration.z);
        NSLog (@"Attitude : %f / %f / %f", motionManager.deviceMotion.attitude.roll, motionManager.deviceMotion.attitude.pitch, motionManager.deviceMotion.attitude.yaw);
        return;
    }
    
    //INIT accelero variables
    if(first_time_accelero == TRUE)
    {
        first_time_accelero = FALSE;
        last_acceleration.x = current_acceleration.x;
        last_acceleration.y = current_acceleration.y;
        last_acceleration.z = current_acceleration.z;
    }
    
    float highPassFilterConstant = (1.0 / 5.0) / ((1.0 / 40) + (1.0 / 5.0)); // (1.0 / 5.0) / ((1.0 / kAPS) + (1.0 / 5.0));
    
    
    //HPF on the accelero
    highPassFilterX = highPassFilterConstant * (highPassFilterX + current_acceleration.x - last_acceleration.x);
    highPassFilterY = highPassFilterConstant * (highPassFilterY + current_acceleration.y - last_acceleration.y);
    highPassFilterZ = highPassFilterConstant * (highPassFilterZ + current_acceleration.z - last_acceleration.z);
    
    //Save the previous values
    last_acceleration.x = current_acceleration.x;
    last_acceleration.y = current_acceleration.y;
    last_acceleration.z = current_acceleration.z;
    
#define ACCELERO_THRESHOLD          0.2
#define ACCELERO_FASTMOVE_THRESHOLD	1.3
    
    if(fabs(highPassFilterX) > ACCELERO_FASTMOVE_THRESHOLD ||
       fabs(highPassFilterY) > ACCELERO_FASTMOVE_THRESHOLD ||
       fabs(highPassFilterZ) > ACCELERO_FASTMOVE_THRESHOLD){
        ;
    }
    else{
        if(accModeEnabled){
            if(accModeReady == NO){
                //                 NSLog(@"xxxxxxxxxx");
                //                [_aileronChannel setValue:0];//modify by dragon
                [_elevatorChannel setValue:0];
            }
            else{
                
                
                CMAcceleration current_acceleration_rotate;
                float angle_acc_x;
                float angle_acc_y;
                
                //LPF on the accelero
                current_acceleration.x = 0.9 * last_acceleration.x + 0.1 * current_acceleration.x;
                current_acceleration.y = 0.9 * last_acceleration.y + 0.1 * current_acceleration.y;
                current_acceleration.z = 0.9 * last_acceleration.z + 0.1 * current_acceleration.z;
                
                //Save the previous values
                last_acceleration.x = current_acceleration.x;
                last_acceleration.y = current_acceleration.y;
                last_acceleration.z = current_acceleration.z;
                
                //Rotate the accelerations vectors
                current_acceleration_rotate.x =
                (accelero_rotation[0][0] * current_acceleration.x)
                + (accelero_rotation[0][1] * current_acceleration.y)
                + (accelero_rotation[0][2] * current_acceleration.z);
                current_acceleration_rotate.y =
                (accelero_rotation[1][0] * current_acceleration.x)
                + (accelero_rotation[1][1] * current_acceleration.y)
                + (accelero_rotation[1][2] * current_acceleration.z);
                current_acceleration_rotate.z =
                (accelero_rotation[2][0] * current_acceleration.x)
                + (accelero_rotation[2][1] * current_acceleration.y)
                + (accelero_rotation[2][2] * current_acceleration.z);
                
                //IF sequence to remove the angle jump problem when accelero mesure X angle AND Y angle AND Z change of sign
                if(current_acceleration_rotate.y > -ACCELERO_THRESHOLD && current_acceleration_rotate.y < ACCELERO_THRESHOLD)
                {
                    angle_acc_x = atan2f(current_acceleration_rotate.x,
                                         sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                else
                {
                    angle_acc_x = atan2f(current_acceleration_rotate.x,
                                         sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                //IF sequence to remove the angle jump problem when accelero mesure X angle AND Y angle AND Z change of sign
                if(current_acceleration_rotate.x > -ACCELERO_THRESHOLD && current_acceleration_rotate.x < ACCELERO_THRESHOLD)
                {
                    angle_acc_y = atan2f(current_acceleration_rotate.y,
                                         sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                else
                {
                    angle_acc_y = atan2f(current_acceleration_rotate.y,
                                         sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                //NSLog(@"AccX %2.2f   AccY %2.2f   AccZ %2.2f",current_acceleration.x,current_acceleration.y,current_acceleration.z);
                
                /***************************************************************************************************************
                 GYRO HANDLE IF AVAILABLE
                 **************************************************************************************************************/
                if (motionManager.deviceMotionAvailable == 1)
                {
                    current_angular_rate_x = motionManager.deviceMotion.rotationRate.x;
                    current_angular_rate_y = motionManager.deviceMotion.rotationRate.y;
                    current_angular_rate_z = motionManager.deviceMotion.rotationRate.z;
                    
                    angle_gyro_x += -current_angular_rate_x * dt;
                    angle_gyro_y += current_angular_rate_y * dt;
                    angle_gyro_z += current_angular_rate_z * dt;
                    
                    if(first_time_gyro == TRUE)
                    {
                        first_time_gyro = FALSE;
                        
                        //Init for the integration samples
                        angle_gyro_x = 0;
                        angle_gyro_y = 0;
                        angle_gyro_z = 0;
                        
                        //Init for the HPF calculus
                        hpf_gyro_x = angle_gyro_x;
                        hpf_gyro_y = angle_gyro_y;
                        hpf_gyro_z = angle_gyro_z;
                        
                        last_angle_gyro_x = 0;
                        last_angle_gyro_y = 0;
                        last_angle_gyro_z = 0;
                    }
                    
                    //HPF on the gyro to keep the hight frequency of the sensor
                    hpf_gyro_x = 0.9 * hpf_gyro_x + 0.9 * (angle_gyro_x - last_angle_gyro_x);
                    hpf_gyro_y = 0.9 * hpf_gyro_y + 0.9 * (angle_gyro_y - last_angle_gyro_y);
                    hpf_gyro_z = 0.9 * hpf_gyro_z + 0.9 * (angle_gyro_z - last_angle_gyro_z);
                    
                    last_angle_gyro_x = angle_gyro_x;
                    last_angle_gyro_y = angle_gyro_y;
                    last_angle_gyro_z = angle_gyro_z;
                }
                
                /******************************************************************************RESULTS AND COMMANDS COMPUTATION
                 *****************************************************************************/
                //Sum of hight gyro frequencies and low accelero frequencies
                float fusion_x = hpf_gyro_y + angle_acc_x;
                float fusion_y = hpf_gyro_x + angle_acc_y;
                
                //NSLog(@"%*.2f  %*.2f  %*.2f  %*.2f  %*.2f",2,-angle_acc_x*180/PI,2,-angle_acc_y*180/PI,2,current_acceleration_rotate.x,2,current_acceleration_rotate.y,2,current_acceleration_rotate.z);
                //Adapt the command values Normalize between -1 = 1.57rad and 1 = 1.57 rad
                //and reverse the values in regards of the screen orientation
                if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1)
                {
                    //Only accelerometer (iphone 3GS)
                    if(1)//screenOrientationRight
                    {
                        theta = -angle_acc_x;
                        phi = -angle_acc_y;
                    }
                    //                    else
                    //                    {
                    //                        theta = angle_acc_x;
                    //                        phi = angle_acc_y;
                    //                    }
                }
                if (motionManager.deviceMotionAvailable == 1)
                {
                    theta = -fusion_x;
                    phi = fusion_y;
                }
                
                //Clamp the command sent
                //                theta = theta / M_PI_2;
                //                phi   = phi / M_PI_2;
                theta = theta / M_1_PI;
                phi = phi / M_1_PI;
                if(theta > 1)
                    theta = 1;
                if(theta < -1)
                    theta = -1;
                if(phi > 1)
                    phi = 1;
                if(phi < -1)
                    phi = -1;
                
                //NSLog(@"ctrldata.iphone_theta %f", theta);
                //NSLog(@"ctrldata.iphone_phi   %f", phi);
                
                if (_setting.isBeginnerMode) {
                    //                    [_elevatorChannel setValue:phi * kBeginnerAileronChannelRatio];
                    //                    [_aileronChannel setValue:theta * kBeginnerElevatorChannelRatio * -1];
                    if(_setting.isSelfMode) {
                        [_elevatorChannel setValue:phi * kBeginnerAileronChannelRatio * (-1) * _setting.rollPitchScale];
                        [_aileronChannel setValue:theta * kBeginnerElevatorChannelRatio  * _setting.rollPitchScale];
                        
                    }else
                    {
                        [_elevatorChannel setValue:phi * kBeginnerAileronChannelRatio * _setting.rollPitchScale];
                        [_aileronChannel setValue:theta * kBeginnerElevatorChannelRatio * (-1) * _setting.rollPitchScale];
                    }
                    //[_elevatorChannel setValue:phi * kBeginnerAileronChannelRatio * _setting.rollPitchScale];
                    //[_aileronChannel setValue:theta * kBeginnerElevatorChannelRatio * (-1) * _setting.rollPitchScale];
                }
                else{
                    //                    [_elevatorChannel setValue:phi];
                    //                    [_aileronChannel setValue:theta * -1];
                    if (_setting.isSelfMode) {
                        [_elevatorChannel setValue:phi * (-1) * _setting.rollPitchScale];
                        [_aileronChannel setValue:theta  * _setting.rollPitchScale];
                    }
                    else {
                        [_elevatorChannel setValue:phi * _setting.rollPitchScale];
                        [_aileronChannel setValue:theta * (-1) * _setting.rollPitchScale];
                    }
                    //                    [_elevatorChannel setValue:phi * _setting.rollPitchScale];
                    //                    [_aileronChannel setValue:theta * (-1) * _setting.rollPitchScale];
                    
                }
            }
        }
        else{
            if (accModeReady) {
            }
        }
    }
}

-(OSStatus) startTransmission {
    BOOL s = [[Transmitter sharedTransmitter] start];
    return s;
}

-(OSStatus) stopTransmission {
    if(isTransmitting) {
        BOOL s = [[Transmitter sharedTransmitter] stop];
        isTransmitting = !s;
        return !s;
    }else {
        return 0;
    }
}

@end
