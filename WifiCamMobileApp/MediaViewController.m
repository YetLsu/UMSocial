//
//  MediaViewController.m
//  WCMapp2
//
//  Created by Tempo on 16/7/16.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "MediaViewController.h"

#import "MBProgressHUD.h"

@implementation MediaViewController


- (void)viewDidLoad{

//    [self performSegueWithIdentifier:@"goMpbSegue" sender:nil];
    
}

- (void)viewWillAppear:(BOOL)animated{

    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请连接Wi-Fi" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
}

- (void)viewDidAppear:(BOOL)animated{

}

- (void)viewWillDisappear:(BOOL)animated{

}

- (void)viewDidDisappear:(BOOL)animated{

}

- (void)viewWillLayoutSubviews{

}

- (void)viewDidLayoutSubviews{

}



@end
