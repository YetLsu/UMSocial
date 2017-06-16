//
//  AppDelegate.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

@protocol AppDelegateProtocol <NSObject>
@optional
-(void)applicationDidEnterBackground:(UIApplication *)application NS_AVAILABLE_IOS(4_0);
-(void)applicationDidBecomeActive:(UIApplication *)application NS_AVAILABLE_IOS(4_0);
-(void)notifyPropertiesReady;
-(void)notifyConnectionBroken;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) IBOutlet id<AppDelegateProtocol> delegate;

@end