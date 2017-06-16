//
//  ViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBTableAlert.h"
//#import "StartViewController.h"
#import "Channel.h"
#import "Settings.h"
typedef enum : NSUInteger {
  MovieRecStarted,
  MovieRecStoped,
} MovieRecState;


@interface ViewController : UIViewController
- (void)showReconnectAlert;
// Listener call-back
- (void)updateMovieRecState:(MovieRecState)state;
- (void)updateBatteryLevel;
- (void)stopStillCapture;
- (void)stopTimelapse;
- (void)timelapseStartedNotice;
- (void)timelapseCompletedNotice;
- (void)postMovieRecordTime;
- (void)postMovieRecordFileAddedEvent;

@property (weak, nonatomic) IBOutlet UIImageView *point;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UIButton *click;



-(IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event;
-(IBAction)joystickButtonDidTouchUp:(id)sender forEvent:(UIEvent *)event;
-(IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event;




@end

