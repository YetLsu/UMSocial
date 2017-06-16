//
//  SetViewController.m
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/10.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "SetViewController.h"

@interface SetViewController ()

@end

@implementation SetViewController
@synthesize delegate;

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
//
//-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)back:(id)sender {
    [self.delegate setViewControllerDismissed:self];
//    [self.navigationController popViewControllerAnimated:YES];
//    UIStoryboard *mainstory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    [mainstory instantiateViewControllerWithIdentifier:@"ControlViewController"];

}

@end
