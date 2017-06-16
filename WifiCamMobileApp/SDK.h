//
//  SDK.h - Data Access Layer
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-6.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ICatchWificam.h"
#import "WifiCamAVData.h"
#import "WifiCamObserver.h"
#include <vector>
using namespace std;


enum WCFileType {
  WCFileTypeImage  = TYPE_IMAGE,
  WCFileTypeVideo  = TYPE_VIDEO,
  WCFileTypeAudio  = TYPE_AUDIO,
  WCFileTypeText   = TYPE_TEXT,
  WCFileTypeAll    = TYPE_ALL,
  WCFileTypeUnknow = TYPE_UNKNOWN,
};

enum WCRetrunType {
  WCRetSuccess = ICH_SUCCEED,
  WCRetFail,
  WCRetNoSD,
  WCRetSDFUll,
};


@interface SDK : NSObject


#pragma mark - Global
@property (nonatomic) NSMutableArray *downloadArray;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL isBusy;
@property (nonatomic) NSUInteger downloadedTotalNumber;
@property (nonatomic) BOOL connected;
@property (nonatomic, readwrite) dispatch_queue_t sdkQueue;
@property (nonatomic, readwrite) BOOL isSDKInitialized;

#pragma mark - API adapter layer
// SDK
+(SDK *)instance;
-(BOOL)initializeSDK;
-(void)destroySDK;
-(void)cleanUpDownloadDirectory;
-(void)enableLogSdkAtDiretctory:(NSString *)directoryName enable:(BOOL)enable;
-(BOOL)isConnected;

// MEDIA
-(BOOL)startMediaStream:(ICatchPreviewMode)mode enableAudio:(BOOL)enableAudio;;
-(BOOL)stopMediaStream;
-(BOOL)isMediaStreamOn;
-(WifiCamAVData *)getFrameData;
-(WifiCamAVData *)getAudioData;
-(BOOL)videoStreamEnabled;
-(BOOL)audioStreamEnabled;
-(ICatchAudioFormat)getAudioFormat;

// CONTROL
-(WCRetrunType)capturePhoto;
-(WCRetrunType)triggerCapturePhoto;
-(BOOL)startMovieRecord;
-(BOOL)stopMovieRecord;
-(BOOL)startTimelapseRecord;
-(BOOL)stopTimelapseRecord;
-(BOOL)formatSD;
-(BOOL)checkSDExist;
-(void)addObserver:(ICatchEventID)eventTypeId listener:(ICatchWificamListener *)listener isCustomize:(BOOL)isCustomize;
-(void)removeObserver:(ICatchEventID)eventTypeId listener:(ICatchWificamListener *)listener isCustomize:(BOOL)isCustomize;
-(void)addObserver:(WifiCamObserver *)observer;
-(void)removeObserver:(WifiCamObserver *)observer;
-(BOOL)zoomIn;
-(BOOL)zoomOut;

// Photo gallery
-(vector<ICatchFile>)requestFileListOfType:(WCFileType)fileType;
-(UIImage *)requestThumbnail:(ICatchFile *)file;
-(UIImage *)requestImage:(ICatchFile *)file;
-(BOOL)downloadFile:(ICatchFile *)f;
-(void)cancelDownload;
-(BOOL)deleteFile:(ICatchFile *)f;

// Video playback
-(WifiCamAVData *)getPlaybackFrameData;
-(WifiCamAVData *)getPlaybackAudioData;
-(ICatchAudioFormat)getPlaybackAudioFormat;
-(BOOL)videoPlaybackEnabled;
-(BOOL)videoPlaybackStreamEnabled;
-(BOOL)audioPlaybackStreamEnabled;
-(double)play:(ICatchFile *)file;
-(void)pause;
-(void)resume;
-(void)stop;
-(void)seek:(double)point;

//
-(BOOL)isMediaStreamRecording;
-(BOOL)isVideoTimelapseOn;
-(BOOL)isStillTimelapseOn;

// Properties
-(vector<ICatchMode>)retrieveSupportedCameraModes;
-(vector<ICatchCameraProperty>)retrieveSupportedCameraCapabilities;
-(vector<unsigned int>)retrieveSupportedWhiteBalances;
-(vector<unsigned int>)retrieveSupportedCaptureDelays;
-(vector<string>)retrieveSupportedImageSizes;
-(vector<string>)retrieveSupportedVideoSizes;
-(vector<unsigned int>)retrieveSupportedLightFrequencies;
-(vector<unsigned int>)retrieveSupportedBurstNumbers;
-(vector<unsigned int>)retrieveSupportedDateStamps;
-(vector<unsigned int>)retrieveSupportedTimelapseInterval;
-(vector<unsigned int>)retrieveSupportedTimelapseDuration;
-(string)retrieveImageSize;
-(string)retrieveVideoSize;
-(unsigned int)retrieveDelayedCaptureTime;
-(unsigned int)retrieveWhiteBalanceValue;
-(unsigned int)retrieveLightFrequency;
-(unsigned int)retrieveBurstNumber;
-(unsigned int)retrieveDateStamp;
-(unsigned int)retrieveTimelapseInterval;
-(unsigned int)retrieveTimelapseDuration;
-(unsigned int)retrieveBatteryLevel;
-(unsigned int)retrieveFreeSpaceOfImage;
-(unsigned int)retrieveFreeSpaceOfVideo;
-(NSString *)retrieveCameraFWVersion;
-(NSString *)retrieveCameraProductName;
-(uint)retrieveMaxZoomRatio;
-(uint)retrieveCurrentZoomRatio;
-(uint)retrieveCurrentUpsideDown;
-(uint)retrieveCurrentSlowMotion;
-(ICatchCameraMode)retrieveCurrentCameraMode;

// Change properties
-(int)changeImageSize:(string)size;
-(int)changeVideoSize:(string)size;
-(int)changeDelayedCaptureTime:(unsigned int)time;
-(int)changeWhiteBalance:(unsigned int)value;
-(int)changeLightFrequency:(unsigned int)value;
-(int)changeBurstNumber:(unsigned int)value;
-(int)changeDateStamp:(unsigned int)value;
-(int)changeTimelapseInterval:(unsigned int)value;
-(int)changeTimelapseDuration:(unsigned int)value;
-(int)changeUpsideDown:(uint)value;
-(int)changeSlowMotion:(uint)value;

// Customize property stuff
-(int)getCustomizePropertyIntValue:(int)propid;
-(NSString *)getCustomizePropertyStringValue:(int)propid;
-(BOOL)setCustomizeIntProperty:(int)propid value:(uint)value;
-(BOOL)setCustomizeStringProperty:(int)propid value:(NSString *)value;
-(BOOL)isValidCustomerID:(int)customerid;


@end

