//
//  ViewController_ViewControllerPrivate.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-2-28.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "HYOpenALHelper.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "SBTableAlert.h"
#import "StartViewController.h"

enum SettingState{
  SETTING_DELAY_CAPTURE = 0,
  SETTING_STILL_CAPTURE,
  SETTING_VIDEO_CAPTURE
};

@class Camera;

@interface ViewController ()
<
UIAlertViewDelegate,
SBTableAlertDelegate,
SBTableAlertDataSource,
UITableViewDelegate,
UITableViewDataSource,
AppDelegateProtocol
>

@property(weak, nonatomic) IBOutlet UIImageView *preview;
@property(weak, nonatomic) IBOutlet UIButton    *cameraToggle;
@property(weak, nonatomic) IBOutlet UIButton    *videoToggle;
@property(weak, nonatomic) IBOutlet UIButton    *timelapseToggle;
@property(weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property(weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property(weak, nonatomic) IBOutlet UILabel *zoomValueLabel;
@property(weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property(weak, nonatomic) IBOutlet UIButton    *mpbToggle;
@property(weak, nonatomic) IBOutlet UIImageView *batteryState;
@property(weak, nonatomic) IBOutlet UIImageView *awbLabel;
@property(weak, nonatomic) IBOutlet UIImageView *timelapseStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *slowMotionStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *invertModeStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *burstCaptureStateImageView;
@property(weak, nonatomic) IBOutlet UIButton    *selftimerButton;
@property(weak, nonatomic) IBOutlet UILabel     *selftimerLabel;
@property(weak, nonatomic) IBOutlet UIButton    *sizeButton;
@property(weak, nonatomic) IBOutlet UILabel     *sizeLabel;
@property(weak, nonatomic) IBOutlet UIButton    *settingButton;
@property(weak, nonatomic) IBOutlet UIButton    *snapButton;
@property(weak, nonatomic) IBOutlet UILabel *movieRecordTimerLabel;

@property(nonatomic) MPMoviePlayerController *h264player;

@property(nonatomic, getter = isPVRun) BOOL PVRun;
@property(nonatomic, getter = isPVRunning) BOOL PVRunning;
@property(nonatomic, getter = isVideoCaptureStopOn) BOOL videoCaptureStopOn;
@property(nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;

@property(nonatomic) enum SettingState curSettingState;
@property(nonatomic) NSMutableArray *alertTableArray;
@property(nonatomic) WifiCamAlertTable* tbDelayCaptureTimeArray;
@property(nonatomic) WifiCamAlertTable* tbPhotoSizeArray;
@property(nonatomic) WifiCamAlertTable* tbVideoSizeArray;
@property(nonatomic) dispatch_semaphore_t previewSemaphore;
@property(strong, nonatomic) SBTableAlert* sbTableAlert;
@property(strong, nonatomic) CustomIOS7AlertView* customIOS7AlertView;
@property(nonatomic) UIAlertView *normalAlert;
@property(nonatomic) NSTimer *videoCaptureTimer;
@property(nonatomic) int elapsedVideoRecordSecs;
@property(nonatomic) NSTimer *burstCaptureTimer;
@property(nonatomic) NSUInteger burstCaptureCount;
@property(nonatomic) NSTimer *hideZoomControllerTimer;

@property(nonatomic) UIImage *stopOn;
@property(nonatomic) UIImage *stopOff;
@property(nonatomic) uint movieRecordElapsedTimeInSeconds;
@property(nonatomic) SystemSoundID stillCaptureSound;
@property(nonatomic) SystemSoundID videoCaptureSound;
@property(nonatomic) SystemSoundID delayCaptureBeep;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) AudioFileStreamID outAudioFileStream;
@property(nonatomic) HYOpenALHelper *al;

@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) WifiCamStaticData *staticData;


@property (nonatomic) dispatch_group_t previewGroup;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t videoQueue;

@end