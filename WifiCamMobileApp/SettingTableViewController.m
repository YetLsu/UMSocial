//
//  SettingTableViewController.m
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/10.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "SettingTableViewController.h"
//#import "RESideMenu.h"
//#import "SettingsSwitchCell.h"
//#import "SensitivityTableViewCell.h"
@interface SettingTableViewController () {
    Settings *_settings;
}

@end

@implementation SettingTableViewController

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
////    return YES;
//}

//- (BOOL)shouldAutorotate
//{
//    return NO;
//}
//
//-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
//}

//-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
//}

-(id)initWithSetting:(Settings *)settings {
    self = [super init];
    if (self) {
        _settings = settings;
    }
    return self;
}

//- (IBAction)showMenu:(id)sender {
//    [self.sideMenuViewController presentLeftMenuViewController];
//}

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)updateSettingsUI {
    
}

-(void)setswitchButton:(UIButton *)switchButton withValue:(BOOL)active {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"SettingTableView");
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    NSLog(@"userSettingsFilePath = %@",userSettingsFilePath);
    _settings = [[Settings alloc]initWithSettingsFile:userSettingsFilePath];
    NSLog(@"lefthandle = %d",_settings.isBeginnerMode);
    NSLog(@"xxx = %f",_settings.rudderDeadBand);
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
    }
    [_settings save];
}

-(void)updateSliderValueIndicator:(id)sender {
    UISlider *slider = (UISlider *)sender;
    switch (slider.tag) {
        case 103:
            [_settings setRollPitchScale:slider.value];
            break;
            
        case 104:
            [_settings setYawScale:slider.value];
            break;
    }
    [_settings save];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
    // Return the number of rows in the section.
    NSInteger rows;
    switch (section) {
        case 0:
            rows = 3;
            break;
        case 1:
            rows = 1;
            break;
        case 2:
            rows = 1;
            break;
        default:
            rows = 0;
            break;
    }
    return rows;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Basic";
            break;
        case 1:
            title = @"RollPitchScale";
            break;
        case 2:
            title = @"YawScale";
            break;
    }
    return title;
}

@end
