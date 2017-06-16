//
//  SecondViewController.m
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/8.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
////    return YES;
//}
//
//- (BOOL)shouldAutorotate
//{
//    return NO;
//}
//
//-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
//}
//
//-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self.tabBarController setSelectedIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)selectInterface:(id)sender {
    [self.tabBarController setSelectedIndex:0];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tabBarController setSelectedIndex:0];//跳转到第一个页面
//    NSLog(@"viewDidAppear second");
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.tabBarController setSelectedIndex:0];
//    NSLog(@"viewDidDisppear second");
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[NetWork getInstance]Stop_Video];
//    [[NetWork getInstance]free_node];
//    [[NetWork getInstance]Destory_H264Decoder];
    [self.tabBarController setSelectedIndex:0];
//    NSLog(@"viewWillAppear second");
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [[NetWork getInstance]Stop_Video];
//    [[NetWork getInstance]free_node];
//    [[NetWork getInstance]Destory_H264Decoder];
    [self.tabBarController setSelectedIndex:0];
//    NSLog(@"viewWillDisappear second");
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
