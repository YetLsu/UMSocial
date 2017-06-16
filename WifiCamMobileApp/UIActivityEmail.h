//
//  UIActivityEmail.h
//  WifiCamMobileApp
//
//  Created by Guo on 6/9/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityWrapper.h"

@interface UIActivityEmail : UIActivity
@property(nonatomic, weak) id<ActivityWrapperDelegate> delegate;
- (id)initWithDelegate:(id <ActivityWrapperDelegate>)delegate;
@end
