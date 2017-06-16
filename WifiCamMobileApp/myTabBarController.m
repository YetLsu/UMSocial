//
//  myTabBarController.m
//  WCMapp2
//
//  Created by Tempo on 16/7/14.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "myTabBarController.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#include "MMProgressHUD.h"
#define KWifiName @"ALPHA-X1_000" //Wi-Fi名字
int Link_flag;//连接上为1,没有连接上为0
int Arm_status;//解锁状态
int TakeOff_status;//一键起飞状态
BOOL isArm;

@interface myTabBarController (){
    NSTimer *myTimer;
    NSTimer *checkELF;//检测是否连接上ELF_VRDrone wifi定时器
    
}

@property(nonatomic, retain) Settings *setting;

@end

@implementation myTabBarController

@synthesize setting = _setting;

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
//    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)awakeFromNib {
    NSString *documentsDir= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    _setting = [[Settings alloc] initWithSettingsFile:userSettingsFilePath];
    NSLog(@"xxxxxxxxx");
}

- (void)viewDidLoad{

    [super viewDidLoad];
//    self.tabBar.selectedImageTintColor = [UIColor whiteColor];

    self.delegate = self;//禁止在解锁的时候跳转
    [self.navigationController setNavigationBarHidden:YES];//隐藏NavigationBar
    //    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    self.tabBar.tintColor = [UIColor colorWithRed:57/255.0 green:214/255.0 blue:199/255.0 alpha:1];//设置TabBar图标的颜色
    Link_flag = 0;//没有连接上Wi-Fi
    Arm_status = 0;//没有解锁
    TakeOff_status = 0;//没有一键起飞、降落
    NSLog(@"WifiSSID = %@",[self currentWifiSSID]);
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    self.conn = [Reachability reachabilityForLocalWiFi];
    [self.conn startNotifier];
    if ([[self currentWifiSSID]isEqualToString:KWifiName]) {
        
        NSLog(@"Wi-Fi正确");
        
    }else {
        //        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
        //        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Wifi未连接" message:@"请进入系统［设置］>［Wi-Fi]中打开wifi并连接ELF VRDrone" delegate:self cancelButtonTitle:@"取消"otherButtonTitles:@"设置", nil];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"LINK", nil) message:NSLocalizedString(@"CONTENT", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)otherButtonTitles:NSLocalizedString(@"SET", nil), nil];
        alert.tag = 450;
        [alert show];
        
        [checkELF invalidate];
        checkELF = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(checkELFWifi) userInfo:nil repeats:YES];
        
    }
    //    NetWork *network = [NetWork getInstance];
    //    if ([network is_Connect]) {
    ////        NSLog(@"start here");
    //        [network Login_Req];
    //        [network Verify_Req];
    //        myTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(keep_live) userInfo:Nil repeats:YES];
    //    }
    [self.tabBarController.tabBarItem setEnabled:YES];
    //    [self.tabBar setItems:self.tabBar.items animated:NO];
    [self.tabBarController.tabBar setItems:self.tabBar.items animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //    if (buttonIndex == 1 && alertView.tag == 450) {
    //        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://www.elecfreaks.com"]];
    //    }
    if(buttonIndex == 1) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSString *)currentWifiSSID {
    NSString *ssid = nil;
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    for (NSString *ifname in ifs) {
        NSDictionary *info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}

-(void)networkStateChange {
    [self checkNetworkState];
}

-(void)checkNetworkState {
    //check wifi state
    Reachability *wifi = [Reachability reachabilityForLocalWiFi];
    
    if ([wifi currentReachabilityStatus] != NotReachable) {
        if ([[self currentWifiSSID]isEqualToString:KWifiName]) {

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"wifi Connect successfully";
            hud.margin = 10.f;
            hud.yOffset = 150.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:1];
            NSLog(@"wifi Connect successfully");

        }else {

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"wifi 不正确";
            hud.margin = 10.f;
            hud.yOffset = 150.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:1];
            NSLog(@"wifi 不正确");
        }
        
    }else {
        

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"wifi 关闭";
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
        NSLog(@"wifi 关闭");
        
        //[self sendNetWorkunLinkNotification];
        Link_flag = 0;
        //        [NetWork DestoryNetWork];
        [myTimer invalidate];
        myTimer = nil;
    }
}

- (void)checkELFWifi {
    if ([[self currentWifiSSID]isEqualToString:@"ELF VRDrone"]) {
        NSLog(@"check ELF_VRDrone...");
        if (checkELF.isValid) {
            [checkELF invalidate];
//            NetWork *network = [NetWork getInstance];
            //            if ([network is_Connect]) {
            Link_flag = 1;
            //            NSLog(@"start here");
//            [network Login_Req];
//            [network Verify_Req];
            if (_setting.isHDMode) {
//                [network Camera_paramsSetReq:0 VALUE:64];//hd
                //                NSLog(@"hdxxxx");
            }else{
//                [network Camera_paramsSetReq:0 VALUE:32];//vga
                //                NSLog(@"vgaxxxx");
            }
            //            [network Camera_paramsSetReq:0 VALUE:32];
//            myTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(keep_live) userInfo:Nil repeats:YES];
            [self sendNetWorkLinkNotification];
            NSLog(@"Video finish....");
            //            }
        }
        checkELF = nil;
    }else{
        NSLog(@"check %@",[self currentWifiSSID]);
        
    }
    
}

- (void)sendNetWorkLinkNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:NetWorkLinkNotifacation object:self userInfo:nil];
}
- (void)sendNetWorkunLinkNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:NetWorkUnlinkNotifacation object:self userInfo:nil];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ControllerModuleSegue"]) {
        //        NSLog(@"ControllerModuleSegue");
        ControlViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    //    static int flag = 0;
    if (item == [self.tabBar.items objectAtIndex:0]) {
        //        NSLog(@"item0");
        //flag = 1;
    }
    if (item == [self.tabBar.items objectAtIndex:1]) {
        //        NSLog(@"item1");
        //        if (flag == 0) {
        [self.tabBarController setSelectedIndex:0];
        if (Arm_status == 0) { //上锁时跳转
            [self performSegueWithIdentifier:@"ControllerModuleSegue" sender:self];
        }
        
        
        //        }else {
        //            //flag = 0;0000000000.....
        //        }
    }
    if (item == [self.tabBar.items objectAtIndex:2]) {
        //        NSLog(@"item2");
        //flag = 1;
    }
}


//-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
//
//}00000

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    //    NSLog(@"yyyyydjlfakjdlfajdlfjl");
    if (Arm_status) { //解锁时不能跳转
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"请上锁";
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
        NSLog(@"解锁时不能跳转");
        return NO;
    }
    else {//上锁时才能跳转
        return YES;
    }
    //    return YES;
}



#pragma mark --controlViewControllerDelegate
-(void)controlViewControllerDismissed:(ControlViewController *)controller {
    NSLog(@"tabBar....");
    [controller dismissViewControllerAnimated:YES completion:nil];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */



@end
