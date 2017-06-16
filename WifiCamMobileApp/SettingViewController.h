//
//  SettingViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-11.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum SettingTableInfo {
  SettingTableTextLabel,
  SettingTableDetailTextLabel,
  SettingTableDetailType,
  SettingTableDetailData,
  SettingTableDetailLastItem,
  
}SettingTableInfo;

@interface SettingViewController : UITableViewController <UIAlertViewDelegate>

@end
