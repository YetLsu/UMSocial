//
//  CollectionViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "MpbViewControllerPrivate.h"
#import "MpbViewController.h"
#include "UtilsMacro.h"
#import "MpbCollectionViewCell.h"
#import "MpbCollectionHeaderView.h"
#import "MpbPopoverViewController.h"
#import "MBProgressHUD.h"
#import "VideoPlaybackViewController.h"
#import "WifiCamControl.h"

#import "UIActivityItemImage.h"
#import "UIActivityItemVideo.h"

#import "UIActivityDownload.h"
#import "UIActivityFacebook.h"
#import "UIActivityTwitter.h"
#import "UIActivityWeibo.h"
#import "UIActivityTencentWeibo.h"

#import "UIActivityWechatSession.h"
#import "UIActivityWechatTimeline.h"
#import "UIActivityWechatFavorite.h"
#import "UIActivityQQ.h"
#import "UIActivityEmail.h"
#import "UMSocial.h"

static NSString *kCellID = @"cellID";

@implementation MpbViewController
@synthesize observerNo;
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    observerNo=0;
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self initPhotoGallery];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
}

- (void)initPhotoGallery
{
    self.navigationItem.leftBarButtonItem = self.doneButton;
    self.title = NSLocalizedString(@"Albums", @"");
    self.editButton.title = NSLocalizedString(@"Edit", @"");
    self.doneButton.title = NSLocalizedString(@"Done", @"");
    self.mpbSemaphore = dispatch_semaphore_create(1);
    self.thumbnailQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Thumbnail", 0);
    self.downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Download", 0);
    self.downloadPercentQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.DownloadPercent", 0);
    self.collDataArray = [[NSMutableDictionary alloc] init];
    //self.browser = [_ctrl.fileCtrl createOneMWPhotoBrowserWithDelegate:self];
    self.selItemsTable = [_ctrl.fileCtrl createOneCellsTable];
    self.mpbCache = [_ctrl.fileCtrl createCacheForMultiPlaybackWithCountLimit:100
                                                               totalCostLimit:4096];
    self.enableHeader = YES;
    self.loaded = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    self.run = YES;
    
    if (_curMpbState == MpbStateNor) {
        [_selItemsTable.selectedCells removeAllObjects];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_loaded) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        
        // Get list and udpate collection-view
        dispatch_async(_thumbnailQueue, ^{
            [self resetCollectionViewData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                self.loaded = YES;
                
                if (_totalCount > 0) {
                    _editButton.enabled = YES;
                    _actionButton.enabled = YES;
                } else {
                    _editButton.enabled = NO;
                    _actionButton.enabled = NO;
                    self.browser = nil;
                }
                
                [self.collectionView reloadData];
            });
        });
    } else {
        if (_totalCount > 0) {
            _editButton.enabled = YES;
            _actionButton.enabled = YES;
        } else {
            _editButton.enabled = NO;
            _actionButton.enabled = NO;
        }
        
        [self.collectionView reloadData];
    }
}

- (void)resetCollectionViewData
{
    AppLog(@"listFiles start ...");
    _wifiCam.gallery = [WifiCamControl createOnePhotoGallery];
    self.gallery = _wifiCam.gallery;
    
    NSUInteger photoListSize = _gallery.imageTable.fileList.size();
    NSUInteger videoListSize = _gallery.videoTable.fileList.size();
    unsigned long long totalPhotoKBytes = _gallery.imageTable.fileStorage;
    unsigned long long totalVideoKBytes = _gallery.videoTable.fileStorage;
    unsigned long long totalAllKBytes = totalPhotoKBytes + totalVideoKBytes;
    
    AppLog(@"photoListSize: %lu", (unsigned long)photoListSize);
    AppLog(@"videoListSize: %lu", (unsigned long)videoListSize);
    AppLog(@"totalPhotoKBytes : %llu", totalPhotoKBytes);
    AppLog(@"totalVideoKBytes : %llu", totalVideoKBytes);
    AppLog(@"totalAllKBytes : %llu", totalAllKBytes);
    AppLog(@"listFiles end ...");
    
    // Clean-up
    [_collDataArray removeAllObjects];
    
    if (_enableHeader) {
        
        SEL photoSinglePlaybackFunction = @selector(photoSinglePlaybackCallback:);
        NSDictionary *photoDict = @{@(SectionTitle): NSLocalizedString(@"Photos",nil),
                                    @(SectionType):@(WCFileTypeImage),
                                    @(SectionDataTable):_gallery.imageTable,
                                    @(SectionTotalFileKBytes):@(totalPhotoKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(photoSinglePlaybackFunction)};
        [_collDataArray setObject:photoDict forKey:@(SectionIndexPhoto)];
        
        SEL videoSinglePlaybackFunction = @selector(videoSinglePlaybackCallback:);
        NSDictionary *videoDict = @{@(SectionTitle): NSLocalizedString(@"Videos",nil),
                                    @(SectionType):@(WCFileTypeVideo),
                                    @(SectionDataTable):_gallery.videoTable,
                                    @(SectionTotalFileKBytes):@(totalVideoKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(videoSinglePlaybackFunction)};
        [_collDataArray setObject:videoDict forKey:@(SectionIndexVideo)];
    } else {
        SEL allPlaybackFunction = @selector(allPlaybackCallback:);
        NSDictionary *photoDict = @{@(SectionTitle): NSLocalizedString(@"Photos",nil),
                                    @(SectionType):@(WCFileTypeAll),
                                    @(SectionDataTable):_gallery.allFileTable,
                                    @(SectionTotalFileKBytes):@(totalAllKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(allPlaybackFunction)};
        [_collDataArray setObject:photoDict forKey:@(0)];
    }
    
    self.totalCount = photoListSize + videoListSize;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.run = NO;
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    if (_actionSheet.visible) {
        [_actionSheet dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    if (_selItemsTable.count > 0 || observerNo > 0 ) {
        [self.selItemsTable removeObserver:self forKeyPath:@"count"];
        --observerNo;
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [_mpbCache removeAllObjects];
}

-(void)dealloc
{
    [_mpbCache removeAllObjects];
    self.doneButton = nil;
    self.browser = nil;
}

-(void)recoverFromDisconnection
{
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self.collectionView reloadData];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time{
    self.navigationController.toolbar.userInteractionEnabled = NO;
    if (message) {
        [self.view bringSubviewToFront:self.progressHUD];
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        self.progressHUD.dimBackground = YES;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = YES;
    
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode {
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = dMessage;
    self.progressHUD.mode = mode;
    self.progressHUD.dimBackground = YES;
    [self.view bringSubviewToFront:self.progressHUD];
    [self.progressHUD show:YES];
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = NO;
    
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage {
    if (message) {
        self.progressHUD.labelText = message;
    }
    if (dMessage) {
        self.progressHUD.progress = _downloadedPercent / 100.0;
        self.progressHUD.detailsLabelText = dMessage;
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
    
}

#pragma mark - MPB
- (IBAction)goHome:(id)sender
{
    self.run = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_mpbSemaphore, time) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDCompleteMessage:NSLocalizedString(@"STREAM_WAIT_FOR_VIDEO", nil)];
            });
            
        } else {
            
            dispatch_semaphore_signal(_mpbSemaphore);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self dismissViewControllerAnimated:YES completion:^{
                    AppLog(@"MPB QUIT ...");
                }];
                
            });
        }
        
    });
}

- (IBAction)edit:(id)sender
{
    if (_curMpbState == MpbStateNor) {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = NSLocalizedString(@"SelectItem", nil);
        self.curMpbState = MpbStateEdit;
        self.editButton.title = NSLocalizedString(@"Cancel", @"");
        self.editButton.style = UIBarButtonItemStyleDone;
        
        self.actionButton.enabled = NO;
        self.deleteButton.enabled = NO;
        [self.selItemsTable addObserver:self forKeyPath:@"count" options:0x0 context:nil];
        observerNo++;
    } else {
        if ([_ctrl.fileCtrl isBusy]) {
            // Cancel download
            self.cancelDownload = YES;
            [_ctrl.fileCtrl cancelDownload];
        }
        
        self.navigationItem.leftBarButtonItem = self.doneButton;
        self.title = NSLocalizedString(@"Albums", @"");
        self.curMpbState = MpbStateNor;
        self.editButton.title = NSLocalizedString(@"Edit", @"");
        self.editButton.style = UIBarButtonItemStyleBordered;
        
        if ([_popController isPopoverVisible]) {
            [_popController dismissPopoverAnimated:YES];
        }
        
        // Clear
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            //      ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
            MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:ip];
            [cell setSelectedConfirmIconHidden:YES];
            cell.tag = 0;
        }
        if (!_cancelDownload) {
            [_selItemsTable.selectedCells removeAllObjects];
        }
        
        self.selItemsTable.count = 0;
        [self.selItemsTable removeObserver:self forKeyPath:@"count"];
        --observerNo;
        self.totalDownloadSize = 0;
    }
}

-(void)showPopoverFromBarButtonItem:(UIBarButtonItem *)item
                            message:(NSString *)message
                    fireButtonTitle:(NSString *)fireButtonTitle
                           callback:(SEL)fireAction
{
    MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
    contentViewController.msg = message;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentViewController.msgColor = [UIColor blackColor];
    } else {
        contentViewController.msgColor = [UIColor whiteColor];
    }
    
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    if (fireButtonTitle) {
        UIButton *fireButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 110.0f, 260.0f, 47.0f)];
        popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
        fireButton.enabled = YES;
        
        [fireButton setTitle:fireButtonTitle
                    forState:UIControlStateNormal];
        [fireButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                              forState:UIControlStateNormal];
        [fireButton addTarget:self action:fireAction forControlEvents:UIControlEventTouchUpInside];
        [contentViewController.view addSubview:fireButton];
    } else {
        popController.popoverContentSize = CGSizeMake(270.0f, 85.0f);
    }
    
    self.popController = popController;
    [_popController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)showActionSheetFromBarButtonItem:(UIBarButtonItem *)item
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                 destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    tag:(NSInteger)tag
{
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                   delegate:self
                                          cancelButtonTitle:cancelButtonTitle
                                     destructiveButtonTitle:destructiveButtonTitle
                                          otherButtonTitles:nil, nil];
    _actionSheet.tag = tag;
    [_actionSheet showFromBarButtonItem:item animated:YES];
}

-(void)showActivityViewController:(NSArray *)activityItems
                         delegate:(id <ActivityWrapperDelegate>)delegate
{
    
    UIActivityDownload *download = [[UIActivityDownload alloc] initWithDelegate:delegate];
    UIActivityFacebook *facebook = [[UIActivityFacebook alloc] initWithDelegate:delegate];
    UIActivityTwitter *twitter = [[UIActivityTwitter alloc] initWithDelegate:delegate];
    UIActivityWeibo *weibo = [[UIActivityWeibo alloc] initWithDelegate:delegate];
    UIActivityTencentWeibo *tWeibo = [[UIActivityTencentWeibo alloc] initWithDelegate:delegate];
    UIActivityWechatSession *wechatSession = [[UIActivityWechatSession alloc] initWithDelegate:delegate];
    UIActivityWechatTimeline *wechatMoments = [[UIActivityWechatTimeline alloc] initWithDelegate:delegate];
    UIActivityWechatFavorite *wechatFavorite = [[UIActivityWechatFavorite alloc] initWithDelegate:delegate];
    UIActivityQQ *qq = [[UIActivityQQ alloc] initWithDelegate:delegate];
    UIActivityEmail *email = [[UIActivityEmail alloc] initWithDelegate:delegate];
    NSArray *appActivities = @[download, facebook, twitter, weibo, tWeibo, wechatSession, wechatMoments, wechatFavorite, qq, email];
    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                    applicationActivities:appActivities];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.activityViewController.popoverPresentationController.barButtonItem = _actionButton;
    }
    
    // Exclude
    /*
     self.activityViewController.excludedActivityTypes = @[UIActivityTypePostToFacebook,
     UIActivityTypePostToTwitter,
     UIActivityTypePostToWeibo,
     UIActivityTypeMessage,
     UIActivityTypeMail,
     UIActivityTypePrint,
     UIActivityTypeCopyToPasteboard,
     UIActivityTypeAssignToContact,
     UIActivityTypeSaveToCameraRoll,
     UIActivityTypeAddToReadingList,
     UIActivityTypePostToFlickr,
     UIActivityTypePostToVimeo,
     UIActivityTypePostToTencentWeibo,
     UIActivityTypeAirDrop];
     */
    [self presentViewController:_activityViewController animated:YES completion:nil];
}

//LaunchServices: invalidationHandler called
-(void)_showSLComposeViewController:(NSString *)serviceType {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isUsingUM = NO;
        UIImage *umShareImage = nil;
        SLComposeViewController *SLComposeSheet = nil;
        
        if ([serviceType isEqualToString:UMShareToWechatSession]
            || [serviceType isEqualToString:UMShareToWechatTimeline]
            || [serviceType isEqualToString:UMShareToWechatFavorite]
            || [serviceType isEqualToString:UMShareToQQ]
            || [serviceType isEqualToString:UMShareToEmail]) {
            isUsingUM = YES;
        } else {
            SLComposeSheet = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            [SLComposeSheet removeAllImages];
            [SLComposeSheet removeAllURLs];
        }
        
        // Downloading
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
            ICatchFile f = fileTable.fileList.at(ip.item);
            switch (f.getFileType()) {
                case TYPE_IMAGE: {
                    AppLog(@"Request image...");
                    UIImage *sharedImage = [_ctrl.fileCtrl requestImage:&f];
                    if (!isUsingUM) {
                        [SLComposeSheet addImage:sharedImage];
                    } else {
                        umShareImage = sharedImage;
                    }
                    
                }
                    break;
                    
                case TYPE_VIDEO:
                    break;
                default:
                    break;
            }
        }
        
        // Done
        if (!isUsingUM) {
            [SLComposeSheet setInitialText:@"Shared image from WCMApp2"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:NO];
            if (!isUsingUM) {
                [self presentViewController:SLComposeSheet animated:YES completion: nil];
            } else {
                
                [_ctrl.fileCtrl resetBusyToggle:YES];
                AppLog(@"type: %@", serviceType);
                [UMSocialData defaultData].extConfig.wxMessageType = UMSocialWXMessageTypeImage;
                [[UMSocialDataService defaultDataService] postSNSWithTypes:@[serviceType] content:nil image:umShareImage location:nil urlResource:nil presentedController:self completion:^(UMSocialResponseEntity *response) {
                    
                    [_ctrl.fileCtrl resetBusyToggle:NO];
                    [_selItemsTable.selectedCells removeAllObjects];
                    
                    if (response.responseCode == UMSResponseCodeSuccess) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"成功" message:@"分享成功" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"抱歉" message:@"分享失败" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil];
                        [alertView show];
                    }
                    
                }];
            }
            
        });
    });
}

-(void)showSLComposeViewController:(NSString *)serviceType
{
    [self showProgressHUDWithMessage:nil detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
    AppLog(@"serviceType: %@", serviceType);
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showSLComposeViewController:serviceType];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showSLComposeViewController:serviceType];
        }];
    }
    
}

-(void)_showDownloadConfirm:(NSString *)message
                      title:(NSString *)confrimButtonTitle
                     dBytes:(unsigned long long)downloadSizeInKBytes
                     fSpace:(double)freeDiscSpace {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (downloadSizeInKBytes < freeDiscSpace) {
            [self showPopoverFromBarButtonItem:self.actionButton
                                       message:message
                               fireButtonTitle:confrimButtonTitle
                                      callback:@selector(downloadDetail:)];
        } else {
            [self showPopoverFromBarButtonItem:self.actionButton
                                       message:message
                               fireButtonTitle:nil
                                      callback:nil];
        }
        
    } else {
        [self showActionSheetFromBarButtonItem:self.actionButton
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:confrimButtonTitle
                                           tag:ACTION_SHEET_DOWNLOAD_ACTIONS];
    }
}

-(void)showDownloadConfirm
{
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    NSInteger fileNum = 0;
    unsigned long long downloadSizeInKBytes = 0;
    NSString *confrimButtonTitle = nil;
    NSString *message = nil;
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    
    if (_curMpbState == MpbStateEdit) {
        
        if (_totalDownloadSize < freeDiscSpace/2.0) {
            message = [self makeupDownloadMessageWithSize:_totalDownloadSize
                                                andNumber:_selItemsTable.count];
            confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
        }
        
    } else {
        
        for (int i =0; i<_collDataArray.count; ++i) {
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
            fileNum += fileTable.fileList.size();
            downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
        }
        
        if (downloadSizeInKBytes < freeDiscSpace) {
            message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
                                                andNumber:fileNum];
            confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
        }
        
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
        }];
    }
}

-(NSString *)makeupDownloadMessageWithSize:(unsigned long long)sizeInKB
                                 andNumber:(NSInteger)num
{
    /*
     NSString *message = NSLocalizedString(@"DownloadConfirmMessage", nil);
     NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
     
     double downloadTime = (double)sizeInKB/1024/60;
     message = [message stringByReplacingOccurrencesOfString:@"%1"
     withString:[NSString stringWithFormat:@"%ld", (long)num]];
     message = [message stringByReplacingOccurrencesOfString:@"%2"
     withString:[NSString stringWithFormat:@"%.2f", downloadTime]];
     message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
     return message;
     */
    
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    unsigned long long downloadTimeInHours = (sizeInKB/1024)/3600;
    unsigned long long downloadTimeInMinutes = (sizeInKB/1024)/60 - downloadTimeInHours*60;
    unsigned long long downloadTimeInSeconds = sizeInKB/1024 - downloadTimeInHours*3600 - downloadTimeInMinutes*60;
    AppLog(@"downloadTimeInHours: %llu, downloadTimeInMinutes: %llu, downloadTimeInSeconds: %llu",
           downloadTimeInHours, downloadTimeInMinutes, downloadTimeInSeconds);
    
    if (downloadTimeInHours > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage3", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInHours]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%4"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else if (downloadTimeInMinutes > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage2", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else {
        message = NSLocalizedString(@"DownloadConfirmMessage1", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    }
    message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
    return message;
    
}

-(NSString *)makeupNoDownloadMessageWithSize:(unsigned long long)sizeInKB
{
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    NSString *leftSpace = [_ctrl.comCtrl translateSize:freeDiscSpace];
    message = [NSString stringWithFormat:@"%@\n Download:%@, Free:%@", NSLocalizedString(@"NotEnoughSpaceError", nil), humanDownloadFileSize, leftSpace];
    message = [message stringByAppendingString:@"\n Needs double free space"];
    return message;
}

- (IBAction)actionButtonPressed:(id)sender
{
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    /*
     NSInteger fileNum = 0;
     unsigned long long downloadSizeInKBytes = 0;
     NSString *confrimButtonTitle = nil;
     NSString *message = nil;
     double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
     
     if (_curMpbState == MpbStateEdit) {
     if (_totalDownloadSize < freeDiscSpace) {
     message = [self makeupDownloadMessageWithSize:_totalDownloadSize
     andNumber:_selItemsTable.count];
     confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
     } else {
     message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
     }
     
     } else {
     
     for (int i =0; i<_collDataArray.count; ++i) {
     WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
     fileNum += fileTable.fileList.size();
     downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
     }
     
     if (downloadSizeInKBytes < freeDiscSpace) {
     message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
     andNumber:fileNum];
     confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
     } else {
     message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
     }
     
     }
     */
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        ICatchFile f = fileTable.fileList.at(ip.item);
        switch (f.getFileType()) {
            case TYPE_IMAGE: {
                UIActivityItemImage *sharedImage = [[UIActivityItemImage alloc] init];
                [items addObject:sharedImage];
            }
                break;
                
            case TYPE_VIDEO: {
                UIActivityItemVideo *sharedVideo = [[UIActivityItemVideo alloc] init];
                [items addObject:sharedVideo];
            }
                break;
            default:
                break;
        }
    }
    
    [self showActivityViewController:items delegate:self];
}

- (void)requestDownloadPercent:(ICatchFile *)file
{
    if (!file) {
        AppLog(@"file is null");
        return;
    }
    
    ICatchFile *f = file;
    NSString *locatePath = nil;
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    unsigned long long fileSize = f->getFileSize();
    locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    AppLog(@"locatePath: %@, %llu", locatePath, fileSize);
    
    dispatch_async(_downloadPercentQueue, ^{
        do {
            
            if (_cancelDownload) break;
            //self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:f];
            self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:locatePath
                                                                      fileSize:fileSize];
            AppLog(@"percent: %u", self.downloadedPercent);
            
            [NSThread sleepForTimeInterval:0.2];
        } while (_downloadFileProcessing);
        
    });
}

- (NSArray *)downloadAllOfType:(WCFileType)type
{
    ICatchFile *file = NULL;
    vector<ICatchFile> fileList;
    NSInteger downloadedNum = 0;
    NSInteger downloadFailedCount = 0;
    
    switch (type) {
        case WCFileTypeImage:
            fileList = _gallery.imageTable.fileList;
            break;
            
        case WCFileTypeVideo:
            fileList = _gallery.videoTable.fileList;
            break;
            
        default:
            break;
    }
    
    for(vector<ICatchFile>::iterator it = fileList.begin();
        it != fileList.end();
        ++it) {
        if (_cancelDownload) {
            break;
        }
        
        file = &(*it);
        
        self.downloadFileProcessing = YES;
        [self requestDownloadPercent:file];
        if (![_ctrl.fileCtrl downloadFile:file]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        ++downloadedNum;
        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
    }
    
    return [NSArray arrayWithObjects:@(downloadedNum), @(downloadFailedCount), nil];
}

- (NSArray *)downloadAll
{
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    NSArray *resultArray = nil;
    
    resultArray = [self downloadAllOfType:WCFileTypeImage];
    downloadedPhotoNum = [resultArray[0] integerValue];
    downloadFailedCount += [resultArray[1] integerValue];
    
    resultArray = [self downloadAllOfType:WCFileTypeVideo];
    downloadedVideoNum = [resultArray[0] integerValue];
    downloadFailedCount += [resultArray[1] integerValue];
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (NSArray *)downloadSelectedFiles
{
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        if (_cancelDownload) break;
        
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        ICatchFile f = fileTable.fileList.at(ip.item);
        
        self.downloadFileProcessing = YES;
        [self requestDownloadPercent:&f];
        if (![_ctrl.fileCtrl downloadFile:&f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        switch (f.getFileType()) {
            case TYPE_IMAGE:
                ++downloadedPhotoNum;
                break;
                
            case TYPE_VIDEO:
                ++downloadedVideoNum;
                break;
                
            case TYPE_TEXT:
            case TYPE_AUDIO:
            case TYPE_ALL:
            case TYPE_UNKNOWN:
            default:
                break;
        }
        
        self.downloadedPercent = 0;
        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
        
    }
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (IBAction)downloadDetail:(id)sender
{
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.cancelDownload = NO;
    
    // Prepare
    if (_curMpbState == MpbStateNor) {
        self.navigationItem.leftBarButtonItem = nil;
        self.editButton.title = NSLocalizedString(@"Cancel", @"");
        self.editButton.style = UIBarButtonItemStyleDone;
        [self.selItemsTable addObserver:self forKeyPath:@"count" options:0x0 context:nil];
        self.totalDownloadFileNumber = _totalCount;
    } else {
        self.totalDownloadFileNumber = _selItemsTable.selectedCells.count;
    }
    self.actionButton.enabled = NO;
    self.deleteButton.enabled = NO;
    self.downloadedFileNumber = 0;
    self.downloadedPercent = 0;
    [self addObserver:self forKeyPath:@"downloadedFileNumber" options:0x0 context:nil];
    [self addObserver:self forKeyPath:@"downloadedPercent" options:NSKeyValueObservingOptionNew context:nil];
    NSUInteger handledNum = MIN(_downloadedFileNumber + 1, _totalDownloadFileNumber);
    NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
    
    // Show processing notice
    [self showProgressHUDWithMessage:msg
                      detailsMessage:nil
                                mode:MBProgressHUDModeDeterminate];
    // Just in case, _selItemsTable.selectedCellsn wouldn't be destoried after app enter background
    [_ctrl.fileCtrl tempStoreDataForBackgroundDownload:_selItemsTable.selectedCells];
    
    dispatch_async(_downloadQueue, ^{
        NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
        NSInteger downloadFailedCount = 0;
        UIBackgroundTaskIdentifier downloadTask;
        NSArray *resultArray = nil;
        
        [_ctrl.fileCtrl resetBusyToggle:YES];
        // -- Request more time to excute task within background
        UIApplication  *app = [UIApplication sharedApplication];
        downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
            
            AppLog(@"-->Expiration");
            NSArray *oldNotifications = [app scheduledLocalNotifications];
            // Clear out the old notification before scheduling a new one
            if ([oldNotifications count] > 5) {
                [app cancelAllLocalNotifications];
            }
            
            NSString *noticeMessage = [NSString stringWithFormat:@"[Progress: %lu/%lu] - App is about to exit. Please bring it to foreground to continue dowloading.", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
            [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
        }];
        
        
        // ---------- Downloading
        if (_curMpbState == MpbStateNor) {
            self.curMpbState = MpbStateEdit;
            resultArray = [self downloadAll];
        } else {
            resultArray = [self downloadSelectedFiles];
        }
        downloadedPhotoNum = [resultArray[0] integerValue];
        downloadedVideoNum = [resultArray[1] integerValue];
        downloadFailedCount = [resultArray[2] integerValue];
        // -----------
        
        
        // Download is completed, notice & update GUI
        self.totalDownloadSize = 0;
        // Post local notification
        if (app.applicationState == UIApplicationStateBackground) {
            NSString *noticeMessage = NSLocalizedString(@"SavePhotoToAlbum", @"Download complete.");
            [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
        }
        // HUD notification
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObserver:self forKeyPath:@"downloadedFileNumber"];
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
            
            // Clear
            for (NSIndexPath *ip in _selItemsTable.selectedCells) {
                MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:ip];
                [cell setSelectedConfirmIconHidden:YES];
                cell.tag = 0;
            }
            [_selItemsTable.selectedCells removeAllObjects];
            self.selItemsTable.count = 0;
            
            if (!_cancelDownload) {
                NSString *message = nil;
                if (downloadFailedCount > 0) {
                    NSString *message = NSLocalizedString(@"DownloadSelectedError", nil);
                    message = [message stringByReplacingOccurrencesOfString:@"%d" withString:[NSString stringWithFormat:@"%d", downloadFailedCount]];
                    [self showProgressHUDNotice:message showTime:0.5];
                    
                } else {
                    
                    message = NSLocalizedString(@"DownloadDoneMessage", nil);
                    NSString *photoNum = [NSString stringWithFormat:@"%ld", (long)downloadedPhotoNum];
                    NSString *videoNum = [NSString stringWithFormat:@"%ld", (long)downloadedVideoNum];
                    message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                                 withString:photoNum];
                    message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                                 withString:videoNum];
                    [self showProgressHUDCompleteMessage:message];
                }
                
            } else {
                [self hideProgressHUD:YES];
            }
        });
        
        [_ctrl.fileCtrl resetBusyToggle:NO];
        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
    });
}

- (IBAction)delete:(id)sender
{
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    NSString *message = NSLocalizedString(@"DeleteMultiAsk", nil);
    NSString *replaceString = [NSString stringWithFormat:@"%ld", (long)_selItemsTable.count];
    message = [message stringByReplacingOccurrencesOfString:@"%d"
                                                 withString:replaceString];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self showPopoverFromBarButtonItem:sender
                                   message:message
                           fireButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                  callback:@selector(deleteDetail:)];
    } else {
        [self showActionSheetFromBarButtonItem:sender
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                           tag:ACTION_SHEET_DELETE_ACTIONS];
    }
}

- (IBAction)deleteDetail:(id)sender
{
    __block int failedCount = 0;
    
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.run = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    
    //  NSMutableArray *toDeletedIndexPaths = [[NSMutableArray alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cachedKey = nil;
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        dispatch_semaphore_wait(_mpbSemaphore, time);
        
        // Real delete icatch file & remove NSCache item
        
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            //      int type = [[a objectAtIndex:1] intValue];
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
            ICatchFile f = fileTable.fileList.at(ip.item);
            //ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
            if ([_ctrl.fileCtrl deleteFile:&f] == NO) {
                ++failedCount;
            }
            cachedKey = [NSString stringWithFormat:@"ID%d", f.getFileHandle()];
            /*
             switch (type) {
             case WCFileTypeImage:
             if (!_enableHeader) {
             ip = [_ctrl.fileCtrl requestSplitedIndexPathOfType:WCFileTypeImage
             withIndex:ip.item];
             }
             [_ctrl.fileCtrl requestDeleteFileOfType:WCFileTypeImage withIndex:ip.item];
             cachedKey = [_ctrl.fileCtrl requestFileIdOfType:WCFileTypeImage
             withIndex:ip.item];
             break;
             case WCFileTypeVideo:
             if (!_enableHeader) {
             ip = [_ctrl.fileCtrl requestSplitedIndexPathOfType:WCFileTypeVideo
             withIndex:ip.item];
             }
             [_ctrl.fileCtrl requestDeleteFileOfType:WCFileTypeVideo withIndex:ip.item];
             cachedKey = [_ctrl.fileCtrl requestFileIdOfType:WCFileTypeVideo
             withIndex:ip.item];
             break;
             default:
             break;
             }
             [toDeletedIndexPaths addObject:ip];
             */
            
            [_mpbCache removeObjectForKey:cachedKey];
        }
        
        // Update the UICollectionView's data source
        [self resetCollectionViewData];
        dispatch_semaphore_signal(_mpbSemaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failedCount != _selItemsTable.selectedCells.count) {
                [_selItemsTable.selectedCells removeAllObjects];
                self.run = YES;
                [self.collectionView reloadData];
            }
            
            NSString *noticeMessage = nil;
            
            if (failedCount > 0) {
                noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
                NSString *failedCountString = [NSString stringWithFormat:@"%d", failedCount];
                noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
            } else {
                noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
            }
            [self showProgressHUDCompleteMessage:noticeMessage];
            self.selItemsTable.count = 0;
        });
        
    });
}

-(void)prepareForAction
{
    NSInteger selectedPhotoNum = 0;
    NSInteger selectedVideoNum = 0;
    
    self.deleteButton.enabled = YES;
    self.actionButton.enabled = YES;
    
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        ICatchFile f = fileTable.fileList.at(ip.item);
        //    int type = [[a objectAtIndex:1] intValue];
        //    ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
        switch (f.getFileType()) {
            case TYPE_IMAGE:
                ++selectedPhotoNum;
                break;
                
            case TYPE_VIDEO:
                ++selectedVideoNum;
                break;
            default:
                break;
        }
    }
    AppLog(@"VIDEO: %ld, IMAGE: %ld", (long)selectedVideoNum, (long)selectedPhotoNum);
    
    if ((selectedPhotoNum > 0) && (selectedVideoNum > 0)) {
        NSString  *demoTitle = NSLocalizedString(@"SelectedItems", nil);
        NSString  *items = [NSString stringWithFormat:@"%d", selectedPhotoNum + selectedVideoNum];
        self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        
    } else if (selectedPhotoNum > 0) {
        if (selectedPhotoNum == 1) {
            self.title = NSLocalizedString(@"SelectedOnePhoto", nil);
        } else {
            NSString  *demoTitle = NSLocalizedString(@"SelectedPhotos", nil);
            NSString  *items = [NSString stringWithFormat:@"%ld", (long)selectedPhotoNum];
            self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        }
    } else if (selectedVideoNum > 0) {
        if (selectedVideoNum == 1) {
            self.title = NSLocalizedString(@"SelectedOneVideo", nil);
        } else {
            NSString  *demoTitle = NSLocalizedString(@"SelectedVideos", nil);
            NSString  *items = [NSString stringWithFormat:@"%ld", (long)selectedVideoNum];
            self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        }
    }
}

-(void)prepareForCancelAction
{
    if (_curMpbState == MpbStateEdit) {
        self.deleteButton.enabled = NO;
        self.actionButton.enabled = NO;
        if (_totalCount > 0) {
            self.title = NSLocalizedString(@"SelectItem", nil);
        } else {
            self.curMpbState = MpbStateNor;
            self.title = NSLocalizedString(@"Albums", @"");
            self.editButton.title = NSLocalizedString(@"Edit", @"");
            self.editButton.enabled = NO;
            self.navigationItem.leftBarButtonItem = self.doneButton;
        }
    } else {
        self.deleteButton.enabled = NO;
        self.actionButton.enabled = _totalCount > 0 ? YES : NO;
    }
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject              :(id)object
        change                :(NSDictionary *)change
        context               :(void *)context
{
    if ([keyPath isEqualToString:@"count"]) {
        if (_selItemsTable.count > 0) {
            [self prepareForAction];
        } else {
            [self prepareForCancelAction];
        }
    } else if ([keyPath isEqualToString:@"downloadedFileNumber"]) {
        NSUInteger handledNum = MIN(_downloadedFileNumber + 1, _totalDownloadFileNumber);
        NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
        [self updateProgressHUDWithMessage:msg detailsMessage:nil];
    } else if([keyPath isEqualToString:@"downloadedPercent"]) {
        // TODO: NSKeyValueChangeNewKey
        //AppLog(@"xxx : %d", [[change objectForKey:@"NSKeyValueChangeNewKey"] intValue]);
        
        NSString *msg = [NSString stringWithFormat:@"%lu%%", (unsigned long)_downloadedPercent];
        [self updateProgressHUDWithMessage:nil detailsMessage:msg];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet         :(UIActionSheet *)actionSheet
        clickedButtonAtIndex:(NSInteger)buttonIndex
{
    _actionSheet = nil;
    switch (actionSheet.tag) {
        case ACTION_SHEET_DOWNLOAD_ACTIONS:
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self downloadDetail:self];
            }
            break;
            
        case ACTION_SHEET_DELETE_ACTIONS:
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self deleteDetail:self];
            }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _popController = nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSUInteger count = _collDataArray.count;
    
    if (count > 0 && !_enableHeader) {
        count = 1;
    }
    
    AppLog(@"numberOfSectionsInCollectionView: %lu", (unsigned long)count);
    return count;
}

- (NSInteger) collectionView        :(UICollectionView *)collectionView
              numberOfItemsInSection:(NSInteger)section
{
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(section)] objectForKey:@(SectionDataTable)];
    NSInteger num = fileTable.fileList.size();
    AppLog(@"numberOfItemsInSection: %ld", (long)num);
    return num;
}

- (void)setCellTag:(MpbCollectionViewCell *)cell
         indexPath:(NSIndexPath *)indexPath
{
    if ([_selItemsTable.selectedCells containsObject:indexPath]) {
        [cell setSelectedConfirmIconHidden:NO];
        cell.tag = 1;
    } else {
        [cell setSelectedConfirmIconHidden:YES];
        cell.tag = 0;
    }
}
/*
 - (WCFileType)calcType:(int)sectionType
 cell:(MpbCollectionViewCell *)cell
 indexPath:(NSIndexPath *)indexPath
 {
 WCFileType type = WCFileTypeUnknow;
 switch (sectionType) {
 case WCFileTypeVideo:
 type = WCFileTypeVideo;
 [cell setVideoStaticIconHidden:NO];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeVideo];
 break;
 case WCFileTypeImage:
 type = WCFileTypeImage;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeImage];
 break;
 case WCFileTypeAudio:
 type = WCFileTypeAudio;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeAudio];
 break;
 case WCFileTypeText:
 type = WCFileTypeText;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeText];
 break;
 case WCFileTypeAll:
 [self calcType:[_ctrl.fileCtrl requestFileTypeAtAll:indexPath.item] cell:cell indexPath:indexPath];
 type = WCFileTypeAll;
 default:
 break;
 }
 
 return type;
 }
 */

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MpbCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID
                                                                forIndexPath:indexPath];
    //  WCFileType type = WCFileTypeUnknow;
    //  int sectionType = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
    //  type = [self calcType:sectionType cell:cell indexPath:indexPath];
    
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    ICatchFile file = fileTable.fileList.at(indexPath.item);
    
    [self setCellTag:cell indexPath:indexPath];
    switch (file.getFileType()) {
        case TYPE_IMAGE:
            [cell setVideoStaticIconHidden:YES];
            break;
            
        case TYPE_VIDEO:
            [cell setVideoStaticIconHidden:NO];
            break;
            
        default:
            break;
    }
    
    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
    UIImage *image = [_mpbCache objectForKey:cachedKey];
    
    
    if (image) {
        cell.imageView.image = image;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"empty_photo"];
        
        double delayInSeconds = 0.05;
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(delayTime, _thumbnailQueue, ^{
            if (!_run) {
                AppLog(@"bypass...");
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(_mpbSemaphore, time);
            // Just in case, make sure the cell for this indexPath is still On-Screen.
            if ([cv cellForItemAtIndexPath:indexPath]) {
                UIImage *image = [_ctrl.fileCtrl requestThumbnail:(ICatchFile *)&file];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_mpbCache setObject:image forKey:cachedKey];
                        MpbCollectionViewCell *c = (MpbCollectionViewCell *)[cv cellForItemAtIndexPath:indexPath];
                        if (c) {
                            c.imageView.image = image;
                        }
                    });
                } else {
                    AppLog(@"request thumbnail failed");
                }
            }
            dispatch_semaphore_signal(_mpbSemaphore);
        });
        
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableView = nil;
    
    if (_enableHeader && kind == UICollectionElementKindSectionHeader) {
        
        MpbCollectionHeaderView *headerView = [cv dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                     withReuseIdentifier:@"headerView"
                                                                            forIndexPath:indexPath];
        WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
        NSInteger totalNum = dataTable.fileList.size();
        if (totalNum > 0) {
            
            headerView.title.text = [NSString stringWithFormat:@"%@ : %ld",
                                     [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionTitle)],
                                     (long)totalNum];
            
        } else {
            int type = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
            headerView.title.text = [_staticData.noFileNoticeDict objectForKey:@(type)];
            if (!headerView.title.text) {
                headerView.title.text = NSLocalizedString(@"No files", nil);
            }
        }
        
        reusableView = headerView;
    } else if (_enableFooter && kind == UICollectionElementKindSectionFooter) {
        // ...
    }
    
    return reusableView;
}


#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if (_enableHeader && _totalCount > 0) {
        return CGSizeMake(self.collectionView.bounds.size.width, 50);
    } else {
        return CGSizeMake(0, 0);
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    if (_enableFooter && _totalCount > 0) {
        return CGSizeMake(self.collectionView.bounds.size.width, 50);
    } else {
        return CGSizeMake(0, 0);
    }
}


#pragma mark - UICollectionViewDelegate

- (void)photoSinglePlaybackCallback:(NSIndexPath *)indexPath
{
    self.browser = [_ctrl.fileCtrl createOneMWPhotoBrowserWithDelegate:self];
    [_browser setCurrentPhotoIndex:indexPath.row];
    [self.navigationController pushViewController:self.browser animated:YES];
    //    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:_browser];
    //    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //    [self presentViewController:nc animated:YES completion:nil];
}

- (void)videoSinglePlaybackCallback:(NSIndexPath *)indexPath
{
    if (![_ctrl.fileCtrl isVideoPlaybackEnabled]) {
        [self showProgressHUDNotice:NSLocalizedString(@"ShowNoViewVideoTip", nil) showTime:1.0];
        return;
    }
    
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    ICatchFile file = fileTable.fileList.at(indexPath.item);
    
    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
    _videoPlaybackIndex = indexPath.item;
    
    UIImage *image = [_mpbCache objectForKey:cachedKey];
    if (!image) {
        dispatch_suspend(_thumbnailQueue);
        
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!_run) {
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(_mpbSemaphore, time);
            
            UIImage *image = [_ctrl.fileCtrl requestThumbnail:(ICatchFile *)&file];
            if (image != nil) {
                [_mpbCache setObject:image forKey:cachedKey];
            }
            dispatch_semaphore_signal(_mpbSemaphore);
            dispatch_resume(_thumbnailQueue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _videoPlaybackThumb = image;
                [self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
            });
        });
    } else {
        _videoPlaybackThumb = image;
        [self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
    }
}

- (void)allPlaybackCallback:(NSIndexPath *)indexPath
{
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    ICatchFile file = fileTable.fileList.at(indexPath.item);
    
    switch (file.getFileType()) {
        case TYPE_IMAGE:
            [self photoSinglePlaybackCallback:indexPath];
            break;
            
        case TYPE_VIDEO:
            [self videoSinglePlaybackCallback:indexPath];
            break;
            
        default:
            [self nonePlaybackCallback:indexPath];
            break;
    }
}

- (void)nonePlaybackCallback:(NSIndexPath *)indexPath
{
    [self showProgressHUDCompleteMessage:NSLocalizedString(@"It's not supported yet.", nil)];
}

- (void)collectionView          :(UICollectionView *)cv
        didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_curMpbState == MpbStateNor) {
        NSString *callbackName = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionPlaybackCallback)];
        SEL callback = NSSelectorFromString(callbackName);
        if ([self respondsToSelector:callback]) {
            AppLog(@"callback-index: %ld", (long)indexPath.item);
            [self performSelector:callback withObject:indexPath afterDelay:0];
        } else {
            AppLog(@"It's not support to playback this file.");
        }
    } else {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
        ICatchFile file = fileTable.fileList.at(indexPath.item);
        
        /*
         WCFileType type = WCFileTypeUnknow;
         int sectionType = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
         switch (sectionType) {
         case WCFileTypeVideo:
         type = WCFileTypeVideo;
         break;
         
         case WCFileTypeImage:
         type = WCFileTypeImage;
         break;
         
         case WCFileTypeAll:
         type = [_ctrl.fileCtrl requestFileTypeAtAll:indexPath.item];
         break;
         
         case WCFileTypeAudio:
         case WCFileTypeText:
         default:
         break;
         }
         
         NSArray *a = @[indexPath, @(type)];
         */
        //    NSArray *fileCell = @[indexPath, [NSValue valueWithPointer:&file]];
        MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[cv cellForItemAtIndexPath:indexPath];
        if (cell.tag == 1) { // It's selected.
            cell.tag = 0;
            [cell setSelectedConfirmIconHidden:YES];
            [_selItemsTable.selectedCells removeObject:indexPath];
            _totalDownloadSize -= file.getFileSize()>>10;
        } else {
            cell.tag = 1;
            [cell setSelectedConfirmIconHidden:NO];
            [_selItemsTable.selectedCells addObject:indexPath];
            _totalDownloadSize += file.getFileSize()>>10;
        }
        
        self.selItemsTable.count = _selItemsTable.selectedCells.count;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    VideoPlaybackViewController *vpvc = [segue destinationViewController];
    vpvc.delegate = self;
    vpvc.previewImage = _videoPlaybackThumb;
    vpvc.index = _videoPlaybackIndex;
}

#pragma mark - VideoPlaybackControllerDelegate
-(BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller
            deleteVideoAtIndex:(NSUInteger)index
{
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexVideo)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     file = &(dataTable.fileList.at(index));
     } else {
     listSize = _gallery.videoTable.fileList.size();
     file = &(_gallery.videoTable.fileList.at(index));
     }
     */
    
    listSize = _gallery.videoTable.fileList.size();
    if (listSize>0) {
        i = MAX(0, MIN(index, listSize - 1));
        ICatchFile file = _gallery.videoTable.fileList.at(i);
        ret = [_ctrl.fileCtrl deleteFile:&file];
        if (ret) {
            NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
            [_mpbCache removeObjectForKey:cachedKey];
            [self resetCollectionViewData];
        }
    }
    
    return ret;
}


#pragma mark - MWPhotoBrowserDataSource
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    /*
     NSUInteger retVal = 0;
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     retVal = dataTable.fileList.size();
     } else {
     retVal = _gallery.imageTable.fileList.size();
     }
     return retVal;
     */
    return _gallery.imageTable.fileList.size();
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser
                photoAtIndex:(NSUInteger)index
{
    MWPhoto *photo = nil;
    unsigned long listSize = 0;
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     } else {
     listSize = _gallery.imageTable.fileList.size();
     }
     */
    listSize = _gallery.imageTable.fileList.size();
    ICatchFile file = _gallery.imageTable.fileList.at(index);
    
    if (index < listSize) {
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"sdk://test"] funcBlock:^{
            AppLog(@"requestPhotoOfType");
            return [_ctrl.fileCtrl requestImage:(ICatchFile *)&file];
        }];
    }
    
    return photo;
}
/*
 - (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser
 captionViewForPhotoAtIndex:(NSUInteger)index
 {
 MWCaptionView *caption = nil;
 
 return caption;
 }
 */
#pragma mark - MWPhotoBrowserDelegate
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    //    ICatchFile file = _gallery.imageTable.fileList.at(index);
    //    UIImage *image = [_ctrl.fileCtrl requestImage:(ICatchFile *)&file];
    [_selItemsTable.selectedCells removeAllObjects];
    [_selItemsTable.selectedCells addObject:[NSIndexPath indexPathForItem:index inSection:SectionIndexPhoto]];
    UIActivityItemImage *sharedImage = [[UIActivityItemImage alloc] init];
    [self showActivityViewController:@[sharedImage] delegate:photoBrowser];
}


- (BOOL)photoBrowser      :(MWPhotoBrowser *)photoBrowser
        deletePhotoAtIndex:(NSUInteger)index
{
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     } else {
     listSize = _gallery.imageTable.fileList.size();
     }
     */
    listSize = _gallery.imageTable.fileList.size();
    if (listSize>0) {
        i = MAX(0, MIN(index, listSize - 1));
        ICatchFile file = _gallery.imageTable.fileList.at(i);
        ret = [_ctrl.fileCtrl deleteFile:&file];
        if (ret) {
            NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
            [_mpbCache removeObjectForKey:cachedKey];
            [self resetCollectionViewData];
        }
    }
    
    return ret;
}

-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser downloadPhotoAtIndex:(NSUInteger)index
{
    NSInteger downloadFailedCount = 0;
    NSArray *resultArray = nil;
    UIBackgroundTaskIdentifier downloadTask;
    
    [_ctrl.fileCtrl resetBusyToggle:YES];
    // -- Request more time to excute task within background
    UIApplication  *app = [UIApplication sharedApplication];
    downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
        
        AppLog(@"-->Expiration");
        NSArray *oldNotifications = [app scheduledLocalNotifications];
        // Clear out the old notification before scheduling a new one
        if ([oldNotifications count] > 5) {
            [app cancelAllLocalNotifications];
        }
    }];
    
    resultArray = [self downloadSelectedFiles];
    downloadFailedCount = [resultArray[2] integerValue];
    
    // Post local notification
    if (app.applicationState == UIApplicationStateBackground) {
        NSString *noticeMessage;
        if (downloadFailedCount > 0) {
            noticeMessage = NSLocalizedString(@"Download Failed.", @"Download failed.");
        } else {
            noticeMessage = NSLocalizedString(@"SavePhotoToAlbum", @"Download complete.");
        }
        [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
    }
    [_ctrl.fileCtrl resetBusyToggle:NO];
    [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
    
    return downloadFailedCount>0?NO:YES;
}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser sharePhotoAtIndex:(NSUInteger)index serviceType:(NSString *)serviceType{
    [self showSLComposeViewController:serviceType];
}
@end
