//
//  SettingViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-11.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "SettingViewController.h"
#import "SettingDetailViewController.h"
#import "WifiCamAlertTable.h"
#import "MBProgressHUD.h"
#include "UtilsMacro.h"
#import "ViewController.h"

typedef NS_OPTIONS(NSUInteger, SettingSectionType) {
    SettingSectionTypeBasic = 0,
    SettingSectionTypeChangeSSID = 1,
    SettingSectionTypeAlertAction = 2,
    SettingSectionTypeTimelapse = 3,
};

@interface SettingViewController ()

@property(nonatomic) UIAlertView *formatAlertView;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) NSMutableArray  *mainMenuTable;
@property(nonatomic) NSMutableArray  *mainMenuShowTable;
@property(nonatomic) NSMutableArray  *mainMenuBasicSlideTable;
@property(nonatomic) NSMutableArray  *mainMenuChangeSSIDSlideTable;
@property(nonatomic) NSMutableArray  *mainMenuTimelapseSlideTable;
@property(nonatomic) NSMutableArray  *subMenuTable;
@property(nonatomic) NSInteger curSettingDetailType;
@property(nonatomic) NSInteger curSettingDetailItem;
@property(nonatomic) NSString *timelapseSectionTitle;

@end

@implementation SettingViewController

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    self.title = NSLocalizedString(@"SETTING", @"");
    
    // The whole
    self.mainMenuTable = [[NSMutableArray alloc] init];
    self.mainMenuShowTable = [[NSMutableArray alloc] init];
    self.mainMenuBasicSlideTable = [[NSMutableArray alloc] init];
    self.mainMenuChangeSSIDSlideTable = [[NSMutableArray alloc] init];
    self.mainMenuTimelapseSlideTable = [[NSMutableArray alloc] init];
    self.subMenuTable = [[NSMutableArray alloc] init];
    
    
    NSDictionary *actionTable = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_FORMAT", @"")};
    [_mainMenuShowTable addObject:actionTable];
    
    
    //[_mainMenuTable addObject:_mainMenuBasicSlideTable];
    [_mainMenuTable insertObject:_mainMenuBasicSlideTable atIndex:SettingSectionTypeBasic];
    [_mainMenuTable insertObject:_mainMenuChangeSSIDSlideTable atIndex:SettingSectionTypeChangeSSID];
    [_mainMenuTable insertObject:_mainMenuShowTable atIndex:SettingSectionTypeAlertAction];
    if (_camera.previewMode == WifiCamPreviewModeTimelapseOff
        && [self capableOf:WifiCamAbilityTimeLapse]) {
        [_mainMenuTable insertObject:_mainMenuTimelapseSlideTable atIndex:SettingSectionTypeTimelapse];
    }
    
    self.formatAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SETTING_FORMAT_CONFIRM", @"")
                                                      message:NSLocalizedString(@"SETTING_FORMAT_DESC", @"")
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            otherButtonTitles:NSLocalizedString(@"Sure", @""), nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
//    hud.labelText = NSLocalizedString(@"LOAD_SETTING_DATA", nil);
//    hud.minSize = CGSizeMake(120, 120);
//    hud.dimBackground = YES;
//    
//
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = NSLocalizedString(@"LOAD_SETTING_DATA", nil);
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self fillMainMenuBasicSlideTable];
        [self fillMainMenuChangeSSIDSlideTable];
        [self fillMainMenuTimelapseSlideTable];
        
        [NSThread sleepForTimeInterval:0.5]; //
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timelapseSectionTitle = NSLocalizedString(@"SETTING_TIMELAPSE", nil);
            [self.tableView reloadData];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!_formatAlertView.hidden) {
        [_formatAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)recoverFromDisconnection
{
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    
    [self.tableView reloadData];
}

#pragma mark - Fill menu

- (BOOL)capableOf:(WifiCamAbility)ability
{
    return (_camera.ability & ability) == ability ? YES : NO;
}

- (void)fillMainMenuBasicSlideTable
{
    NSDictionary *table = nil;
    [_mainMenuBasicSlideTable removeAllObjects];
    
    if ([self capableOf:WifiCamAbilityWhiteBalance]) {
        table = [self fillWhiteBalanceTable];
        [_mainMenuBasicSlideTable addObject:table];
    }
    
    if ([self capableOf:WifiCamAbilityLightFrequency]) {
        table = [self fillLightFrequencyTable];
        [_mainMenuBasicSlideTable addObject:table];
    }
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOff) {
        if ([self capableOf:WifiCamAbilityBurstNumber]) {
            table = [self fillBurstNumberTable];
            [_mainMenuBasicSlideTable addObject:table];
        }
    }
    
    //if (_camera.previewMode == WifiCamPreviewModeCameraOff
    //    || _camera.previewMode == WifiCamPreviewModeVideoOff) {
    if ([self capableOf:WifiCamAbilityDateStamp]) {
        table = [self fillDateStampTable];
        [_mainMenuBasicSlideTable addObject:table];
    }
    //}
    
    if ([self capableOf:WifiCamAbilityUpsideDown]) {
        table = [self fillUpsideDownTable];
        [_mainMenuBasicSlideTable addObject:table];
    }
    
    if ([self capableOf:WifiCamAbilitySlowMotion]
        && _camera.previewMode == WifiCamPreviewModeVideoOff) {
        table = [self fillSlowMotionTable];
        [_mainMenuBasicSlideTable addObject:table];
    }
    
    table = [self fillAboutTable];
    [_mainMenuBasicSlideTable addObject:table];
}

- (void)fillMainMenuChangeSSIDSlideTable
{
    if ([self capableOf:WifiCamAbilityChangeSSID]
        || [self capableOf:WifiCamAbilityChangePwd]) {
        NSDictionary *table = @{@(SettingTableTextLabel): @"Change SSID"};
        [_mainMenuChangeSSIDSlideTable removeAllObjects];
        [_mainMenuChangeSSIDSlideTable addObject:table];
    }
}

- (void)fillMainMenuTimelapseSlideTable
{
    if (_camera.previewMode == WifiCamPreviewModeTimelapseOff
        && [self capableOf:WifiCamAbilityTimeLapse]) {
        NSDictionary *table = nil;
        [_mainMenuTimelapseSlideTable removeAllObjects];
        
        table = [self fillTimeLapseTypeTable];
        [_mainMenuTimelapseSlideTable addObject:table];
        table = [self fillTimeLapseIntervalTable];
        [_mainMenuTimelapseSlideTable addObject:table];
        table = [self fillTimeLapseDurationTable];
        [_mainMenuTimelapseSlideTable addObject:table];
    }
}

- (NSDictionary *)fillLightFrequencyTable
{
    WifiCamAlertTable *pfArray = [_ctrl.propCtrl prepareDataForLightFrequency:_camera.curLightFrequency];
    NSDictionary *powerFrequencyTable = [[WifiCamStaticData instance] powerFrequencyDict];
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_POWER_SUPPLY", @""),
                            @(SettingTableDetailTextLabel): [powerFrequencyTable objectForKey:@(_camera.curLightFrequency)],
                            @(SettingTableDetailType): @(SettingDetailTypePowerFrequency),
                            @(SettingTableDetailData): pfArray.array,
                            @(SettingTableDetailLastItem): @(pfArray.lastIndex)};
    return table;
}

- (NSDictionary *)fillWhiteBalanceTable
{
    WifiCamAlertTable *awbArray = [_ctrl.propCtrl prepareDataForWhiteBalance:_camera.curWhiteBalance];
    NSDictionary *whiteBalanceTable = [[WifiCamStaticData instance] whiteBalanceDict];
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_AWB", @""),
                            @(SettingTableDetailTextLabel): [whiteBalanceTable objectForKey:@(_camera.curWhiteBalance)],
                            @(SettingTableDetailType): @(SettingDetailTypeWhiteBalance),
                            @(SettingTableDetailData): awbArray.array,
                            @(SettingTableDetailLastItem): @(awbArray.lastIndex)};
    return table;
}

- (NSDictionary *)fillBurstNumberTable
{
    WifiCamAlertTable *bnArray = [_ctrl.propCtrl prepareDataForBurstNumber:_camera.curBurstNumber];
    NSDictionary *burstNumberStringTable = [[WifiCamStaticData instance] burstNumberStringDict];
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_BURST", @""),
                            @(SettingTableDetailTextLabel): [[burstNumberStringTable objectForKey:@(_camera.curBurstNumber)] firstObject],
                            @(SettingTableDetailType): @(SettingDetailTypeBurstNumber),
                            @(SettingTableDetailData): bnArray.array,
                            @(SettingTableDetailLastItem): @(bnArray.lastIndex)};
    return table;
}

- (NSDictionary *)fillDateStampTable
{
    WifiCamAlertTable *dsArray = [_ctrl.propCtrl prepareDataForDateStamp:_camera.curDateStamp];
    NSDictionary *dateStampTable = [[WifiCamStaticData instance] dateStampDict];
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_DATESTAMP", @""),
                            @(SettingTableDetailTextLabel): [dateStampTable objectForKey:@(_camera.curDateStamp)],
                            @(SettingTableDetailType): @(SettingDetailTypeDateStamp),
                            @(SettingTableDetailData): dsArray.array,
                            @(SettingTableDetailLastItem): @(dsArray.lastIndex)};
    return table;
}

- (NSDictionary *)fillSSIDPwdTable
{
    
    return nil;
}

- (NSDictionary *)fillTimeLapseTypeTable
{
    NSString *curTimelapseTypeStr = nil;
    WifiCamAlertTable *t = [[WifiCamAlertTable alloc] init];
    t.array = [NSMutableArray arrayWithObjects:NSLocalizedString(@"SETTING_TIMELAPSE_TYPE_STILL", nil),
               NSLocalizedString(@"SETTING_TIMELAPSE_TYPE_VIDEO", nil), nil];
    if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
        t.lastIndex = 1;
    } else {
        t.lastIndex = 0;
    }
    curTimelapseTypeStr = [t.array objectAtIndex:t.lastIndex];
    
    return @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_TIMELAPSE_TYPE", @""),
             @(SettingTableDetailTextLabel): curTimelapseTypeStr,
             @(SettingTableDetailType): @(SettingDetailTypeTimelapseType),
             @(SettingTableDetailData): t.array,
             @(SettingTableDetailLastItem): @(t.lastIndex)};
}

- (NSDictionary *)fillTimeLapseIntervalTable
{
    WifiCamAlertTable *vtiArray = [_ctrl.propCtrl prepareDataForTimelapseInterval:_camera.curTimelapseInterval];
    //  NSDictionary *timeLapseTable = [[WifiCamStaticData instance] timelapseIntervalDict];
    NSString *tableCellDetailText = @"";
    if (vtiArray.lastIndex != UNDEFINED_NUM) {
        //    tableCellDetailText = [timeLapseTable objectForKey:@(_camera.curTimelapseInterval)];
        if (0 == _camera.curTimelapseInterval) {
            tableCellDetailText = NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_OFF", nil);
        } else {
            //      tableCellDetailText = [NSString stringWithFormat:@"%ds", _camera.curTimelapseInterval];
            tableCellDetailText = [vtiArray.array objectAtIndex:vtiArray.lastIndex];
        }
    }
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_CAP_TIMESCAPE_INTERVAL", @""),
                            @(SettingTableDetailTextLabel): tableCellDetailText,
                            @(SettingTableDetailType): @(SettingDetailTypeTimelapseInterval),
                            @(SettingTableDetailData): vtiArray.array,
                            @(SettingTableDetailLastItem): @(vtiArray.lastIndex)};
    return table;
}

- (NSDictionary *)fillTimeLapseDurationTable
{
    WifiCamAlertTable *vtdArray = [_ctrl.propCtrl prepareDataForTimelapseDuration:_camera.curTimelapseDuration];
    //  NSDictionary *timeLapseTable = [[WifiCamStaticData instance] timelapseDurationDict];
    NSString *tableCellDetailText = @"";
    if (vtdArray.lastIndex != UNDEFINED_NUM) {
        //    tableCellDetailText = [timeLapseTable objectForKey:@(_camera.curTimelapseDuration)];
        if (0xFFFF == _camera.curTimelapseDuration) {
            tableCellDetailText = NSLocalizedString(@"SETTING_CAP_TL_DURATION_Unlimited", nil);
        } else {
            //      tableCellDetailText = [NSString stringWithFormat:@"%dm", _camera.curTimelapseDuration];
            tableCellDetailText = [vtdArray.array objectAtIndex:vtdArray.lastIndex];
        }
    }
    
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_CAP_TIMESCAPE_LIMIT", @""),
                            @(SettingTableDetailTextLabel): tableCellDetailText,
                            @(SettingTableDetailType): @(SetttngDetailTypeTimelapseDuration),
                            @(SettingTableDetailData): vtdArray.array,
                            @(SettingTableDetailLastItem): @(vtdArray.lastIndex)};
    return table;
}


- (NSDictionary *)fillUpsideDownTable
{
    WifiCamAlertTable *upsideDownTable = [[WifiCamAlertTable alloc] init];
    upsideDownTable.array = [[NSMutableArray alloc] initWithObjects:NSLocalizedString(@"SETTING_OFF", nil), NSLocalizedString(@"SETTING_ON", nil), nil];
    
    uint curUpsideDown = _camera.curInvertMode;//[_ctrl.propCtrl retrieveCurrentUpsideDown];
    if (0 == curUpsideDown) {
        upsideDownTable.lastIndex = 0;
    } else {
        upsideDownTable.lastIndex = 1;
    }
    
    NSDictionary *upsideDownDict = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_UPSIDE_DOWN", @""),
                                     @(SettingTableDetailTextLabel): [upsideDownTable.array objectAtIndex:upsideDownTable.lastIndex],
                                     @(SettingTableDetailType): @(SettingDetailTypeUpsideDown),
                                     @(SettingTableDetailData): upsideDownTable.array,
                                     @(SettingTableDetailLastItem): @(upsideDownTable.lastIndex)};
    
    return upsideDownDict;
}

- (NSDictionary *)fillSlowMotionTable
{
    WifiCamAlertTable *slowMotionTable = [[WifiCamAlertTable alloc] init];
    slowMotionTable.array = [[NSMutableArray alloc] initWithObjects:NSLocalizedString(@"SETTING_OFF", nil), NSLocalizedString(@"SETTING_ON", nil), nil];
    
    uint curSlowMotion = _camera.curSlowMotion;//[_ctrl.propCtrl retrieveCurrentSlowMotion];
    if (0 == curSlowMotion) {
        slowMotionTable.lastIndex = 0;
    } else {
        slowMotionTable.lastIndex = 1;
    }
    
    NSDictionary *upsideDownDict = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_SLOW_MOTION", @""),
                                     @(SettingTableDetailTextLabel): [slowMotionTable.array objectAtIndex:slowMotionTable.lastIndex],
                                     @(SettingTableDetailType): @(SettingDetailTypeSlowMotion),
                                     @(SettingTableDetailData): slowMotionTable.array,
                                     @(SettingTableDetailLastItem): @(slowMotionTable.lastIndex)};
    
    return upsideDownDict;
}

- (NSDictionary *)fillAboutTable
{
    NSMutableArray  *aboutArray = [[NSMutableArray alloc] init];
    NSString *appVersion = NSLocalizedString(@"SETTING_APP_VERSION", nil);
    appVersion = [appVersion stringByReplacingOccurrencesOfString:@"%@"
                                                       withString:APP_VERSION];
    [aboutArray addObject:appVersion];
    if ([self capableOf:WifiCamAbilityFWVersion]) {
        NSString *fwVersion = NSLocalizedString(@"SETTING_FIRMWARE_VERSION", nil);
        fwVersion = [fwVersion stringByReplacingOccurrencesOfString:@"%@" withString:_camera.cameraFWVersion];
        [aboutArray addObject:fwVersion];
    }
    if ([self capableOf:WifiCamAbilityProductName]) {
        NSString *productName = NSLocalizedString(@"SETTING_PRODUCT_NAME", nil);
        productName = [productName stringByReplacingOccurrencesOfString:@"%@" withString:_camera.cameraProductName];
        [aboutArray addObject:productName];
    }
    
    NSDictionary *table = @{@(SettingTableTextLabel): NSLocalizedString(@"SETTING_ABOUT", @""),
                            @(SettingTableDetailType): @(SettingDetailTypeAbout),
                            @(SettingTableDetailData): aboutArray};
    
    
    return table;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_mainMenuTable count];
}

- (NSInteger) tableView             :(UITableView *)tableView
              numberOfRowsInSection :(NSInteger)section
{
    return [[_mainMenuTable objectAtIndex:section] count];
}

- (UITableViewCell *) tableView             :(UITableView *)tableView
                      cellForRowAtIndexPath :(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"settingCell";
    static NSString *CellIdentifier2 = @"settingCell2";
    static NSString *CellIdentifier3 = @"settingCell3";
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SettingSectionTypeAlertAction) {
        // Format
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2 forIndexPath:indexPath];
        [cell.textLabel setTextColor:[UIColor blueColor]];
    } else if (indexPath.section == SettingSectionTypeBasic || indexPath.section == SettingSectionTypeTimelapse){
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else if (indexPath.section == SettingSectionTypeChangeSSID) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3 forIndexPath:indexPath];
    }
    
    //  AppLog(@"section:%d, row:%d", indexPath.section, indexPath.row);
    NSDictionary *dict = [[_mainMenuTable objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSAssert1([dict isKindOfClass:[NSDictionary class]], @"Object dict isn't an NSDictionary", nil);
    cell.textLabel.text = [dict objectForKey:@(SettingTableTextLabel)];
    cell.detailTextLabel.text = [dict objectForKey:@(SettingTableDetailTextLabel)];
    
    return cell;
}

- (NSString *)tableView               :(UITableView *)tableView
              titleForHeaderInSection :(NSInteger)section
{
    NSString *retVal = nil;
    
    switch (section) {
        case SettingSectionTypeBasic:
            retVal = NSLocalizedString(@"SETTING", nil);
            break;
            
        case SettingSectionTypeAlertAction:
            //      retVal = NSLocalizedString(@"SD Card", nil);
            break;
            
        case SettingSectionTypeTimelapse:
            retVal = _timelapseSectionTitle;
            break;
            
        default:
            break;
    }
    
    return retVal;
}

#pragma mark - Table view delegate

- (void)tableView               :(UITableView *)tableView
        didSelectRowAtIndexPath :(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SettingSectionTypeAlertAction) {
        // Format
        if (indexPath.row == 0) {
            [_formatAlertView setTag:0];
            [_formatAlertView show];
            
        }
    } else if (indexPath.section == SettingSectionTypeChangeSSID) {
        
        //[self performSegueWithIdentifier:@"changeSSID" sender:self];
    }
}

- (NSIndexPath *) tableView               :(UITableView *)tableView
                  willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section != SettingSectionTypeAlertAction) {
        NSDictionary *dict = [[_mainMenuTable objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [_subMenuTable setArray:[dict objectForKey:@(SettingTableDetailData)]];
        _curSettingDetailType = [[dict objectForKey:@(SettingTableDetailType)] integerValue];
        _curSettingDetailItem = [[dict objectForKey:@(SettingTableDetailLastItem)] integerValue];
        
    }
    
    return indexPath;
    
}

#pragma mark - UIAlertView delegate
- (void)alertView           :(UIAlertView *)alertView
        clickedButtonAtIndex:(NSInteger)buttonIndex
{
    __block BOOL formatOK = NO;
    if ((buttonIndex == 1) && (alertView.tag == 0)) {
        if (![_ctrl.propCtrl checkSDExist]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                 message           :NSLocalizedString(@"CARD_ERROR", nil)
                                                 delegate          :self
                                                 cancelButtonTitle :NSLocalizedString(@"Sure", nil)
                                                 otherButtonTitles :nil, nil];
            [alert show];
            return;
        }
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        hud.labelText = NSLocalizedString(@"SETTING_FORMATTING", nil);
        hud.minSize = CGSizeMake(120, 120);
        hud.dimBackground = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            formatOK = [_ctrl.actCtrl formatSD];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.mode = MBProgressHUDModeText;
                if (formatOK) {
                    hud.labelText = NSLocalizedString(@"SETTING_FORMAT_FINISH", nil);
                } else {
                    hud.labelText = NSLocalizedString(@"SETTING_FORMAT_FAILED", nil);
                }
                
                [MBProgressHUD hideHUDForView:self.view.window animated:YES];
            });
            
        });
    }
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewControlleVidr].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        SettingDetailViewController *detail = [segue destinationViewController];
        
        detail.subMenuTable = _subMenuTable;
        detail.curSettingDetailType = _curSettingDetailType;
        detail.curSettingDetailItem = _curSettingDetailItem;
    }
    
    
}

- (IBAction)goHome:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        AppLog(@"Setting -- QUIT");
    }];
}

@end
