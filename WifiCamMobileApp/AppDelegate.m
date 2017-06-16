//
//  AppDelegate.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "AppDelegate.h"
#import "ExceptionHandler.h"
#import "ViewController.h"
#include "WifiCamSDKEventListener.h"
#import "WifiCamControl.h"
#import "Reachability+Ext.h"


#define DEBUG_ONLY 0

// Debug-Only
#if (DEBUG_ONLY == 1)
#include "ICatchWificamConfig.h"
#endif

@interface AppDelegate ()
@property(nonatomic) BOOL enableLog;
@property(nonatomic) FILE *appLogFile;
//@property (nonatomic) FILE *sdkLogFile;
@property(nonatomic) WifiCamObserver *globalObserver;
@property(strong, nonatomic) UIAlertView *reconnectionAlertView;
@property(strong, nonatomic) UIAlertView *connectionErrorAlertView;
@property(strong, nonatomic) UIAlertView *connectingAlertView;
@end


@implementation AppDelegate

-(void)copyDefaultSettingFileIfNeeded {
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Setting.plist"];
    //    NSLog(@"userSettingsFilePath = %@",userSettingsFilePath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:userSettingsFilePath] == NO) {
        //        NSLog(@"exit");
        NSString *settingsFilePath = [[NSBundle mainBundle] pathForResource:@"Setting" ofType:@"plist"];
        [fileManager copyItemAtPath:settingsFilePath toPath:userSettingsFilePath error:NULL];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self registerDefaultsFromSettingsBundle];
    NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
    self.enableLog = [defaultSettings boolForKey:@"PreferenceSpecifier:Log"];
    if (_enableLog) {
        [self startLogToFile];
    } else {
        [self cleanLogs];
    }
    AppLog(@"enabledLog: %d", self.enableLog);
    
    AppLog(@"%s", __func__);
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    
    
    
    self.connectionErrorAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                      message                                         :NSLocalizedString(@"NoWifiConnection", nil)
                      delegate                                        :self
                      cancelButtonTitle                               :NSLocalizedString(@"Sure", nil)
                      otherButtonTitles                               :nil, nil];
    _connectionErrorAlertView.tag = APP_CONNECT_ERROR_TAG;
    
    self.reconnectionAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                 message           :NSLocalizedString(@"TimeoutError", nil)
                                                 delegate          :self
                                                 cancelButtonTitle :NSLocalizedString(@"STREAM_RECONNECT", nil)
                                                 otherButtonTitles :nil, nil];
    _reconnectionAlertView.tag = APP_RECONNECT_ALERT_TAG;
    [self copyDefaultSettingFileIfNeeded];
    
    [self addGlobalObserver];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, doneand throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    AppLog(@"%s", __func__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    AppLog(@"%s", __func__);
    
    [self removeGlobalObserver];
    /*
     UIApplication  *app = [UIApplication sharedApplication];
     UILocalNotification *alarm = [[UILocalNotification alloc] init];
     if (alarm) {
     alarm.fireDate = [NSDate date];
     alarm.timeZone = [NSTimeZone defaultTimeZone];
     alarm.repeatInterval = 0;
     NSString *str = [NSString stringWithFormat:@"App enter background."];
     alarm.alertBody = str;
     alarm.soundName = UILocalNotificationDefaultSoundName;
     
     [app scheduleLocalNotification:alarm];
     }
     */
    
    if (![[SDK instance] isDownloading]) {
        if ([self.delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [self.delegate applicationDidEnterBackground:nil];
        } else {
            
            dispatch_sync([[SDK instance] sdkQueue], ^{
                //[[SDK instance] stopMediaStream];
                [[SDK instance] destroySDK];
            });
        }
        
        
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
        
        //if (_enableLog) {
        //  [self stopLog];
        //}
        [[SDK instance] cleanUpDownloadDirectory];
        
        //[self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
    } else {
        NSTimeInterval ti = 0;
        ti = [[UIApplication sharedApplication] backgroundTimeRemaining];
        NSLog(@"backgroundTimeRemaining: %f", ti); // just for debug
    }
    if (!_connectingAlertView.hidden) {
        [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_connectionErrorAlertView.hidden) {
        [_connectionErrorAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_reconnectionAlertView.hidden) {
        [_reconnectionAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    TRACE();
    
    [self addGlobalObserver];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    AppLog(@"%s", __func__);
#if (DEBUG_ONLY == 1)
    //  NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
    //  if (![defaultSettings integerForKey:@"PreviewCacheTime"]) {
    //    AppLog(@"loading default value...");
    //    [self performSelector:@selector(registerDefaultsFromSettingsBundle)];
    //  }
    
    /*
     NSInteger pct = [[NSUserDefaults standardUserDefaults] integerForKey:@"PreviewCacheTime"];
     AppLog(@"pct: %d", pct);
     ICatchWificamConfig *config = new ICatchWificamConfig();
     config->setPreviewCacheParam(pct);
     delete config; config = NULL;
     */
    
#endif
    if ([self.delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [self.delegate applicationDidBecomeActive:nil];
    }else
         [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    AppLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    if (_enableLog) {
        [self stopLog];
    }
    [[SDK instance] cleanUpDownloadDirectory];
    
}

#pragma mark - Log

- (void)startLogToFile
{
    // Get the document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Name the log folder & file
    NSDate *date = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSString *name = [dateformatter stringFromDate:date];
    NSString *appLogFileName = [NSString stringWithFormat:@"APP-%@.log", name];
    // Create the log folder
    NSString *logDirectory = [documentsDirectory stringByAppendingPathComponent:name];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    // Create(Open) the log file
    NSString *appLogFilePath = [logDirectory stringByAppendingPathComponent:appLogFileName];
    self.appLogFile = freopen([appLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    //NSString *sdkLogFileName = [NSString stringWithFormat:@"SDK-%@.log", [NSDate date]];
    //NSString *sdkLogFilePath = [documentsDirectory stringByAppendingPathComponent:sdkLogFileName];
    //self.sdkLogFile = freopen([sdkLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    
    // Log4SDK
    [[SDK instance] enableLogSdkAtDiretctory:logDirectory enable:YES];
    
    AppLog(@"%s", __func__);
}

- (void)stopLog
{
    AppLog(@"%s", __func__);
    fclose(_appLogFile);
    //fclose(_sdkLogFile);
}

- (void)cleanLogs
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
}

// retrieve the default setting values
- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case APP_RECONNECT_ALERT_TAG:
            if (buttonIndex == 0) {
                [self globalReconnect];
            } else if (buttonIndex == 1) {
                [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
            }
            
            break;
            
        case APP_CUSTOMER_ALERT_TAG:
            [[SDK instance] destroySDK];
            exit(0);
            break;
            
        default:
            break;
    }
}

#pragma mark - Observer
-(void)addGlobalObserver {
    AppLog(@"add disconnect & other event listener");
    WifiCamSDKEventListener *listener = new WifiCamSDKEventListener(self, @selector(notifyDisconnectionEvent));
    self.globalObserver = [[WifiCamObserver alloc] initWithListener:listener eventType:ICATCH_EVENT_CONNECTION_DISCONNECTED isCustomized:NO isGlobal:YES];
    [[SDK instance] addObserver:_globalObserver];
}

-(void)removeGlobalObserver {
    AppLog(@"remove disconnect & other event listener");
    [[SDK instance] removeObserver:_globalObserver];
    delete _globalObserver.listener;
    _globalObserver.listener = NULL;
    self.globalObserver = nil;
}

-(void)notifyDisconnectionEvent {
    AppLog(@"Disconnectino event was received.");
    if ([self.delegate respondsToSelector:@selector(notifyConnectionBroken)]) {
        [self.delegate notifyConnectionBroken];
    } else {
        [[SDK instance] destroySDK];
    }
    
    [self removeGlobalObserver];
    if (!_reconnectionAlertView.visible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_reconnectionAlertView show];
        });
    }
}

-(void)globalReconnect
{
    [self addGlobalObserver];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_connectingAlertView) {
            self.connectingAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                  message:NSLocalizedString(@"Connecting", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:nil
                                                        otherButtonTitles:nil, nil];
        }
        
        [_connectingAlertView show];
        dispatch_async([[SDK instance] sdkQueue], ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkDisconnectedNotification"
                                                                object:nil];
            [NSThread sleepForTimeInterval:1.0];
            
            int totalCheckCount = 60; // 60times : 30s
            while (totalCheckCount-- > 0) {
                if ([Reachability didConnectedToCameraHotspot]) {
                    if ([[SDK instance] initializeSDK]) {
                        [WifiCamControl scan];
                        
                        WifiCamManager *app = [WifiCamManager instance];
                        WifiCam *wifiCam = [app.wifiCams objectAtIndex:0];
                        wifiCam.camera = [WifiCamControl createOneCamera];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkConnectedNotification"
                                                                                object:nil];
                        });
                        break;
                    }
                }
                
                AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
                [NSThread sleepForTimeInterval:0.5];
            }
            
            if (totalCheckCount <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
                    [_reconnectionAlertView show];
                });
            }
            
        });
        
        
    });
}
@end
