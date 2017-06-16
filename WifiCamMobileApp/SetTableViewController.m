//
//  SetTableViewController.m
//  WCMapp2
//
//  Created by Tempo on 16/7/12.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "SetTableViewController.h"
#import "OSDCommon.h"
#import "OSDData.h"
#import "Transmitter.h"
#import "MMProgressHUD.h"
#import "MBProgressHUD.h"
#import "ViewController.h"
@interface SetTableViewController (){

    Settings *_settings;
    int count;
}

@end

@implementation SetTableViewController

- (IBAction)CalibrationAction:(UIButton *)sender {
    
    if (![[[Transmitter sharedTransmitter]bleSerialManager]isConnected]) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"蓝牙没有连接";
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
    }else {
        if (count++ > 1) {
            count = 0;
        }else {
            if(count != 2) {
                NSLog(@"count = %d",count);

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"再点击一次";
                hud.margin = 10.f;
                hud.yOffset = 150.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:1];
            }else {
                
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"校准中...";
                hud.margin = 10.f;
                hud.yOffset = 150.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:1];
                [[[Transmitter sharedTransmitter]bleSerialManager]sendData:getSimpleCommand(MSP_CALIBRATION)];
                self.calibrationBut.enabled = NO;
                
            }
        }
    }
}

- (id)initWithSetting:(Settings *)settings{

    self = [super init];
    if (self) {
        _settings = settings;
    }
    return self;
}

- (void)viewDidLoad{

    [super viewDidLoad];
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    _settings = [[Settings alloc]initWithSettingsFile:userSettingsFilePath];
    
    self.leftHand.on = _settings.isLeftHanded;
    [self.leftHand addTarget:self action:@selector(settingsSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
    
    self.selfie.on = _settings.isSelfMode;
    [self.selfie addTarget:self action:@selector(settingsSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
    
    self.throttleBack.on = _settings.isThrottleMode;
    [self.throttleBack addTarget:self action:@selector(settingsSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
    
    self.HDmodel.on = _settings.isHDMode;
    [self.HDmodel addTarget:self action:@selector(settingsSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
    
    self.qhLabel.text = [NSString stringWithFormat:@"%d",(int)(_settings.rollPitchScale*100/0.6)];
    self.qhSlider.value = _settings.rollPitchScale/0.6;
    [self.qhSlider addTarget:self action:@selector(updateSliderValueIndicator:) forControlEvents:UIControlEventValueChanged];
    
    self.ztLabel.text = [NSString stringWithFormat:@"%d",(int)(_settings.yawScale*100)];
    self.ztSlider.value = _settings.yawScale;
    [self.ztSlider addTarget:self action:@selector(updateSliderValueIndicator:) forControlEvents:UIControlEventValueChanged];
    
    self.calibrationLabel.text = [NSString stringWithFormat:@"%d",0];
    self.calibrationProgress.progress = 0.0;
    count = 0;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkProcessValue) name:kSetCalibrationDidChange object:nil];
    
}

//返回单手操控页面
- (IBAction)backAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

//校准操作
- (void) checkProcessValue {
    self.calibrationLabel.text = [NSString stringWithFormat:@"%d",Process];
    self.calibrationProgress.progress = (float)(Process/100.0);
    if (Process == 100) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"校准完成";
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
        self.calibrationBut.enabled = YES;

    }
}

//设置模式状态
- (void)settingsSwitchToggled:(id)sender
{
    UISwitch *settingsSwitch = (UISwitch *)sender;
    
    //Update Scanning/Connection settings.
    switch (settingsSwitch.tag) {
            
        case 101:
            [_settings setIsLeftHanded:settingsSwitch.on];
            break;
        case 102:
            [_settings setIsSelfMode:settingsSwitch.on];
            break;
        case 103:
            [_settings setIsThrottleMode:settingsSwitch.on];
            break;
        case 104:
            [_settings setIsHDMode:settingsSwitch.on];
            break;
    }
    [_settings save];
}

//改变灵敏度
-(void)updateSliderValueIndicator:(id)sender {
    UISlider *slider = (UISlider *)sender;
    switch (slider.tag) {
        case 103:
            [_settings setRollPitchScale:slider.value*0.6];//限制 该值在0-0.6之间
            self.qhLabel.text = [NSString stringWithFormat:@"%d",(int)(slider.value*100)];
            break;
            
        case 104:
            [_settings setYawScale:slider.value];
            self.ztLabel.text = [NSString stringWithFormat:@"%d",(int)(slider.value*100)];
            break;
    }
    [_settings save];
}

- (void)viewWillDisappear:(BOOL)animated{

    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kSetCalibrationDidChange object:nil];
}
@end
