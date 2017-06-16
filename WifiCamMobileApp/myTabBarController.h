//
//  myTabBarController.h
//  WCMapp2
//
//  Created by Tempo on 16/7/14.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ControlViewController.h"
#import "Reachability.h"

extern int Link_flag;
extern int Arm_status;
extern int TakeOff_status;
extern BOOL isArm;
#define NetWorkLinkNotifacation     @"NetWorkLinkNotifacation"
#define NetWorkUnlinkNotifacation   @"NetWorkUnlinkNotifacation"

@interface myTabBarController : UITabBarController<ControlViewControllerDelegate,UIAlertViewDelegate,UITabBarControllerDelegate>
@property (nonatomic, strong) Reachability *conn;

@end
