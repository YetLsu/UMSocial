//
//  ControlViewController.m
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/4.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "ControlViewController.h"
#import "Transmitter.h"
#import "util.h"
#import "OSDCommon.h"
#import <mach/mach_time.h>
#import "MMProgressHUD.h"
#import <AudioToolbox/AudioToolbox.h>
#import "OSDData.h"

//#import "TabBarViewController.h"
#import "myTabBarController.h"
#define kPeripheralDeviceListTabelView 1

#define kThrottleFineTuningStep 0.03
#define kBeginnerElevatorChannelRatio  0.5
#define kBeginnerAileronChannelRatio   0.5
#define kBeginnerRudderChannelRatio    0.0
#define kBeginnerThrottleChannelRatio  0.8

@interface ControlViewController () {
    CGPoint joystickRightCurrentPosition,joystickLeftCurrentPosition;
    CGPoint joystickRightInitialPosition,joystickLeftInitialPosition;
    CGPoint rightCenter,leftCenter;
    
    float rightJoyStickOperableRadius;
    float leftJoyStickOperableRadius;
    BOOL isTransmitting;
    BOOL isLeftHanded;
    BOOL isThrottleBack;//油门回中
    BOOL rudderIsLocked;//转头锁定
    BOOL buttonRightPressed,buttonLeftPressed;
    BOOL firstTouch;
    BOOL isTryingConnect;

    NSThread *myThread;//显示数据线程
    int displayMode;

    NSString *imagePath;
    NSString *videoPath;
    NSString *videoImagePath;
    BOOL    isVideo;//是否打开视频
    BOOL    isRecording;//是否录制视频
    BOOL    isArm;  //解锁标志
    BOOL    isTakeOff;//是否一键起飞
    int flag;
    int con_rec_flag;
    SystemSoundID myAlertSound;
    NSTimer *myTimer;
    NSTimer *VersionTimer;//检测版本定时器
    int check_flag;//版本检测次数
}

@property(nonatomic, retain) Channel *aileronChannel;
@property(nonatomic, retain) Channel *elevatorChannel;
@property(nonatomic, retain) Channel *rudderChannel;
@property(nonatomic, retain) Channel *throttleChannel;
@property(nonatomic, retain) Channel *aux1Channel;
@property(nonatomic, retain) Channel *aux2Channel;
@property(nonatomic, retain) Channel *aux3Channel;
@property(nonatomic, retain) Channel *aux4Channel;

@property(nonatomic, retain) Settings *setting;

@end

@implementation ControlViewController
@synthesize delegate;

@synthesize ImageViewBackground;
@synthesize VideoImage1;
@synthesize VideoImage2;

@synthesize btn_home;
@synthesize lockButton;
@synthesize videoButton;
@synthesize photoButton;
@synthesize modeButton;
@synthesize takeOff;

@synthesize joystickLeftBackground;
@synthesize joystickRightBackground;
@synthesize joystickLeftPoint;
@synthesize joystickRightPoint;
@synthesize joystickLeftButton;
@synthesize joystickRightButton;

@synthesize aileronChannel = _aileronChannel;
@synthesize elevatorChannel = _elevatorChannel;
@synthesize rudderChannel = _rudderChannel;
@synthesize throttleChannel = _throttleChannel;
@synthesize aux1Channel = _aux1Channel;
@synthesize aux2Channel = _aux2Channel;
@synthesize aux3Channel = _aux3Channel;
@synthesize aux4Channel = _aux4Channel;
@synthesize setting = _setting;
@synthesize con_rec_label = _con_rec_label;



- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
//    return UIInterfaceOrientationMaskAllButUpsideDown;
}

-(BOOL)shouldAutorotate
{
    
    return NO;
}

-(void)awakeFromNib {
    NSString *documentsDir= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    _setting = [[Settings alloc] initWithSettingsFile:userSettingsFilePath];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    CGAffineTransform transform = CGAffineTransformIdentity;
//    transform = CGAffineTransformRotate(transform, M_PI/2);
//    self.view.transform = transform;

    VideoImage1.hidden = YES;
    VideoImage2.hidden = YES;
    VideoImage1.contentMode = UIViewContentModeScaleToFill;
    VideoImage2.contentMode = UIViewContentModeScaleToFill;
    
    
    _aileronChannel = [_setting channelByName:kChannelNameAileron];
    _elevatorChannel = [_setting channelByName:kChannelNameElevator];
    _rudderChannel = [_setting channelByName:kChannelNameRudder];
    _throttleChannel = [_setting channelByName:kChannelNameThrottle];
    _aux1Channel = [_setting channelByName:kChannelNameAUX1];
    _aux2Channel = [_setting channelByName:kChannelNameAUX2];
    _aux3Channel = [_setting channelByName:kChannelNameAUX3];
    _aux4Channel = [_setting channelByName:kChannelNameAUX4];
    
    leftJoyStickOperableRadius = rightJoyStickOperableRadius = joystickLeftBackground.frame.size.width/2;//点的操作半径
   
    
    rightCenter = CGPointMake(joystickRightPoint.frame.origin.x+joystickRightPoint.frame.size.width/2, \
                              joystickRightPoint.frame.origin.y+joystickRightPoint.frame.size.height/2);
    joystickRightInitialPosition = CGPointMake(rightCenter.x-joystickRightBackground.frame.size.width/2, \
                                               rightCenter.y-joystickRightBackground.frame.size.height/2);
    
    leftCenter = CGPointMake(joystickLeftPoint.frame.origin.x+joystickLeftPoint.frame.size.width/2,  \
                             joystickLeftPoint.frame.origin.y+joystickLeftPoint.frame.size.height/2);
    joystickLeftInitialPosition = CGPointMake(leftCenter.x-joystickLeftBackground.frame.size.width/2, \
                                              leftCenter.y-joystickLeftBackground.frame.size.height/2);
    joystickLeftCurrentPosition = joystickLeftInitialPosition;
    joystickRightCurrentPosition = joystickRightInitialPosition;

    isLeftHanded = _setting.isLeftHanded;
    isThrottleBack = _setting.isThrottleMode;

    [self updateUI:isLeftHanded];
    [joystickLeftButton setEnabled:NO];
    [joystickRightButton setEnabled:NO];
    firstTouch = NO;
    isVideo = NO;
    isRecording = NO;
    isArm = NO;
    [self updateJoystickCenter];
    _con_rec_label.hidden = YES;
    myTimer = nil;
    VersionTimer = nil;
    check_flag = 0;
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkTransmitterState) name:kNotificationTransmitterStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkArmState) name:kNotificationLockStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkarmState) name:kNotificationArmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkarmingState) name:kNotificationArmingStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkdisarmState) name:kNotificationDisarmStateDidChange object:nil];
    
    
    //network
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(netWorkLink) name:NetWorkLinkNotifacation object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(netWorkunLink) name:NetWorkUnlinkNotifacation object:nil];
    
    //bluetooth
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkunLinkState) name:kNotificationTransmitterStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkLinkState) name:kNotificationBluetoothLinkDidChange object:nil];
    //GetVersion
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkVersion) name:kControlGetVersionDidChange object:nil];
    //TakeOff
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkTakeOff) name:kControlTakeOffDidChange object:nil];
    //Land
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkLanding) name:kControlLandDidChange object:nil];
    //辅助通道设置
    if(_setting.isHeadFreeMode) {
        [_aux1Channel setValue:1];
    }else {
        [_aux1Channel setValue:-1];
    }
    
    if(_setting.isAltHoldMode) {
        [_aux2Channel setValue:1];
    }else{
        [_aux2Channel setValue:-1];
    }
    
    
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];

    imagePath = [NSString stringWithFormat:@"%@/Image/",pathDocuments];
    videoPath = [NSString stringWithFormat:@"%@/Video/",pathDocuments];
    videoImagePath = [NSString stringWithFormat:@"%@/VideoImage/",pathDocuments];
    
    if (!_setting.isThrottleMode) {//非定高模式
        takeOff.hidden = YES;
    }else{
        takeOff.hidden = NO;
    }
    
   

    //增加手势识别
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    if (_setting.isLeftHanded) {
        [joystickLeftButton addGestureRecognizer:doubleTapGestureRecognizer];
    }else {
        [joystickRightButton addGestureRecognizer:doubleTapGestureRecognizer];
    }
    
}



-(void) updateUI:(BOOL)isLeftHand {
    if (isLeftHand) {
        joystickLeftPoint.image = [UIImage imageNamed:@"joystick_right_point.png"];
        joystickRightPoint.image = [UIImage imageNamed:@"joystick_left_point.png"];
    }else{
        joystickLeftPoint.image = [UIImage imageNamed:@"joystick_left_point.png"];
        joystickRightPoint.image = [UIImage imageNamed:@"joystick_right_point.png"];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //隐藏标签栏
    self.tabBarController.tabBar.hidden = YES;
    //隐藏状态栏
    [[UIApplication sharedApplication ] setStatusBarHidden:YES];
    NSLog(@"controllerViewWillAppear");
    flag = 0;
    con_rec_flag = 0;
    displayMode = 0;
    VersionNum = 0;
    VersionTimer = nil;
    check_flag = 0;

    if(isTransmitting == NO) {
        isTransmitting = YES;
        [self startTransmission];
    }

    isArm = NO;
    if (Arm_status) {
        [lockButton setImage:[UIImage imageNamed:@"IconUnLock"] forState:UIControlStateNormal];
        isArm = YES;
    }
    isTakeOff = NO;
    if (TakeOff_status) {
        [takeOff setImage:[UIImage imageNamed:@"IconLand"] forState:UIControlStateNormal];
        isTakeOff = YES;
    }else {
        [takeOff setImage:[UIImage imageNamed:@"IconTakeOff"] forState:UIControlStateNormal];
        isTakeOff = NO;
    }

}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //显示标签栏
    self.tabBarController.tabBar.hidden = NO;
    
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationArmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationArmingStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationDisarmStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kControlNotificationPowerValueDidChange object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NetWorkLinkNotifacation object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NetWorkUnlinkNotifacation object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationTransmitterStateDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotificationBluetoothLinkDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kControlGetVersionDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kControlTakeOffDidChange object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kControlLandDidChange object:nil];
    
    if (isTransmitting == YES) {
        [self stopTransmission];
    }
    NSLog(@"viewWillDisappear controlViewController");

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event {
    
    //    NSLog(@"333333333");
    UITouch *touch = [[event touchesForView:sender]anyObject];
    CGPoint current_location = [touch locationInView:self.view];
    static CGPoint previous_loaction;
    previous_loaction = current_location;
    
    if(sender == joystickRightButton) {
        static uint64_t right_press_previous_time = 0;
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
        
        buttonRightPressed = YES;
        joystickRightCurrentPosition.x = current_location.x - joystickRightBackground.frame.size.width/2;
        CGPoint pointCurrentLocation = CGPointZero;
        if(isLeftHanded){
            joystickRightCurrentPosition.y = current_location.y -  joystickRightBackground.frame.size.height/2;
            [self refreshJoystickRight];
            //摇杆中心点
            rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
                                      joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
            pointCurrentLocation = rightCenter;
        }else {
            if (isThrottleBack) {
                joystickRightCurrentPosition.y = current_location.y -  joystickRightBackground.frame.size.height/2;
                [self refreshJoystickRight];
                //摇杆中心点
                rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
                                          joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
                pointCurrentLocation = rightCenter;
            }else{
                //TODO
                float throttleValue = [_throttleChannel value];
                joystickRightCurrentPosition.y = current_location.y - (joystickRightBackground.frame.size.height/2) + throttleValue*rightJoyStickOperableRadius;
                [self refreshJoystickRight];
                //摇杆中心点
                rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
                pointCurrentLocation = CGPointMake(rightCenter.x, current_location.y);
            }
        }
        //更新摇杆点的位置
        [self updateVelocity:pointCurrentLocation isRight:YES];
        //        NSLog(@"right button is pressed");
    }else if(sender == joystickLeftButton) {
        static uint64_t Left_press_previous_time = 0;
        if(Left_press_previous_time == 0) Left_press_previous_time = mach_absolute_time();
        
        uint64_t current_time = mach_absolute_time();
        static mach_timebase_info_data_t sLeftPressTimebaseInfo;
        uint64_t elapsedElf;
        float dt = 0;
        
        //dt calulus function of real elapsed time
        if(sLeftPressTimebaseInfo.denom == 0) (void)mach_timebase_info(&sLeftPressTimebaseInfo);
        elapsedElf = (current_time-Left_press_previous_time)*(sLeftPressTimebaseInfo.numer/sLeftPressTimebaseInfo.denom);
        dt = elapsedElf/1000000000.0;
        Left_press_previous_time = current_time;
        
        buttonLeftPressed = YES;
        joystickLeftCurrentPosition.x = current_location.x - joystickLeftBackground.frame.size.width/2;
        CGPoint pointCurrentLocation = CGPointZero;
        if(isLeftHanded){
            if (isThrottleBack) {
                joystickLeftCurrentPosition.y = current_location.y-joystickLeftBackground.frame.size.height/2;
                [self refreshJoystickLeft];
                //摇杆中心点
                leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
                                         joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
                pointCurrentLocation = leftCenter;
                
            }else{
                //TODO
                float throttleValue = [_throttleChannel value];
                joystickLeftCurrentPosition.y = current_location.y-joystickLeftBackground.frame.size.height/2 + throttleValue * leftJoyStickOperableRadius;
                [self refreshJoystickLeft];
                //摇杆中心点
                leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
                pointCurrentLocation = CGPointMake(leftCenter.x, current_location.y);
            }
        }else{
            joystickLeftCurrentPosition.y = current_location.y-joystickLeftBackground.frame.size.height/2;
            [self refreshJoystickLeft];
            //摇杆中心点
            leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
                                     joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
            pointCurrentLocation = leftCenter;
        }
        [self updateVelocity:pointCurrentLocation isRight:NO];
        
        //        NSLog(@"left button is pressed");
    }
    
}

- (IBAction)joystickButtonDidTouchUp:(UIButton *)sender forEvent:(UIEvent *)event {
    
    //    NSLog(@"444444444444");
    if(sender == joystickRightButton) {
        buttonRightPressed = NO;
        joystickRightCurrentPosition = joystickRightInitialPosition;
        //        NSLog(@"joystickRightCurrentPosition : %@",NSStringFromCGPoint(joystickRightCurrentPosition));
        [self refreshJoystickRight];
        
        //
        //
        if(isLeftHanded) {
            [_aileronChannel setValue:0.0];
            [_elevatorChannel setValue:0.0];
            rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
                                      joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
            //TODO ACC
        }
        else{
            if (isThrottleBack) {
                [_rudderChannel setValue:0.0];
                [_throttleChannel setValue:0.0];
                //            NSLog(@"throttleValue = %f",throttleValue);
                rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
                                          joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
            }else{
                [_rudderChannel setValue:0.0];
                float throttleValue = [_throttleChannel value];
                //            NSLog(@"throttleValue = %f",throttleValue);
                rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
                                          joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2-throttleValue * rightJoyStickOperableRadius);
            }
        }
        //        rightCenter = CGPointMake(joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2, \
        joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
        //        NSLog(@"rightCenter : %@",NSStringFromCGPoint(rightCenter));
        [self updateVelocity:rightCenter isRight:YES];
        //        NSLog(@"right button is released");
        //        NSLog(@"x = : %f",joystickRightBackground.frame.origin.x+joystickRightBackground.frame.size.width/2);
        //        NSLog(@"y = : %f",joystickRightBackground.frame.origin.y+joystickRightBackground.frame.size.height/2);
    }else if(sender == joystickLeftButton) {
        buttonLeftPressed = NO;
        joystickLeftCurrentPosition = joystickLeftInitialPosition;
        [self refreshJoystickLeft];
        if(isLeftHanded) {
            if (isThrottleBack) {
                [_rudderChannel setValue:0.0];
                [_throttleChannel setValue:0.0];
                //            NSLog(@"throttleValue = %f",throttleValue);
                leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
                                         joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
            }else{
                [_rudderChannel setValue:0.0];
                float throttleValue = [_throttleChannel value];
                //            NSLog(@"throttleValue = %f",throttleValue);
                leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
                                         joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2-throttleValue * leftJoyStickOperableRadius);
            }
        }
        else {
            [_aileronChannel setValue:0.0];
            [_elevatorChannel setValue:0.0];
            leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
                                     joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
        }
        //        leftCenter = CGPointMake(joystickLeftBackground.frame.origin.x+joystickLeftBackground.frame.size.width/2, \
        joystickLeftBackground.frame.origin.y+joystickLeftBackground.frame.size.height/2);
        [self updateVelocity:leftCenter isRight:NO];
        //        NSLog(@"left button is released");
    }
}

- (IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event {
    
    //    NSLog(@"555555555555");
    BOOL _runOnce = YES;
    static float rightBackgroundWidth = 0.0;
    static float rightBackgroundHeight = 0.0;
    static float leftBackgroundWidth = 0.0;
    static float leftBackgroundHeight = 0.0;
    if(_runOnce) {
        rightBackgroundWidth = joystickRightBackground.frame.size.width;
        rightBackgroundHeight = joystickRightBackground.frame.size.height;
        leftBackgroundWidth = joystickLeftBackground.frame.size.width;
        leftBackgroundHeight = joystickLeftBackground.frame.size.height;
        _runOnce = NO;
    }
    
    UITouch *touch = [[event touchesForView:sender]anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    float aileronElevatorValidBandRation = 0.5 - _setting.aileronDeadBand / 2.0;
    float rudderValidBandRation = 0.5 - _setting.rudderDeadBand / 2.0;
    
    if(sender == joystickRightButton && buttonRightPressed) {
        //        NSLog(@"right diddrag");
        float rightJoystickXInput,rightJoystickYInput;
        float rightJoystickXValidBand;//右边摇杆X轴的无效区
        float rightJoystickYValidBand;//右边摇杆y轴的无效区
        
        if(isLeftHanded) {
            rightJoystickXValidBand = aileronElevatorValidBandRation;//X轴操作是Aileron
            rightJoystickYValidBand = aileronElevatorValidBandRation;//Y轴操作是Elevator
        }
        else {
            rightJoystickXValidBand = rudderValidBandRation;
            rightJoystickYValidBand = 0.5;//Y轴操作是油门
        }
        if(!isLeftHanded && rudderIsLocked) {
            rightJoystickXInput = 0.0;
        }
        //左右操作(controlRation * rightBackgoundWidth)是控制的有效区域,所以(rightBackgoundWidth / 2) - (controlRation * rightBackgoundWidth)就是操作盲区了
        else if((rightCenter.x - point.x) > ((rightBackgroundWidth / 2) - (rightJoystickXValidBand * rightBackgroundWidth))) {
            float percent = ((rightCenter.x - point.x) - ((rightBackgroundWidth / 2) - (rightJoystickXValidBand * rightBackgroundWidth))) / (rightJoystickXValidBand * rightBackgroundWidth);
            if(percent > 1.0)
                percent = 1.0;
            rightJoystickXInput = -percent;
        }
        else if((point.x - rightCenter.x) > ((rightBackgroundWidth / 2) - (rightJoystickXValidBand * rightBackgroundWidth))) {
            float percent = ((point.x - rightCenter.x) - ((rightBackgroundWidth / 2) - (rightJoystickXValidBand * rightBackgroundWidth))) / (rightJoystickXValidBand * rightBackgroundWidth);
            if(percent > 1.0)
                percent = 1.0;
            rightJoystickXInput = percent;
        } else {
            rightJoystickXInput = 0.0;
        }
        
        if(isLeftHanded) {
            if(_setting.isBeginnerMode) {
                //                [_aileronChannel setValue:rightJoystickXInput * kBeginnerAileronChannelRatio];
                [_aileronChannel setValue:rightJoystickXInput * kBeginnerAileronChannelRatio * _setting.rollPitchScale];
            } else {
                //                [_aileronChannel setValue:rightJoystickXInput];
                [_aileronChannel setValue:rightJoystickXInput * _setting.rollPitchScale];
            }
        }else {
            if(_setting.isBeginnerMode) {
                //                [_rudderChannel setValue:rightJoystickXInput * kBeginnerRudderChannelRatio];
                [_rudderChannel setValue:rightJoystickXInput * kBeginnerRudderChannelRatio * _setting.yawScale];
            }else {
                //                [_rudderChannel setValue:rightJoystickXInput];
                [_rudderChannel setValue:rightJoystickXInput * _setting.yawScale];
            }
        }
        //上下操作
        //if(!isLeftHanded) {
        //    rightJoystickYInput = _throttleChannel.value;
        // } else if((point.y - rightCenter.y) > ((rightBackgroundHeight / 2) - (rightJoystickYValidBand * rightBackgroundHeight))) {
        if((point.y - rightCenter.y) > ((rightBackgroundHeight / 2) - (rightJoystickYValidBand * rightBackgroundHeight))) {
            float percent = ((point.y - rightCenter.y) - ((rightBackgroundHeight / 2) - (rightJoystickYValidBand * rightBackgroundHeight))) / (rightJoystickYValidBand * rightBackgroundHeight);
            if(percent > 1.0)
                percent = 1.0;
            rightJoystickYInput = -percent;
        } else if((rightCenter.y - point.y) > ((rightBackgroundHeight / 2) - (rightJoystickYValidBand * rightBackgroundHeight))) {
            float percent = ((rightCenter.y - point.y) - ((rightBackgroundHeight / 2) - (rightJoystickYValidBand * rightBackgroundHeight))) / (rightJoystickYValidBand * rightBackgroundHeight);
            if(percent > 1.0)
                percent = 1.0;
            rightJoystickYInput = percent;
        } else {
            //            NSLog(@"xxxxxxxx");
            rightJoystickYInput = 0.0;
        }
        
        if(isLeftHanded) {
            if(_setting.isBeginnerMode) {
                //                [_elevatorChannel setValue:rightJoystickYInput * kBeginnerElevatorChannelRatio];
                [_elevatorChannel setValue:rightJoystickYInput * kBeginnerElevatorChannelRatio * _setting.rollPitchScale];
            } else {
                //                [_elevatorChannel setValue:rightJoystickYInput];
                [_elevatorChannel setValue:rightJoystickYInput * _setting.rollPitchScale];
            }
        }else {
            //            NSLog(@"yyyyyyyyy");
            //            NSLog(@"rightJoystickYInput = %f",rightJoystickYInput);
            if(_setting.isBeginnerMode) {
                [_throttleChannel setValue:(kBeginnerThrottleChannelRatio - 1) + rightJoystickYInput * kBeginnerThrottleChannelRatio];
            } else {
                [_throttleChannel setValue:rightJoystickYInput];
            }
        }
        [self updateVelocity:point isRight:YES];
        //NSLog(@"right button is drag");
    }
    if(sender == joystickLeftButton && buttonLeftPressed) {
        //        NSLog(@"left diddrag");
        //[self updateVelocity:point isRight:NO];
        //NSLog(@"left button is drag");
        float leftJoystickXInput, leftJoystickYInput;
        
        float leftJoystickXValidBand;  //右边摇杆x轴的无效区
        float leftJoystickYValidBand;  //右边摇杆y轴的无效区
        
        if(isLeftHanded){
            leftJoystickXValidBand = rudderValidBandRation;
            leftJoystickYValidBand = 0.5;   //Y轴操作是油门
        }
        else{
            leftJoystickXValidBand = aileronElevatorValidBandRation; //X轴操作是Aileron
            leftJoystickYValidBand = aileronElevatorValidBandRation; //Y轴操作是Elevator
        }
        
        if(isLeftHanded && rudderIsLocked){
            leftJoystickXInput = 0.0;
        }
        else if((leftCenter.x - point.x) > ((leftBackgroundWidth / 2) - (leftJoystickXValidBand * leftBackgroundWidth)))
        {
            float percent = ((leftCenter.x - point.x) - ((leftBackgroundWidth / 2) - (leftJoystickXValidBand * leftBackgroundWidth))) / ((leftJoystickXValidBand * leftBackgroundWidth));
            if(percent > 1.0)
                percent = 1.0;
            
            leftJoystickXInput = -percent;
            
        }
        else if((point.x - leftCenter.x) > ((leftBackgroundWidth / 2) - (leftJoystickXValidBand * leftBackgroundWidth)))
        {
            float percent = ((point.x - leftCenter.x) - ((leftBackgroundWidth / 2) - (leftJoystickXValidBand * leftBackgroundWidth))) / ((leftJoystickXValidBand * leftBackgroundWidth));
            if(percent > 1.0)
                percent = 1.0;
            
            leftJoystickXInput = percent;
        }
        else
        {
            leftJoystickXInput = 0.0;
        }
        
        if(isLeftHanded){
            if(_setting.isBeginnerMode){
                
                [_rudderChannel setValue:leftJoystickXInput * kBeginnerRudderChannelRatio * _setting.yawScale];
            }else{
                
                [_rudderChannel setValue:leftJoystickXInput * _setting.yawScale];
            }
        }
        else{
            if(_setting.isBeginnerMode){
                
                [_aileronChannel setValue:leftJoystickXInput * kBeginnerAileronChannelRatio * _setting.rollPitchScale];
            }else{
                
                [_aileronChannel setValue:leftJoystickXInput * _setting.rollPitchScale];
            }
        }
        
        if((point.y - leftCenter.y) > ((leftBackgroundHeight / 2) - (leftJoystickYValidBand * leftBackgroundHeight)))
        {
            float percent = ((point.y - leftCenter.y) - ((leftBackgroundHeight / 2) - (leftJoystickYValidBand * leftBackgroundHeight))) / ((leftJoystickYValidBand * leftBackgroundHeight));
            if(percent > 1.0)
                percent = 1.0;
            
            leftJoystickYInput = -percent;
        }
        else if((leftCenter.y - point.y) > ((leftBackgroundHeight / 2) - (leftJoystickYValidBand * leftBackgroundHeight)))
        {
            float percent = ((leftCenter.y - point.y) - ((leftBackgroundHeight / 2) - (leftJoystickYValidBand * leftBackgroundHeight))) / ((leftJoystickYValidBand * leftBackgroundHeight));
            if(percent > 1.0)
                percent = 1.0;
            
            leftJoystickYInput = percent;
        }
        else
        {
            leftJoystickYInput = 0.0;
        }
        
        //NSLog(@"left y input:%.3f",leftJoystickYInput);
        
        if(isLeftHanded){
            if (_setting.isBeginnerMode) {
                [_throttleChannel setValue:(kBeginnerThrottleChannelRatio - 1) + leftJoystickYInput * kBeginnerThrottleChannelRatio];
            }
            else{
                [_throttleChannel setValue:leftJoystickYInput];
            }
            
        }
        else{
            if (_setting.isBeginnerMode) {
                //                [_elevatorChannel setValue:leftJoystickYInput * kBeginnerElevatorChannelRatio];
                [_elevatorChannel setValue:leftJoystickYInput * kBeginnerElevatorChannelRatio * _setting.rollPitchScale];
            }
            else{
                //                [_elevatorChannel setValue:leftJoystickYInput];
                [_elevatorChannel setValue:leftJoystickYInput * _setting.rollPitchScale];
            }
        }
        [self updateVelocity:point isRight:NO];
    }
    
}


-(void)doubleTap:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"------doubleTap---------");
    if (isVideo) {
        //SystemSoundID myAlertSound;
        NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/photoShutter.caf"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
        AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
        NSDate *senddate = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc]init];
        [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
        NSString *ImageName = [imagePath stringByAppendingString:[[dateformatter stringFromDate:senddate]stringByAppendingString:@".jpg"]];
        BOOL result = [UIImageJPEGRepresentation(ImageViewBackground.image, 1.0)writeToFile:ImageName atomically:YES];
        if (result) {
            NSLog(@"保存成功");
        }
        
    } else {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"保存失败";
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
        NSLog(@"保存不成功");
    }
    
}


-(void) updateJoystickCenter {
    //    NSLog(@"6666666666");
    rightCenter = CGPointMake(joystickRightInitialPosition.x+joystickRightBackground.frame.size.width/2, \
                              joystickRightInitialPosition.y+joystickRightBackground.frame.size.height/2);
    leftCenter = CGPointMake(joystickLeftInitialPosition.x+joystickLeftBackground.frame.size.width/2, \
                             joystickLeftInitialPosition.y+joystickLeftBackground.frame.size.height/2);
    
    //更新油门点的位置
    
    if(isLeftHanded) {
        
        joystickLeftPoint.center = CGPointMake(leftCenter.x, leftCenter.y-leftJoyStickOperableRadius*_throttleChannel.value);
    }else{
        
        joystickRightPoint.center = CGPointMake(rightCenter.x, rightCenter.y-rightJoyStickOperableRadius*_throttleChannel.value);
    }
    
}

-(void) updateJoyPointCenter:(CGPoint) point isRight:(BOOL)isRight {
    //    NSLog(@"777777777");
    UIImageView *pointImage = (isRight? joystickRightPoint : joystickLeftPoint);
    CGRect frame = pointImage.frame;
    frame.origin.x = point.x - pointImage.frame.size.width/2;
    frame.origin.y = point.y - pointImage.frame.size.height/2;
    pointImage.frame = frame;
}

-(void)refreshJoystickRight {
    //    NSLog(@"8888888888");
    CGRect frame = joystickRightBackground.frame;
    frame.origin = joystickRightCurrentPosition;
    joystickRightBackground.frame = frame;
//    NSLog(@"joystickRightBackground : %@",NSStringFromCGRect(frame));
}

-(void)refreshJoystickLeft {
    //    NSLog(@"999999999999");
    CGRect frame = joystickLeftBackground.frame;
    frame.origin = joystickLeftCurrentPosition;
    joystickLeftBackground.frame = frame;
//    NSLog(@"joystickLeftBackground : %@",NSStringFromCGRect(frame));
}

//更新摇杆点的位置，point是当前触摸点的位置
-(void)updateVelocity:(CGPoint)point isRight:(BOOL)isRight {
    CGPoint nextPoint = CGPointMake(point.x, point.y);
    CGPoint center = (isRight? rightCenter : leftCenter);
    UIImageView *pointImage = (isRight? joystickRightPoint : joystickLeftPoint);
    
    float dx = nextPoint.x - center.x;
    float dy = nextPoint.y - center.y;
    float len = sqrt(dx * dx + dy * dy);
    float point_radius = isRight? rightJoyStickOperableRadius : leftJoyStickOperableRadius;
    
    
    if(len > point_radius) {
        if(dx > 0) {
            
            nextPoint.x = center.x + fabsf(dx)*rightJoyStickOperableRadius/len;
        }else {
            
            nextPoint.x = center.x - fabsf(dx)*rightJoyStickOperableRadius/len;
        }
    }
    
    
    if(len > point_radius) {
        if(dy > 0) {
            
            nextPoint.y = center.y + fabsf(dy)*rightJoyStickOperableRadius/len;
            
        }else {
            
            nextPoint.y = center.y - fabsf(dy)*rightJoyStickOperableRadius/len;
        }
    }
    
    CGRect frame = pointImage.frame;
    frame.origin.x = nextPoint.x - pointImage.frame.size.width/2;
    frame.origin.y = nextPoint.y - pointImage.frame.size.height/2;
    pointImage.frame = frame;
}

-(void) getJoystickBackInitialPosition {
    
    leftJoyStickOperableRadius = rightJoyStickOperableRadius = joystickLeftBackground.frame.size.width/2;//更新点的操作半径
    joystickRightInitialPosition = CGPointMake(joystickRightBackground.frame.origin.x, joystickRightBackground.frame.origin.y);//

    joystickLeftInitialPosition = CGPointMake(joystickLeftBackground.frame.origin.x, joystickLeftBackground.frame.origin.y);

    if(firstTouch == YES) {
        [joystickRightButton setEnabled:YES];
        [joystickLeftButton setEnabled:YES];
    }
}


-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"你好呀");
   
    if(firstTouch == NO) {
        
        firstTouch = YES;
        [self getJoystickBackInitialPosition];
    }
    
}

-(void) switchScan {
    //    NSLog(@"ccccccccccccccc");
    BleSerialManager *manager = [[Transmitter sharedTransmitter]bleSerialManager];
    if([manager isScanning]) {
        [manager stopScan];
    } else {
        [[[Transmitter sharedTransmitter]bleSerialManager]disconnect];
        [manager scan];
        if([manager isScanning]) {
//            NSLog(@"hello world");
        }
    }
}

-(IBAction)buttonClick:(id)sender {
    //    NSLog(@"dddddddddddddd");
    if(firstTouch == NO) { //获取初始坐标
        firstTouch = YES;
        [self getJoystickBackInitialPosition];
    }
    //record video
    if(sender == videoButton) {
        if (isVideo) {
            //static int flag1 = 0;
            if (con_rec_flag == 2) {
                con_rec_flag = 0;
            }
            switch (con_rec_flag) {
                case 0://开始录制视频
                {
                    isRecording = YES;
                    [videoButton setImage:[UIImage imageNamed:@"IconVideo1"] forState:UIControlStateNormal];
                    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"VideoRecord" ofType:@".wav" inDirectory:@"."]];
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
                    AudioServicesPlaySystemSound(myAlertSound); //播放开始录像声音
                    myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(ControlDisplayRec) userInfo:Nil repeats:YES];
                    NSDate *senddate = [NSDate date];
                    NSDateFormatter *dateformatter = [[NSDateFormatter alloc]init];
                    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
                    NSString *ImageName = [videoImagePath stringByAppendingString:[[dateformatter stringFromDate:senddate]stringByAppendingString:@".jpg"]];
                    [UIImageJPEGRepresentation(ImageViewBackground.image, 1.0)writeToFile:ImageName atomically:YES];
                    
                    
                }
                    break;
                    
                case 1://停止录制视频
                    isRecording = NO;
                    [videoButton setImage:[UIImage imageNamed:@"IconVideo"] forState:UIControlStateNormal];
                    
                    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"VideoRecord" ofType:@".wav" inDirectory:@"."]];
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
                    AudioServicesPlaySystemSound(myAlertSound); //播放停止录像声音
                    if (myTimer.isValid) {
                        [myTimer invalidate];
                        _con_rec_label.hidden = YES;
                    }
                    myTimer = nil;
                    break;
            }
            con_rec_flag++;
        }else {

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if (Link_flag == 1) {
                hud.labelText = @"OPENVIDEO";
            }else{
                hud.labelText = @"OFFLINE";
            }
            hud.margin = 10.f;
            hud.yOffset = 150.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:1];
            NSLog(@"保存不成功");
            NSLog(@"不是isvideo");
        }
    }
    if (sender == modeButton) {

        if (flag == 3) {
            flag = 0;
        }
        switch (flag) {
            case 0:

                if (Link_flag == 1) {

                    isVideo = YES;//打开视频标志
                    displayMode = 0;
                    [modeButton setImage:[UIImage imageNamed:@"IconNone"] forState:UIControlStateNormal];
                    
                    if (!myThread) {
                        NSLog(@"create thread");
                        myThread = [[NSThread alloc]initWithTarget:self selector:@selector(displayVideo) object:nil];

                        [myThread start];
                    }else {
                        NSLog(@"start new thread");
                        [myThread cancel];

                        myThread = [[NSThread alloc]initWithTarget:self selector:@selector(displayVideo) object:nil];
                        [myThread start];
                    }
                    
                }else {

                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = @"OFFLINE";
                    hud.margin = 10.f;
                    hud.yOffset = 150.f;
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES afterDelay:1];
                    NSLog(@"Link_flag != 1");
                    
                }

                break;
            case 1:
                displayMode = 1;
                [modeButton setImage:[UIImage imageNamed:@"IconTwice"] forState:UIControlStateNormal];
                break;
            case 2:

                [modeButton setImage:[UIImage imageNamed:@"IconNone"] forState:UIControlStateNormal];
                [videoButton setImage:[UIImage imageNamed:@"IconVideo"] forState:UIControlStateNormal];
                if (isVideo) {
                    if (isRecording) {
                        [videoButton setImage:[UIImage imageNamed:@"IconVideo"] forState:UIControlStateNormal];
                        
                        isRecording = NO;
                        if (myTimer.isValid) {
                            [myTimer invalidate];
                            _con_rec_label.hidden = YES;
                        }
                        con_rec_flag = 0;
                        myTimer = nil;

                    }
                    isVideo = NO;

                    displayMode = 3;
                    
                    ImageViewBackground.hidden = NO;
                    VideoImage1.hidden = YES;
                    VideoImage2.hidden = YES;
                    joystickLeftBackground.hidden = NO;
                    joystickRightBackground.hidden = NO;
                    joystickLeftPoint.hidden = NO;
                    joystickRightPoint.hidden = NO;
                    
                    joystickLeftBackground.alpha = 1;
                    joystickRightBackground.alpha = 1;
                    joystickLeftPoint.alpha = 1;
                    joystickRightPoint.alpha = 1;
                    [myThread cancel];//标记
                    ImageViewBackground.image = [UIImage imageNamed:@"backgound.png"];

                    NSLog(@"stop video recivie");

                }
                break;
        }

        if (Link_flag == 0) {
            flag = 0;
        }else {
            flag ++;
        }
    }

    if(sender == btn_home) {

        [self.delegate controlViewControllerDismissed:self];
                    
    }
    if(sender == lockButton) {

        if ([[[Transmitter sharedTransmitter]bleSerialManager]isConnected]) {
            if (isArm == NO) {
                [_aileronChannel setValue:-1];
                [_throttleChannel setValue:-1];
                [self updateJoystickCenter];
            }else {
                [_aileronChannel setValue:1];
                [_throttleChannel setValue:-1];
                [self updateJoystickCenter];
            }

        }else {

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"蓝牙没有连接";
            hud.margin = 10.f;
            hud.yOffset = 150.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:1];
            NSLog(@"蓝牙没有连接");
        }
        
    }
    if(sender == photoButton) {
        if (isVideo) {

            NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/photoShutter.caf"];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
            AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
            
            NSDate *senddate = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc]init];
            [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
            NSString *ImageName = [imagePath stringByAppendingString:[[dateformatter stringFromDate:senddate]stringByAppendingString:@".jpg"]];
            
            BOOL result = [UIImageJPEGRepresentation(ImageViewBackground.image, 1.0)writeToFile:ImageName atomically:YES];
            if (result) {
                NSLog(@"保存成功");
            }
            //        NSLog(@"res = %d",res);
        }else {

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if (Link_flag == 1) {
                hud.labelText = @"OPENVIDEO";
            }else{
                hud.labelText = @"OFFLINE";
            }
            hud.margin = 10.f;
            hud.yOffset = 150.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:1];
            NSLog(@"不是isVideo");
            
        }
    }
    
    if(sender == takeOff) {
        if ([[[Transmitter sharedTransmitter]bleSerialManager]isConnected]) {
            if (isArm == NO) {//没有解锁

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"没有解锁";
                hud.margin = 10.f;
                hud.yOffset = 150.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:1];
                NSLog(@"没有解锁");
            }else {
                //发送一键起飞、降落命令
                
                if (isTakeOff == NO) {//发送一键起飞命令
                    [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_TAKEOFF)];
                    [_throttleChannel setValue:0];
                }else {//发送一键降落命令
                    
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
            NSLog(@"蓝牙没有连接");
        }

    }

}

-(void) ControlDisplayRec {
    if (isRecording) {
        _con_rec_label.hidden = !_con_rec_label.hidden;
//        NSLog(@"control display label");
    }
}

-(void) displayVideo {
//    if ([[NSThread currentThread] isCancelled]) {
//        [NSThread exit];
//    }
//    [[NetWork getInstance] Camera_display];
//    NSLog(@"YYYYYYYYYYYY");
    if ([[NSThread currentThread] isCancelled]) {
        NSLog(@"thread exit");
        [NSThread exit];
    }
    //    NSLog(@"start display");
//    NSLog(@"current thread = %@",[NSThread currentThread]);
    while (![[NSThread currentThread]isCancelled]){
//    while ([myThread isCancelled]) {
//    while (([NSThread currentThread] == myThread) && [myThread isCancelled]) {
//        [NSThread exit];
//        NSLog(@"start this");
        
    }
}

-(void)keep_live {
//    [network Keep_Alive];
}

-(OSStatus) startTransmission {
    BOOL s = [[Transmitter sharedTransmitter] start];
    return s;
}

-(OSStatus) stopTransmission {
    if(isTransmitting) {
        BOOL s = [[Transmitter sharedTransmitter] stop];
        isTransmitting = !s;
//        NSLog(@"isTransmitting = %d",isTransmitting);
        return !s;
    }else {
        return 0;
    }
}

-(void) checkTakeOff {
    NSLog(@"checkTakeff...");
    isTakeOff = YES;
    [takeOff setImage:[UIImage imageNamed:@"IconLand"] forState:UIControlStateNormal];
}

-(void) checkLanding {
    NSLog(@"checkLanding...");
    isTakeOff = NO;
    [takeOff setImage:[UIImage imageNamed:@"IconTakeOff"] forState:UIControlStateNormal];
}


-(void) ControlCheckVersion {
    NSLog(@"check_flag = %d",check_flag);
    check_flag ++;
    [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_GET_VERSION)];//获取版本号
    NSLog(@"VersionTimer = %d",VersionTimer.isValid);
    
    if (check_flag++ >15) {//停止定时器
        if (VersionTimer.isValid) {
            [VersionTimer invalidate];
            VersionTimer = nil;
            check_flag = 0;
            [_setting setIsThrottleMode:NO];
            [_setting save];
            isThrottleBack = _setting.isThrottleMode;
            takeOff.hidden = YES;//hidden takeoff button
        }
    }
}

-(void) checkVersion {
    NSLog(@"VersionNum = %d",VersionNum);
    //    NSLog(@"mainVersionxxxxx");
    if(VersionNum == 36){
        if (!_setting.isThrottleMode) {
            takeOff.hidden = NO;
        }
        [_setting setIsThrottleMode:TRUE];
        [_setting save];
        isThrottleBack = _setting.isThrottleMode;
        if (VersionTimer.isValid) {
            NSLog(@"Controlerxxxxx");
            [VersionTimer invalidate];
            VersionTimer = nil;
        }
        check_flag = 0;
    }
}

//断开连接
-(void) checkunLinkState {
    //TODO
    
    if (isArm) {
        isArm = NO;
        isTakeOff = NO;
        [takeOff setImage:[UIImage imageNamed:@"IconTakeOff"] forState:UIControlStateNormal];
        [lockButton setImage:[UIImage imageNamed:@"IconLock1"] forState:UIControlStateNormal];
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"蓝牙断开连接";
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1];
    NSLog(@"蓝牙断开连接");
    VersionNum = 0;
    if (VersionTimer.isValid) {
        [VersionTimer invalidate];
    }
    VersionTimer = nil;
    check_flag = 0;
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
    [hud hide:YES afterDelay:1];
    NSLog(@"蓝牙已连接");

    [VersionTimer invalidate];
    VersionTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(ControlCheckVersion) userInfo:nil repeats:YES];
}

-(void) netWorkLink {
    NSLog(@"ControlnetWorkLink........");
    
}

-(void) netWorkunLink {
    NSLog(@"ControlnetWorkunLink......");
    if (isVideo) {
        if (isRecording) {
            [videoButton setImage:[UIImage imageNamed:@"IconVideo_con"] forState:UIControlStateNormal];
            
            isRecording = NO;
            if (myTimer.isValid) {
                [myTimer invalidate];
                _con_rec_label.hidden = YES;
            }
            con_rec_flag = 0;
            myTimer = nil;
        }
        isVideo = NO;
        displayMode = 0;
        flag = 0;
        NSLog(@"display destory....");
        
        
        ImageViewBackground.hidden = NO;
        VideoImage1.hidden = YES;
        VideoImage2.hidden = YES;
        
        joystickLeftBackground.hidden = NO;
        joystickRightBackground.hidden = NO;
        joystickLeftPoint.hidden = NO;
        joystickRightPoint.hidden = NO;
        
        joystickLeftBackground.alpha = 1;
        joystickRightBackground.alpha = 1;
        joystickLeftPoint.alpha = 1;
        joystickRightPoint.alpha = 1;
        
        ImageViewBackground.image = [UIImage imageNamed:@"backgound"];
        [modeButton setImage:[UIImage imageNamed:@"IconNone1"] forState:UIControlStateNormal];
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"VIDEOOFFLINE";
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1];
    NSLog(@"不是isVideo");
}

-(void)checkTransmitterState {
    NSLog(@"checkTransmitterState");
//    ARMState armState = [[[Transmitter sharedTransmitter]osdData]armState];
    TransmitterState inputState = [[Transmitter sharedTransmitter]inputState];
    TransmitterState outputState = [[Transmitter sharedTransmitter]outputState];
    if((inputState == TransmitterStateOk) && (outputState == TransmitterStateOk)) {
//        [bleButton setImage:[UIImage imageNamed:@"btn_ble_connected.png"] forState:UIControlStateNormal];
        
    }else if((inputState == TransmitterStateOk) && (outputState != TransmitterStateOk)) {
        
    }else if((inputState != TransmitterStateOk) && (outputState == TransmitterStateOk)) {
        
    }else {
//        [bleButton setImage:[UIImage imageNamed:@"btn_ble_disconnected.png"] forState:UIControlStateNormal];
    }
}

-(void)checkArmState {
//    NSLog(@"checkArmState.....");
    ARMState armState = [[[Transmitter sharedTransmitter]osdData]armState];
//    NSLog(@"armState = %d",armState);
    if (armState == ARMStateOK) {
//        [_aileronChannel setValue:0];
//        NSLog(@"armed........");
        [lockButton setImage:[UIImage imageNamed:@"IconUnLock"] forState:UIControlStateNormal];
    }else if (armState == DISARMStateOK) {
//        NSLog(@"disarmed.....");
//        [_aileronChannel setValue:0];
        [lockButton setImage:[UIImage imageNamed:@"IconLock"] forState:UIControlStateNormal];
    }else {
        
    }
}

-(void) checkarmState {
//    NSLog(@"checkarmstate");
    isArm = YES;
    //SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"armed" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
    [lockButton setImage:[UIImage imageNamed:@"IconUnLock"] forState:UIControlStateNormal];
    [_aileronChannel setValue:0];
}

-(void) checkarmingState {
//    NSLog(@"checkarmingState");
}

-(void)checkdisarmState {
//    NSLog(@"checkdisarmState");
    isArm = NO;
    isTakeOff = NO;
    //SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle]pathForResource:@"disarmed" ofType:@".wav" inDirectory:@"."]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound); //播放拍照声音
    [lockButton setImage:[UIImage imageNamed:@"IconLock"] forState:UIControlStateNormal];
    [takeOff setImage:[UIImage imageNamed:@"IconTakeOff"] forState:UIControlStateNormal];
    [_aileronChannel setValue:0];
}

- (void)handleNotificationPeripheralListDidChange{
//    NSLog(@"Recv Notification");
}

-(void)updateConnectionState {
    //    NSLog(@"eeeeeeeee");
    CBPeripheral *peripheral = [[[Transmitter sharedTransmitter]bleSerialManager]currentBleSerial];
    //if(isTryingConnect && ![peripheral isConnected]){
    if(isTryingConnect && !(peripheral.state == CBPeripheralStateConnected)) {
        return;
    }else{
        //if([peripheral isConnected]) {
        if(peripheral.state == CBPeripheralStateConnected) {
            isTryingConnect = NO;
        }
    }
}



-(void) updateView:(UIImage *)newImage {
//    NSLog(@"display");
    if (displayMode == 1) {//双屏显示
        ImageViewBackground.hidden = YES;
        VideoImage1.hidden = NO;
        VideoImage2.hidden = NO;
        joystickLeftBackground.hidden = YES;
        joystickRightBackground.hidden = YES;
        joystickLeftPoint.hidden = YES;
        joystickRightPoint.hidden = YES;
        VideoImage1.image = newImage;
        VideoImage2.image = newImage;
    }else if(displayMode == 0){//单屏显示
        VideoImage1.hidden = YES;
        VideoImage2.hidden = YES;
        ImageViewBackground.hidden = NO;
        joystickLeftBackground.hidden = NO;
        joystickRightBackground.hidden = NO;
        joystickLeftPoint.hidden = NO;
        joystickRightPoint.hidden = NO;
        joystickLeftBackground.alpha = 0.4;
        joystickRightBackground.alpha = 0.4;
        joystickLeftPoint.alpha = 0.4;
        joystickRightPoint.alpha = 0.4;
        ImageViewBackground.image = newImage;
    }

}

-(void) dispaly:(char *)pFrameRGB length:(int)len nWidth:(int)nWidth nHeight:(int)nHeight {
    if(len > 0)
    {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)pFrameRGB, nWidth*nHeight*3,kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef cgImage = CGImageCreate(nWidth,
                                           nHeight,
                                           8,
                                           24,
                                           nWidth*3,
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           YES,
                                           kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        //UIImage *image = [UIImage imageWithCGImage:cgImage];
        UIImage* image = [[UIImage alloc]initWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
//                NSLog(@"xxxxxxx");
        //返回主线程更新界面
        [self performSelectorOnMainThread:@selector(updateView:) withObject:image waitUntilDone:YES];
        //[image release];
        //        VideoImage.image = image;
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"setViewModeSegue"]) {
        SetViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}


#pragma mark -- SetTableViewDelegate
-(void) setTableViewControllerDismissed:(SetTableViewController *)controller {
    NSLog(@"controller");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -- SetViewControllerDelegate
-(void) setViewControllerDismissed:(SetViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}




@end
