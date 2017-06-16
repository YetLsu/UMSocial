//
//  ChangeSSIDViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 11/10/14.
//  Copyright (c) 2014 iCatchTech. All rights reserved.
//

#import "ChangeSSIDViewController.h"

@interface ChangeSSIDViewController ()
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) MBProgressHUD *progressHUD;

@property(nonatomic) NSString *tempSSID;
@property(nonatomic) NSString *tempPassword;
@end

@implementation ChangeSSIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  WifiCamManager *app = [WifiCamManager instance];
  self.wifiCam = [app.wifiCams objectAtIndex:0];
  self.camera = _wifiCam.camera;
  self.ctrl = _wifiCam.controler;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)recoverFromDisconnection
{
  [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
}


-(BOOL)isValidPassword:(NSString *)password
{
  BOOL result = NO;
  
  NSScanner *sc = [NSScanner scannerWithString:password];
  if ([sc scanInt:NULL]) {
    result = [sc isAtEnd];
  }
  
  return result;
}

- (IBAction)save:(id)sender {
  
  // check null
  // check length
  
  [self showProgressHUDWithMessage:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    BOOL error = NO;
    NSString * errorMessage = nil;
    
    
    do {
      if (_tempSSID) {
        if (_tempSSID.length < 1 || _tempSSID.length > 20) {
          error = YES;
          errorMessage = @"Incorrect SSID (<20 characters)";
          break;
        } else {
          _camera.ssid = _tempSSID;
          BOOL ret = [_ctrl.propCtrl changeSSID:_camera.ssid];
          if (!ret) {
            error = YES;
            errorMessage = @"Change SSID Failed.";
            break;
          }
        }
      } else {
        error = YES;
        errorMessage = @"SSID isn't changed.";
        break;
      }
      
      if (_tempPassword) {
        if (_tempPassword.length < 8 || _tempPassword.length > 10 || ![self isValidPassword:_tempPassword]) {
          error = YES;
          errorMessage = @"Invalid Password (8~10 numeric characters)";
          break;
        } else {
          _camera.password = _tempPassword;
          BOOL ret = [_ctrl.propCtrl changePassword:_camera.password];
          if (!ret) {
            error = YES;
            errorMessage = @"Change Password Failed.";
            break;
          }
        }
      } else {
        error = YES;
        errorMessage = @"Password isn't changed.";
        break;
      }
      
    } while (0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) {
        [self showProgressHUDNotice:errorMessage showTime:3.0];
      } else {
        [self showProgressHUDCompleteMessage:@"Success."];
        //[self.navigationController popToRootViewControllerAnimated:YES];
      }
    
    });
  
  });

}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
  if (!_progressHUD) {
    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
    _progressHUD.minSize = CGSizeMake(120, 120);
    _progressHUD.minShowTime = 1;
    _progressHUD.dimBackground = YES;
    // The sample image is based on the
    // work by: http://www.pixelpressicons.com
    // licence: http://creativecommons.org/licenses/by/2.5/ca/
    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
    [self.view.window addSubview:_progressHUD];
  }
  return _progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time {
  TRACE();
  if (message) {
    [self.progressHUD show:YES];
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeText;
    [self.progressHUD hide:YES afterDelay:time];
  } else {
    [self.progressHUD hide:YES];
  }
}

- (void)showProgressHUDWithMessage:(NSString *)message {
  TRACE();
  self.progressHUD.labelText = message;
  self.progressHUD.mode = MBProgressHUDModeIndeterminate;
  [self.progressHUD show:YES];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
  TRACE();
  if (message) {
    [self.progressHUD show:YES];
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = nil;
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    [self.progressHUD hide:YES afterDelay:1.0];
  } else {
    [self.progressHUD hide:YES];
  }
}

- (void)hideProgressHUD:(BOOL)animated {
  TRACE();
  [self.progressHUD hide:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  //#warning Potentially incomplete method implementation.
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  //#warning Incomplete method implementation.
  // Return the number of rows in the section.
  return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ssid" forIndexPath:indexPath];
  
  cell.tag = indexPath.row;
  AppLog(@"tag: %ld", cell.tag);
  
  CGRect textFieldRect;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // iPad
    textFieldRect = CGRectMake(0.0, 0.0f, 615.0f, 30.0f);
  } else {
    // iPhone
    textFieldRect = CGRectMake(0.0, 0.0f, 195.0f, 30.0f);
  }
  
  UITextField *theTextField = [[UITextField alloc] initWithFrame:textFieldRect];
  theTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  theTextField.returnKeyType = UIReturnKeyDone;
  theTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
  theTextField.tag = indexPath.row;
  theTextField.delegate = self;
  
  //此方法为关键方法
  [theTextField addTarget:self action:@selector(textFieldWithText:) forControlEvents:UIControlEventEditingChanged];
  
  switch (indexPath.row) {
    case 0:
      cell.textLabel.text = @"SSID";
      theTextField.text = _camera.ssid;
      
      [theTextField becomeFirstResponder];
      break;
    case 1:
      cell.textLabel.text = @"Password";
      theTextField.text = _camera.password;
      theTextField.secureTextEntry = YES;
      break;
      
    default:
      break;
  }
  
  cell.accessoryView = theTextField;
  
  return cell;
}

#pragma mark - UITextField delegate
// Dismiss keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

-(void)textFieldWithText:(UITextField *)textField
{
  AppLog(@"[%ld]textField.text: %@", (long)textField.tag, textField.text);
  switch (textField.tag) {
    case 0:
      self.tempSSID = textField.text;
      break;
      
    case 1:
      self.tempPassword = textField.text;
      break;
      
    default:
      break;
  }
}



@end
