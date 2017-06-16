//
//  VideoPlaybackViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-3-10.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "MpbPopoverViewController.h"
#import "VideoPlaybackProgressView.h"
#import "VideoPlaybackProgressViewBg.h"
#import "MBProgressHUD.h"
#import "HYOpenALHelper.h"
#import "AppDelegate.h"
#include "MpbSDKEventListener.h"


@interface VideoPlaybackViewController () {
  UIPopoverController *_popController;
  UIActionSheet *_actionsSheet;
  VideoPbProgressListener *videoPbProgressListener;
  VideoPbProgressStateListener *videoPbProgressStateListener;
  VideoPbDoneListener *videoPbDoneListener;
  VideoPbServerStreamErrorListener *videoPbServerStreamErrorListener;
}

#pragma mark - Outlet
@property(strong, nonatomic) IBOutlet UIImageView *previewThumb;
@property(weak, nonatomic) IBOutlet VideoPlaybackProgressView *playbackController;
@property(weak, nonatomic) IBOutlet VideoPlaybackProgressViewBg *videoPbProgressBg;
@property(strong, nonatomic) IBOutlet UIView *pbCtrlPanel;
@property(weak, nonatomic) IBOutlet UILabel *videoPbTotalTime;
@property(weak, nonatomic) IBOutlet UILabel *videoPbElapsedTime;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property(weak, nonatomic) IBOutlet UIButton *playbackButton;
#pragma mark - State
@property(nonatomic, getter = isPlayed) BOOL played;
@property(nonatomic, getter = isPaused) BOOL paused;
@property(nonatomic, getter =  isControlHidden) BOOL controlHidden;
@property(nonatomic) dispatch_semaphore_t semaphore;
@property(nonatomic) NSTimer *pbTimer;
@property(nonatomic) double totalSecs;
@property(nonatomic) double playedSecs;
@property(nonatomic) double videoCurSecs;
@property(nonatomic) NSUInteger downloadedPercent;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) HYOpenALHelper *al;
@property(nonatomic) BOOL seeking;
@property(nonatomic) BOOL exceptionHappen;

@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamPhotoGallery *gallery;
@property(nonatomic) WifiCamControlCenter *ctrl;

@end

@implementation VideoPlaybackViewController

@synthesize previewImage;
@synthesize index;

#pragma mark - Lifecycle
- (void)viewDidLoad
{
  AppLog(@"%s", __func__);
  [super viewDidLoad];
  
  WifiCamManager *app = [WifiCamManager instance];
  self.wifiCam = [app.wifiCams objectAtIndex:0];
  self.camera = _wifiCam.camera;
  self.gallery = _wifiCam.gallery;
  self.ctrl = _wifiCam.controler;
  
  ICatchFile file = _gallery.videoTable.fileList.at(index);
  self.title = [NSString stringWithFormat:@"%s", file.getFileName().c_str()];
  /*
   AppLog(@"w:%f, h:%f", _previewThumb.bounds.size.width, _previewThumb.bounds.size.height);
   UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(_previewThumb.bounds.size.width/2-28,
   _previewThumb.bounds.size.height/2-28,
   56, 56)];
   [playButton setImage:[UIImage imageNamed:@"detail_play_normal"] forState:UIControlStateNormal];
   [self.view addSubview:playButton];
   */
  _previewThumb.image = previewImage;
  _totalSecs = 0;
  _playedSecs = 0;
  
  [_playbackController addTarget:self
                          action:@selector(sliderValueChanged:)
                forControlEvents:UIControlEventValueChanged];
  _playbackController.maximumValue = _totalSecs;
  _playbackController.minimumValue = 0;
  //[_playbackController setThumbImage:[UIImage imageNamed:@"bullet_white"] forState:UIControlStateNormal];
  _playbackController.value = 0;
  
  self.semaphore = dispatch_semaphore_create(1);
  
  
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(recoverFromDisconnection)
                                           name    :@"kCameraNetworkConnectedNotification"
                                           object  :nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleDisconnection)
                                           name    :@"kCameraNetworkDisconnectedNotification"
                                           object  :nil];
  
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  /*
  [self showProgressHUDWithMessage:nil
                    detailsMessage:nil
                              mode:MBProgressHUDModeIndeterminate];
  */
  [self playbackButtonPressed:self.playbackButton];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  if (_played) {
    [self removePbObserver];
    [_ctrl.pbCtrl stop];
    self.played = NO;
  }
  
  if (_popController.popoverVisible) {
    [_popController dismissPopoverAnimated:YES];
  }
  if (_actionsSheet.visible) {
    [_actionsSheet dismissWithClickedButtonIndex:0 animated:NO];
  }
  if (self.progressHUD.alpha != 0) {
    [self hideProgressHUD:NO];
  }
}

-(void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
  TRACE();
  _previewThumb = nil;
  _pbCtrlPanel = nil;
}

-(void)recoverFromDisconnection
{
  TRACE();
  [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)handleDisconnection
{
  TRACE();
  if (_played) {
    [self removePbObserver];
    [_ctrl.pbCtrl stop];
    self.played = NO;
    
  }
}

#pragma mark - Observer
- (void)addPbObserver
{
  videoPbProgressListener = new VideoPbProgressListener(self);
  [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                    listener:videoPbProgressListener
                 isCustomize:NO];
  videoPbProgressStateListener = new VideoPbProgressStateListener(self);
  [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                    listener:videoPbProgressStateListener
                 isCustomize:NO];
  videoPbDoneListener = new VideoPbDoneListener(self);
  [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_STREAM_PLAYING_ENDED
                    listener:videoPbDoneListener
                 isCustomize:NO];
  videoPbServerStreamErrorListener = new VideoPbServerStreamErrorListener(self);
  [_ctrl.comCtrl addObserver:ICATCH_EVENT_SERVER_STREAM_ERROR
                    listener:videoPbServerStreamErrorListener
                 isCustomize:NO];
}

- (void)removePbObserver
{
  if (videoPbProgressListener) {
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                         listener:videoPbProgressListener
                      isCustomize:NO];
    delete videoPbProgressListener; videoPbProgressListener = NULL;
  }
  if (videoPbProgressStateListener) {
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                         listener: videoPbProgressStateListener
                      isCustomize:NO];
    delete videoPbProgressStateListener; videoPbProgressStateListener = NULL;
  }
  if (videoPbDoneListener) {
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_STREAM_PLAYING_ENDED
                         listener:videoPbDoneListener
                      isCustomize:NO];
    delete videoPbDoneListener; videoPbDoneListener = NULL;
  }
  if (videoPbServerStreamErrorListener) {
    [_ctrl.comCtrl removeObserver:ICATCH_EVENT_SERVER_STREAM_ERROR
                         listener:videoPbServerStreamErrorListener
                      isCustomize:NO];
    delete videoPbServerStreamErrorListener; videoPbServerStreamErrorListener = NULL;
  }
  
}

- (void)updateVideoPbProgress:(double)value
{
  self.videoPbProgressBg.value = value/self.totalSecs;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.videoPbProgressBg setNeedsDisplay];
  });
}

- (void)updateVideoPbProgressState:(BOOL)caching
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (caching) {
      [_al pause];
      [_pbTimer invalidate];
      /*
      [self showProgressHUDWithMessage:nil
                        detailsMessage:nil
                                  mode:MBProgressHUDModeIndeterminate];      
       */
    } else {
      //[self hideProgressHUD:YES];
      self.seeking = NO;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.pbTimer isValid]) {
          self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target  :self
                                                        selector:@selector(updateTimeInfo:)
                                                        userInfo:nil
                                                         repeats:YES];
        }
      });
    }
  });
}

- (void)stopVideoPb
{
  if (_played) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_ctrl.pbCtrl stop];
      self.played = NO;
      self.playedSecs = 0;
      dispatch_async(dispatch_get_main_queue(), ^{
        [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
                         forState:UIControlStateNormal];
        [_pbTimer invalidate];
        _videoPbElapsedTime.text = @"00:00:00";
        _playbackController.value = 0;
        self.videoCurSecs = 0;
      });
      
      // Finally, remove all the observers for playback
      [self removePbObserver];
      
    });
  }
  
}

- (void)showServerStreamError
{
  AppLog(@"server error!");
  self.exceptionHappen = YES;
  [self stopVideoPb];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self showProgressHUDNotice:NSLocalizedString(@"CameraPbError", nil) showTime:2.0];
  });
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"downloadedPercent"]) {
    [self updateProgressHUDWithMessage:nil detailsMessage:nil];
  }
}

#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
  if (!_progressHUD) {
    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _progressHUD.minSize = CGSizeMake(120, 120);
    _progressHUD.minShowTime = 1;
    [self.view addSubview:_progressHUD];
    [self.view bringSubviewToFront:self.videoPbProgressBg];
  }
  return _progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time{
  if (message) {
    //[self.view bringSubviewToFront:self.progressHUD];
    [self.progressHUD show:YES];
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeText;
    //self.progressHUD.dimBackground = YES;
    [self.progressHUD hide:YES afterDelay:time];
  } else {
    [self.progressHUD hide:YES];
  }
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode{
  if (_progressHUD.alpha == 0 ) {
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = dMessage;
    self.progressHUD.mode = mode;
    //self.progressHUD.dimBackground = YES;
    [self.progressHUD show:YES];
    
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = NO;
  }
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage {
  if (message) {
    self.progressHUD.labelText = message;
  }
  if (dMessage) {
    self.progressHUD.detailsLabelText = dMessage;
  }
  self.progressHUD.progress = _downloadedPercent / 100.0;
}

- (void)hideProgressHUD:(BOOL)animated {
  [self.progressHUD hide:animated];
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  self.navigationController.toolbar.userInteractionEnabled = YES;
}

#pragma mark - VideoPB
- (IBAction)sliderValueChanged:(VideoPlaybackProgressView *)slider {
  AppLog(@"value : %f", slider.value);

  if (_played) {
    self.seeking = YES;
    self.playedSecs = slider.value;
    _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_ctrl.pbCtrl seek:slider.value];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self playbackButtonPressed:self.playbackButton];
      });
      
    });

  } else {
    [self showProgressHUDNotice:@"Seek failed." showTime:1.5];
    slider.value = 0;
  }
}

- (IBAction)sliderTouchDown:(id)sender {
  TRACE();
  if (_played && !_paused) {
    [self playbackButtonPressed:self.playbackButton];
  }
}

- (void)updateTimeInfo:(NSTimer *)sender {
  if (!_seeking) {
    self.playedSecs = _videoCurSecs;
    float sliderPercent = _playedSecs/_totalSecs; // slider value
    dispatch_async(dispatch_get_main_queue(), ^{
      _playbackController.value = [@(_playedSecs) floatValue];
      _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];
      
      if (sliderPercent > self.videoPbProgressBg.value) {
        self.videoPbProgressBg.value = sliderPercent;
        [self.videoPbProgressBg setNeedsDisplay];
      }
    });
  } else {
    AppLog(@"seeking");
  }
}

- (IBAction)playbackButtonPressed:(UIButton *)pbButton {
  dispatch_queue_t audioQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Audio", 0);
  dispatch_queue_t videoQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Video", 0);
  
  if (_played && !_paused) {
    // Update GUI
    [pbButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
              forState:UIControlStateNormal];
    [_pbTimer invalidate];
    
    // Pause
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_ctrl.pbCtrl pause];
      self.paused = YES;
    });
    
  } else {
    // Update GUI
    [pbButton setImage:[UIImage imageNamed:@"videoplayer_control_pause"]
              forState:UIControlStateNormal];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
      dispatch_semaphore_wait(self.semaphore, time);
      
      if (_playedSecs <= 0) {
        
        [self addPbObserver];
        ICatchFile file = _gallery.videoTable.fileList.at(index);
        self.totalSecs = [_ctrl.pbCtrl play:&file];
        
        
        ///
        //[_ctrl.pbCtrl seek:0];

        AppLog(@"totalSecs: %f", _totalSecs);
        self.played = YES;
        self.paused = NO;
        self.exceptionHappen = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
          _videoPbElapsedTime.text = @"00:00:00";
          _videoPbTotalTime.text = [Tool translateSecsToString:_totalSecs];
          _playbackController.maximumValue = _totalSecs;
        });
        
      } else {
        // Resume
        [_ctrl.pbCtrl resume];
        self.paused = NO;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                      target  :self
                                                      selector:@selector(updateTimeInfo:)
                                                      userInfo:nil
                                                      repeats :YES];
      });
      
      dispatch_group_t group = dispatch_group_create();
      if ([_ctrl.pbCtrl audioPlaybackStreamEnabled]) {
        AppLog(@"Audio is enabled");
        dispatch_group_async(group, audioQueue, ^{[self playAudio];});
      }
      if ([_ctrl.pbCtrl videoPlaybackStreamEnabled]) {
        AppLog(@"Video is enabled");
        dispatch_group_async(group, videoQueue, ^{[self playVideo];});
      }
      dispatch_queue_t gQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
      dispatch_group_notify(group, gQueue, ^{
        dispatch_semaphore_signal(self.semaphore);
      });
      
    });
    
  }
  
}

- (void)playVideo
{
  
  UIImage *receivedImage = nil;
  while (_played && !_paused) {
    WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
    if (_exceptionHappen) {
      break;
    }
    if ((wifiCamData.state != ICH_SUCCEED) && (wifiCamData.state != ICH_TRY_AGAIN)) {
      if ((wifiCamData.state != ICH_VIDEO_STREAM_CLOSED) && (wifiCamData.state != ICH_AUDIO_STREAM_CLOSED)) {
        AppLog(@"wifiCamData.state: %d", wifiCamData.state);
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
          [self showProgressHUDNotice:NSLocalizedString(@"CameraPbError", nil) showTime:2.0];
        });
         */
      } else {
        AppLog(@"Exception happened!");
        self.exceptionHappen = YES;
      }
      break;
    }
    
    if (wifiCamData.time != 0) {
      //AppLog(@"videoCurSecs: %f", wifiCamData.time);
      self.videoCurSecs = wifiCamData.time;
    } else {
      AppLog(@"[Error]PresentationTime is 0");
    }
    
    if (wifiCamData.data != nil) {
      receivedImage = [[UIImage alloc] initWithData:wifiCamData.data];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (receivedImage) {
          _previewThumb.image = receivedImage;
        }
      });
      receivedImage = nil;
    }
  }
  AppLog(@"quit video");
}

- (void)playAudio
{
    NSData *audioBufferData = nil;
    NSMutableData *audioBuffer10Data = [[NSMutableData alloc] init];
    self.al = [[HYOpenALHelper alloc] init];
    ICatchAudioFormat format = [_ctrl.propCtrl retrievePlaybackAudioFormat];
    AppLog(@"freq: %d, chl: %d, bit:%d", format.getFrequency(), format.getNChannels(), format.getSampleBits());
    
    if (![_al initOpenAL:format.getFrequency() channel:format.getNChannels() sampleBit:format.getSampleBits()]) {
        AppLog(@"Init openAL failed.");
        return;
    }
    
    while ( _played  && !_paused && !_exceptionHappen ) {
        
        int count = [_al getInfo];
        if(count < 20) {
            if (count > 3 ) {
                [_al play];
            }
            AppLog(@"Only [%d] Buffer", count);
            [audioBuffer10Data setLength:0];
            
            NSDate *begin = [NSDate date];
            for (int i=0; i< 20; ++i) {
                //                NSDate *begin1 = [NSDate date];
                //                audioBufferData = [[SDK instance] getPlaybackAudioData2];
                audioBufferData = [[_ctrl.propCtrl prepareDataForPlaybackAudioTrack] data];
                if (audioBufferData) {
                    //AppLog(@"apped audio 1 ");
                    [audioBuffer10Data appendData:audioBufferData];
                }
                //                NSDate *end1 = [NSDate date];
                //                NSTimeInterval elapse1 = [end1 timeIntervalSinceDate:begin1];
                //                AppLog(@"After: %f", elapse1);
                
                
            }
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
            AppLog(@"Get %lu, elapse: %f", (unsigned long)audioBuffer10Data.length, elapse);
            
            if(audioBuffer10Data.length>0) {
                [_al insertPCMDataToQueue:audioBuffer10Data.bytes
                                     size:audioBuffer10Data.length];
            }
            
        } else {
            // app 太快
            AppLog(@"FULL");
            [_al play];
            [NSThread sleepForTimeInterval:0.005];
        }

    }
    AppLog(@"quit audio, %d, %d, %d", _played, _paused, _exceptionHappen);
    
    [_al clean];
    self.al = nil;


}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
  if (_played && !_paused) {
    [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
                     forState:UIControlStateNormal];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_ctrl.pbCtrl pause];
      self.paused = YES;
    });
    
    [_pbTimer invalidate];
  }
  if (_popController.popoverVisible) {
    [_popController dismissPopoverAnimated:YES];
  }
  
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    UIViewController *vc = [[UIViewController alloc] init];
    UIButton *testButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 260.0f, 47.0f)];
    [testButton setTitle:NSLocalizedString(@"SureDelete", @"") forState:UIControlStateNormal];
    [testButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f
                                                                                                         topCapHeight:0.0f]
                          forState:UIControlStateNormal];
    [testButton addTarget:self action:@selector(deleteDetail:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:testButton];
    
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:vc];
    popController.popoverContentSize = CGSizeMake(260.0f, 47.0f);
    _popController = popController;
    [_popController presentPopoverFromBarButtonItem:_deleteButton
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
  } else {
    _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                  destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                       otherButtonTitles:nil, nil];
    _actionsSheet.tag = ACTION_SHEET_DELETE_ACTIONS;
    [_actionsSheet showFromBarButtonItem:sender animated:YES];
  }
}

- (IBAction)deleteDetail:(id)sender
{
  if ([sender isKindOfClass:[UIButton self]]) {
    [_popController dismissPopoverAnimated:YES];
  }
  
  [self showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil) detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    BOOL deleteResult = NO;
    
    if([_delegate respondsToSelector:@selector(videoPlaybackController:deleteVideoAtIndex:)]) {
      deleteResult = [self.delegate videoPlaybackController:self deleteVideoAtIndex:index];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (deleteResult) {
        [self hideProgressHUD:YES];
        [self.navigationController popToRootViewControllerAnimated:YES];
      } else {
        [self showProgressHUDNotice:NSLocalizedString(@"DeleteError", nil) showTime:2.0];
      }
      
    });
    
  });
}


- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender {
  if (_played && !_paused) {
    [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"] forState:UIControlStateNormal];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_ctrl.pbCtrl pause];
      self.paused = YES;
    });
    
    [_pbTimer invalidate];
  }
  
  if (_popController.popoverVisible) {
    [_popController dismissPopoverAnimated:YES];
  }
  
  ICatchFile file = _gallery.videoTable.fileList.at(index);
  unsigned long long size = file.getFileSize() >> 20;
  double downloadTime = ((double)size)/60;
  //downloadTime = MAX(1, downloadTime);
  
  NSString *confrimButtonTitle = nil;
  NSString *message = NSLocalizedString(@"DownloadConfirmMessage", nil);
  message = [message stringByReplacingOccurrencesOfString:@"%1"
                                               withString:[NSString stringWithFormat:@"%d", 1]];
  message = [message stringByReplacingOccurrencesOfString:@"%2"
                                               withString:[NSString stringWithFormat:@"%.2f", downloadTime]];
  confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
  
  
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
    contentViewController.msg = message;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
      contentViewController.msgColor = [UIColor blackColor];
    } else {
      contentViewController.msgColor = [UIColor whiteColor];
    }
    
    UIButton *downloadConfirmButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 120.0f, 260.0f, 47.0f)];
    [downloadConfirmButton setTitle:confrimButtonTitle
                           forState:UIControlStateNormal];
    [downloadConfirmButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                                     forState:UIControlStateNormal];
    [downloadConfirmButton addTarget:self action:@selector(downloadDetail:) forControlEvents:UIControlEventTouchUpInside];
    [contentViewController.view addSubview:downloadConfirmButton];
    
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
    _popController = popController;
    [_popController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  } else {
    NSString *msg = message;
    _actionsSheet = [[UIActionSheet alloc] initWithTitle:msg
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                  destructiveButtonTitle:confrimButtonTitle
                                       otherButtonTitles:nil, nil];
    _actionsSheet.tag = ACTION_SHEET_DOWNLOAD_ACTIONS;
    //[self.sheet showInView:self.view];
    //[self.sheet showInView:[UIApplication sharedApplication].keyWindow];
    [_actionsSheet showFromBarButtonItem:_actionButton animated:YES];
  }
}

- (IBAction)downloadDetail:(id)sender
{
  dispatch_queue_t downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Donwload", 0);
  
  if ([sender isKindOfClass:[UIButton self]]) {
    [_popController dismissPopoverAnimated:YES];
  }
  
  [self addObserver:self forKeyPath:@"downloadedPercent" options:NSKeyValueObservingOptionNew context:nil];
  [self showProgressHUDWithMessage:nil
                    detailsMessage:nil
                              mode:MBProgressHUDModeAnnularDeterminate];  
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [_ctrl.fileCtrl resetDownloadingToggle:YES];
    
    UIApplication  *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier downloadTask;
    downloadTask = [app beginBackgroundTaskWithExpirationHandler:^{
      
      AppLog(@"-->expiration");
      NSArray *oldNotifications = [app scheduledLocalNotifications];
      // Clear out the old notification before scheduling a new one
      if ([oldNotifications count] > 5) {
        [app cancelAllLocalNotifications];
      }
      
      UILocalNotification *alarm = [[UILocalNotification alloc] init];
      if (alarm) {
        alarm.fireDate = [NSDate date];
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        NSString *str = [NSString stringWithFormat:@"App is about to exit .Please bring it to foreground to continue dowloading."];
        alarm.alertBody = str;
        alarm.soundName = UILocalNotificationDefaultSoundName;
        
        [app scheduleLocalNotification:alarm];
      }
    }];
    
    NSInteger downloadedPhotoNum = 0;
    NSInteger downloadedVideoNum = 1;
    BOOL downloadResult = YES;
    
    ICatchFile file = _gallery.videoTable.fileList.at(index);
    ICatchFile *pFile = &file;
    dispatch_async(downloadQueue, ^{
      while (_downloadedPercent < 100) {
        self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:pFile];
      }
    });
    downloadResult = [_ctrl.fileCtrl downloadFile:pFile];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *message = nil;
      if (downloadResult) {
        message = NSLocalizedString(@"DownloadDoneMessage", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%ld", (long)downloadedPhotoNum]];
        message = [message stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%ld", (long)downloadedVideoNum]];
        /*
        [self hideProgressHUD:YES];
        
         UIAlertView *alert = [[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"Download", nil)
         message           :message
         delegate          :nil
         cancelButtonTitle :NSLocalizedString(@"Sure", nil)
         otherButtonTitles :nil, nil];
         [alert show];
         */
      } else {
        //SaveError
        message = NSLocalizedString(@"SaveError", nil);
      }
      
      [self showProgressHUDNotice:message showTime:3.0];
    });
    [self removeObserver:self forKeyPath:@"downloadedPercent"];
    [_ctrl.fileCtrl resetDownloadingToggle:NO];
    [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
    //downloadTask = UIBackgroundTaskInvalid;
  });
}

#pragma mark - Gesture
- (IBAction)tapToHideControl:(UITapGestureRecognizer *)sender {
  if (_controlHidden) {
    [_previewThumb setBackgroundColor:[UIColor whiteColor]];
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO];
    _pbCtrlPanel.hidden = NO;
  } else {
    [_previewThumb setBackgroundColor:[UIColor blackColor]];
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
    _pbCtrlPanel.hidden = YES;
  }
  self.controlHidden = !_controlHidden;
}

- (IBAction)panToFastMove:(UIPanGestureRecognizer *)sender {
  AppLog(@"%s", __func__);
  
}


#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  _actionsSheet = nil;
  
  switch (actionSheet.tag) {
    case ACTION_SHEET_DOWNLOAD_ACTIONS:
      if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self downloadDetail:self];
      }
      break;
      
    case ACTION_SHEET_DELETE_ACTIONS:
      if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self deleteDetail:self];
      }
      break;
      
    default:
      break;
  }
  
}

#pragma mark - UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  _popController = nil;
}

@end
