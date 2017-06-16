//
//  SetViewController.h
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/10.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SetViewController;

@protocol SetViewControllerDelegate <NSObject>

-(void)setViewControllerDismissed:(SetViewController *)controller;

@end

@interface SetViewController : UIViewController
@property (nonatomic, weak)id<SetViewControllerDelegate> delegate;

- (IBAction)back:(id)sender;

@end
