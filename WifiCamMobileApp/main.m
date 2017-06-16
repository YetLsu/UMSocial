//
//  main.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "ExceptionHandler.h"

int main(int argc, char * argv[])
{
    InstallUncaughtExceptionHandler();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
