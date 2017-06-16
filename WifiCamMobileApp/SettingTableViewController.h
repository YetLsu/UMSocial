//
//  SettingTableViewController.h
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/10.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
@class SettingTableViewController;

@protocol SettingTableViewControllerDelegate <NSObject>

-(void)settingTableViewController:(SettingTableViewController *)controller leftHandedValueDidChange:(BOOL)enabled;
-(void)settingTableViewController:(SettingTableViewController *)controller beginnerModeValueDidChange:(BOOL)enabled;

@end

enum SwitchButtonStatus{
    SWITCH_BUTTON_UNCHECKED = 0,
    SWITCH_BUTTON_CHECKED,
};

@interface SettingTableViewController : UITableViewController
@property(nonatomic, weak)id<SettingTableViewControllerDelegate> delegate;

-(id)initWithSetting:(Settings *)settings;



@end
