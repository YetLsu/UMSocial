//
//  SetTableViewController.h
//  WCMapp2
//
//  Created by Tempo on 16/7/12.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
@interface SetTableViewController : UITableViewController

- (IBAction)backAction:(UIButton *)sender;


@property (weak, nonatomic) IBOutlet UISwitch *leftHand;
@property (weak, nonatomic) IBOutlet UISwitch *selfie;
@property (weak, nonatomic) IBOutlet UISwitch *throttleBack;
@property (weak, nonatomic) IBOutlet UISwitch *HDmodel;
@property (weak, nonatomic) IBOutlet UISlider *qhSlider;
@property (weak, nonatomic) IBOutlet UILabel *qhLabel;
@property (weak, nonatomic) IBOutlet UISlider *ztSlider;
@property (weak, nonatomic) IBOutlet UILabel *ztLabel;
@property (weak, nonatomic) IBOutlet UIButton *calibrationBut;
@property (weak, nonatomic) IBOutlet UIProgressView *calibrationProgress;
@property (weak, nonatomic) IBOutlet UILabel *calibrationLabel;


- (IBAction)CalibrationAction:(UIButton *)sender;
- (id)initWithSetting:(Settings *)settings;

@end
