//
//  ControlViewController.h
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/4.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "Channel.h"
#import "SetTableViewController.h"
#import "SetViewController.h"
@class ControlViewController;

@protocol ControlViewControllerDelegate <NSObject>

-(void)controlViewControllerDismissed:(ControlViewController *)controller;

@end

@interface ControlViewController : UIViewController<SetViewControllerDelegate>
@property (nonatomic, weak)id<ControlViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *ImageViewBackground;

@property (weak, nonatomic) IBOutlet UIImageView *VideoImage1;
@property (weak, nonatomic) IBOutlet UIImageView *VideoImage2;

@property (weak, nonatomic) IBOutlet UIButton *btn_home;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *takeOff;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;


@property (weak, nonatomic) IBOutlet UIImageView *joystickLeftBackground;
@property (weak, nonatomic) IBOutlet UIImageView *joystickRightBackground;
@property (weak, nonatomic) IBOutlet UIImageView *joystickLeftPoint;
@property (weak, nonatomic) IBOutlet UIImageView *joystickRightPoint;
@property (weak, nonatomic) IBOutlet UIButton *joystickLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *joystickRightButton;


@property (weak, nonatomic) IBOutlet UILabel *con_rec_label;



- (IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event;

- (IBAction)joystickButtonDidTouchUp:(id)sender forEvent:(UIEvent *)event;

- (IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event;



-(IBAction)buttonClick:(id)sender;


@end
