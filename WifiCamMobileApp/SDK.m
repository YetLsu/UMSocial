//
//  SDK.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-6.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "SDK.h"

#include "ICatchWificamConfig.h"
@interface SDK ()
@property (nonatomic) ICatchWificamSession *session;
@property (nonatomic) ICatchWificamPreview *preview;
@property (nonatomic) ICatchWificamControl *control;
@property (nonatomic) ICatchWificamProperty *prop;
@property (nonatomic) ICatchWificamPlayback *playback;
@property (nonatomic) ICatchWificamVideoPlayback* vplayback;
@property (nonatomic) ICatchWificamState *sdkState;
@property (nonatomic) ICatchWificamInfo *sdkInfo;

@property (nonatomic) ICatchFrameBuffer* videoFrameBufferA;
@property (nonatomic) ICatchFrameBuffer* videoFrameBufferB;
@property (nonatomic) BOOL curVideoFrameBufferA;
@property (nonatomic) ICatchFrameBuffer* audioTrackBuffer;
@property (nonatomic) BOOL isStopped;

@property (nonatomic) NSMutableData *imageData;
@property (nonatomic) NSMutableData *audioData;
@property (nonatomic) NSMutableData *videoPlaybackData;
@property (nonatomic) NSMutableData *audioPlaybackData;

@end

@implementation SDK

//@synthesize curPVFileIndex = _curPVFileIndex;

@synthesize downloadArray;
@synthesize downloadedTotalNumber;
@synthesize sdkQueue;
@synthesize isSDKInitialized;

#pragma mark - SDK status

+ (SDK *)instance {
    static SDK *instance = nil;
    /*
     @synchronized(self) {
     if(!instance) {
     instance = [[self alloc] init];
     }
     }
     */
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initSingleton];
        instance.sdkQueue = dispatch_queue_create("WifiCam.GCD.Queue.SDKQ", DISPATCH_QUEUE_SERIAL);
    });
    return instance;
    
}

- (id)init {
  // Forbid calls to –init or +new
  //NSAssert(NO, @"Cannot create instance of Singleton");
  
  // You can return nil or [self initSingleton] here,
  // depending on how you prefer to fail.
  return [self initSingleton];
}

// Real (private) init method
- (id)initSingleton {
  if (self = [super init]) {
    // Init code
  }
  return self;
}

- (BOOL)initializeSDK {
  BOOL ret = NO;
  
  do {
    
    @synchronized(self) {
      
      AppLog(@"---START INITIALIZE SDK(Data Access Layer)---");
      // Destroy older instance
      [self destroySDK];
      _session = new ICatchWificamSession();
      self.videoFrameBufferA = new ICatchFrameBuffer(640 * 480 * 2);
      self.videoFrameBufferB = new ICatchFrameBuffer(640 * 480 * 2);
      self.curVideoFrameBufferA = YES;
      self.audioTrackBuffer = new ICatchFrameBuffer(1024*512);
      self.downloadArray = [[NSMutableArray alloc] init];
      
#if (SDK_DEBUG==1)
      ICatchWificamLog* log = ICatchWificamLog::getInstance();
      log->setSystemLogOutput( true );
      log->setPtpLog(true);
      log->setRtpLog(true);
      log->setPtpLogLevel(LOG_LEVEL_INFO);
      log->setRtpLogLevel(LOG_LEVEL_INFO);
#endif
      
      if (_session == NULL) {
        AppLog(@"Create session failed.");
        break;
      }
      
      AppLog(@"prepareSession");
      if (  _session->prepareSession("192.168.1.1") != ICH_SUCCEED  )
      {
        AppLog(@"prepareSession failed");
        break;
      } else {
        if (_session->checkConnection() == false) {
          AppLog(@"_session check camera connection return false.");
          break;
        }
      }
      AppLog(@"prepareSession done");
      
      self.preview = _session->getPreviewClient();
      self.control = _session->getControlClient();
      self.prop = _session->getPropertyClient();
      self.playback = _session->getPlaybackClient();
      self.vplayback = _session->getVideoPlaybackClient();
      self.sdkState = _session->getStateClient();
      self.sdkInfo = _session->getInfoClient();
      if (!_preview || !_control || !_prop || !_playback || !_sdkState || !_sdkInfo) {
        AppLog(@"SDK objects were nil");
        break;
      }
      
      ret = YES;
    }
  } while (0);
  
  if (ret) {
    AppLog(@"---End---");
  } else {
    AppLog(@"---INITIALIZE SDK Failed---");
    [self destroySDK];
  }
  
  return ret;
}

- (void)destroySDK
{
  @synchronized(self) {
    if (_session != NULL) {
      AppLog(@"start destory session");
      
      _session->destroySession();
      delete _session;_session = NULL;
      AppLog(@"destory session done");
    }
    
    if (_videoFrameBufferA) {
      delete _videoFrameBufferA; _videoFrameBufferA = NULL;
    }
    if (_videoFrameBufferB) {
      delete _videoFrameBufferB; _videoFrameBufferB = NULL;
    }
    if (_audioTrackBuffer) {
      delete _audioTrackBuffer; _audioTrackBuffer = NULL;
    }
    
    self.preview = NULL;
    self.control = NULL;
    self.prop = NULL;
    self.playback = NULL;
    self.vplayback = NULL;
    self.sdkState = NULL;
    self.sdkInfo = NULL;
  }
}

-(void)cleanUpDownloadDirectory
{
  [self cleanTemp];
}

-(void)enableLogSdkAtDiretctory:(NSString *)directoryName
                         enable:(BOOL)enable
{
  ICatchWificamLog* log = ICatchWificamLog::getInstance();
  if (enable) {
    log->setFileLogPath(string([directoryName UTF8String]));
    log->setPtpLogLevel(LOG_LEVEL_INFO);
    log->setRtpLogLevel(LOG_LEVEL_INFO);
    log->setFileLogOutput(true);
    log->setPtpLog(true);
    log->setRtpLog(true);
  } else {
    log->setFileLogOutput(false);
    log->setPtpLog(false);
    log->setRtpLog(false);
  }
}

-(BOOL)isConnected
{
  BOOL retVal = NO;
  if (_session && _session->checkConnection()) {
    retVal = YES;
  }
  return retVal;
}

-(NSString *)retrieveCameraFWVersion
{
  return [NSString stringWithFormat:@"%s", _sdkInfo->getCameraFWVersion().c_str()];
}

-(NSString *)retrieveCameraProductName
{
  return [NSString stringWithFormat:@"%s", _sdkInfo->getCameraProductName().c_str()];
}

#pragma mark - Retrieve Infomattion

-(vector<ICatchMode>)retrieveSupportedCameraModes
{
  vector<ICatchMode> supportedCameraModes;
  _control->getSupportedModes(supportedCameraModes);
  
  return supportedCameraModes;
}

-(vector<ICatchCameraProperty>)retrieveSupportedCameraCapabilities
{
  vector<ICatchCameraProperty> supportedCameraCapability;
  _prop->getSupportedProperties(supportedCameraCapability);
  
  return supportedCameraCapability;
}

-(vector<unsigned int>)retrieveSupportedWhiteBalances
{
  vector<unsigned int> supportedWhiteBalances;
  _prop->getSupportedWhiteBalances(supportedWhiteBalances);
  return supportedWhiteBalances;
}

-(vector<unsigned int>)retrieveSupportedCaptureDelays
{
  vector<unsigned int> supportedCaptureDelays;
  _prop->getSupportedCaptureDelays(supportedCaptureDelays);
  return supportedCaptureDelays;
}

-(vector<string>)retrieveSupportedImageSizes
{
  vector<string> supportedImageSizes;
  _prop->getSupportedImageSizes(supportedImageSizes);
  return supportedImageSizes;
}

-(vector<string>)retrieveSupportedVideoSizes
{
  vector<string> supportedVideoSizes;
  _prop->getSupportedVideoSizes(supportedVideoSizes);
  return supportedVideoSizes;
}

-(vector<unsigned int>)retrieveSupportedLightFrequencies
{
  vector<unsigned int> supportedLightFrequencies;
  _prop->getSupportedLightFrequencies(supportedLightFrequencies);
  
  // Erase some items within vector
  NSMutableArray *a = [[NSMutableArray alloc] init];
  int i = 0;
  for (vector<unsigned int>::iterator it = supportedLightFrequencies.begin();
       it != supportedLightFrequencies.end();
       ++it, ++i) {
    if (*it == LIGHT_FREQUENCY_AUTO || *it == LIGHT_FREQUENCY_UNDEFINED) {
      //[a addObject:[NSNumber numberWithInt:i]];
      [a addObject:@(i)];
    }
  }
  for (i=0; i<a.count; ++i) {
    supportedLightFrequencies.erase(supportedLightFrequencies.begin()+i);
  }
  
  AppLog(@"_supportedLightFrequencies.size: %lu", supportedLightFrequencies.size());
  return supportedLightFrequencies;
}

-(vector<unsigned int>)retrieveSupportedBurstNumbers
{
  vector<unsigned int> supportedBurstNumbers;
  _prop->getSupportedBurstNumbers(supportedBurstNumbers);
  //  for(vector<unsigned int>::iterator it = supportedBurstNumbers.begin();
  //      it != supportedBurstNumbers.end();
  //      ++it) {
  //    AppLog(@"%d", *it);
  //  }
  return supportedBurstNumbers;
}

-(vector<unsigned int>)retrieveSupportedDateStamps
{
  vector<unsigned int> supportedDataStamps;
  _prop->getSupportedDateStamps(supportedDataStamps);
  return supportedDataStamps;
}

-(vector<unsigned int>)retrieveSupportedTimelapseInterval
{
  vector<unsigned int> supportedTimelapseIntervals;
  _prop->getSupportedTimeLapseIntervals(supportedTimelapseIntervals);
  AppLog(@"This size of supportedVideoTimelapseIntervals: %lu", supportedTimelapseIntervals.size());
  return supportedTimelapseIntervals;
}

-(vector<unsigned int>)retrieveSupportedTimelapseDuration
{
  vector<unsigned int> supportedTimelapseDurations;
  _prop->getSupportedTimeLapseDurations(supportedTimelapseDurations);
  AppLog(@"This size of supportedVideoTimelapseDurations: %lu", supportedTimelapseDurations.size());
  return supportedTimelapseDurations;
}

-(string)retrieveImageSize {
  string curImageSize;
  _prop->getCurrentImageSize(curImageSize);
  return curImageSize;
}

-(string)retrieveVideoSize {
  string curVideoSize;
  _prop->getCurrentVideoSize(curVideoSize);
  return curVideoSize;
}

-(unsigned int)retrieveDelayedCaptureTime {
  unsigned int curCaptureDelay;
  _prop->getCurrentCaptureDelay(curCaptureDelay);
  return curCaptureDelay;
}

-(unsigned int)retrieveWhiteBalanceValue {
  unsigned int curWhiteBalance;
  _prop->getCurrentWhiteBalance(curWhiteBalance);
  return curWhiteBalance;
}

-(unsigned int)retrieveLightFrequency {
  unsigned int curLightFrequency;
  _prop->getCurrentLightFrequency(curLightFrequency);
  return curLightFrequency;
}
-(unsigned int)retrieveBurstNumber {
  unsigned int curBurstNumber;
  _prop->getCurrentBurstNumber(curBurstNumber);
  AppLog(@"curBurstNumber: %d", curBurstNumber);
  return curBurstNumber;
}

-(unsigned int)retrieveDateStamp {
  unsigned int curDateStamp;
  _prop->getCurrentDateStamp(curDateStamp);
  return curDateStamp;
}

-(unsigned int)retrieveTimelapseInterval {
  unsigned int curVideoTimelapseInterval;
  _prop->getCurrentTimeLapseInterval(curVideoTimelapseInterval);
  AppLog(@"Re-Get timelapse interval[RAW]: %d", curVideoTimelapseInterval);
  return curVideoTimelapseInterval;
}

-(unsigned int)retrieveTimelapseDuration {
  unsigned int curVideoTimelapseDuration;
  _prop->getCurrentTimeLapseDuration(curVideoTimelapseDuration);
  AppLog(@"curVideoTimelapseDuration: %d", curVideoTimelapseDuration);
  return curVideoTimelapseDuration;
}

-(unsigned int)retrieveBatteryLevel {
  unsigned int curBatteryLevel;
  _control->getCurrentBatteryLevel(curBatteryLevel);
  return curBatteryLevel;
}

-(unsigned int)retrieveFreeSpaceOfImage {
  unsigned int photoNum = 0;
  uint num = 0;
  int ret = _control->getFreeSpaceInImages(num);
  if (ICH_SUCCEED == ret) {
    photoNum = num;
  }
  
  return photoNum;
  
}

-(unsigned int)retrieveFreeSpaceOfVideo {
  unsigned int secs = 0;
  _control->getRemainRecordingTime(secs);
  
  return secs;
}

-(uint)retrieveMaxZoomRatio
{
  uint ratio = 1;
  _prop->getMaxZoomRatio(ratio);
  AppLog(@"max ratio: %d", ratio);
  return ratio;
}

-(uint)retrieveCurrentZoomRatio
{
  uint ratio = 1;
  _prop->getCurrentZoomRatio(ratio);
  return ratio;
}

-(uint)retrieveCurrentUpsideDown
{
  uint curUD = 0;
  _prop->getCurrentUpsideDown(curUD);
  return curUD;
}

-(uint)retrieveCurrentSlowMotion
{
  uint curSM = 0;
  _prop->getCurrentSlowMotion(curSM);
  return curSM;
}


-(ICatchCameraMode)retrieveCurrentCameraMode
{
  return _control->getCurrentCameraMode();
}

#pragma mark - Change properties
-(int)changeImageSize:(string)size {
  return _prop->setImageSize(size);
}

-(int)changeVideoSize:(string)size{
  return _prop->setVideoSize(size);
}

-(int)changeDelayedCaptureTime:(unsigned int)time{
  return _prop->setCaptureDelay(time);
}

-(int)changeWhiteBalance:(unsigned int)value{
  return _prop->setWhiteBalance(value);
}

-(int)changeLightFrequency:(unsigned int)value {
  return _prop->setLightFrequency(value);
}

-(int)changeBurstNumber:(unsigned int)value {
  return _prop->setBurstNumber(value);
}

-(int)changeDateStamp:(unsigned int)value {
  return _prop->setDateStamp(value);
}

-(int)changeTimelapseInterval:(unsigned int)value {
  return _prop->setTimeLapseInterval(value);
}

-(int)changeTimelapseDuration:(unsigned int)value {
  return _prop->setTimeLapseDuration(value);
}

-(int)changeUpsideDown:(uint)value {
  return _prop->setUpsideDown(value);
}

-(int)changeSlowMotion:(uint)value {
  return _prop->setSlowMotion(value);
}


#pragma mark - MEDIA
- (BOOL)startMediaStream:(ICatchPreviewMode)mode  enableAudio:(BOOL)enableAudio{
    int startRetVal = ICH_SUCCEED;
    
    if (!_preview || !_prop) {
        return NO;
    }
    
    ICatchVideoFormat format;
    _prop->getCurrentStreamingInfo(format);
    
    int codec = format.getCodec();
    int w = format.getVideoW();
    int h = format.getVideoH();
    int br = format.getBitrate();
    AppLog(@"codec: 0x%x, w: %d, h: %d, br: %d", codec, w, h, br);
    // old version is 640x360, SBC is 720x400 br 5M
    if( codec == ICATCH_CODEC_H264){
        // do not support H264 , change to default 720x400 br 60M
        w = 720;
        h = 400;
        br = 6000000;
    }else{
        // MJPEG need support old version 640x360 50M
        w = (w<=0) ? 640 : w;
        h = (h<=0) ? 360 : h;
        br = (br<=60000) ? 5000000 : br;
    }
    
    AppLog(@"codec change to: 0x%x, w: %d, h: %d, br: %d", codec, w, h, br);

    bool disableAudio = enableAudio == YES ? false : true;
    
    uint cacheTime = [self previewCacheTime];
    AppLog(@"cacheTime: %d", cacheTime);
    if (cacheTime < 200) {
        //cacheTime = 1000;
        cacheTime = 1000;
        ICatchWificamConfig::getInstance()->setPreviewCacheParam(cacheTime);
    }
    
    //if (codec == ICATCH_CODEC_H264) {
    //    AppLog(@"%s - start h264", __func__);
    //    ICatchH264StreamParam param(w, h, br);
    //    startRetVal = _preview->start(param, mode, disableAudio);
    //} else {
        AppLog(@"%s - start mjpg", __func__);
        ICatchMJPGStreamParam param(w, h, br);
        startRetVal = _preview->start(param, mode, disableAudio);
    //}
    AppLog(@"%s - retVal : %d", __func__, startRetVal);
    
    self.isStopped = NO;
    
    if (startRetVal == ICH_SUCCEED) {
        return YES;
    } else {
        AppLog(@"%s failed", __func__);
        return NO;
    }
}

- (BOOL)stopMediaStream {
    
    @synchronized(self) {
        if (!self.isStopped) {
            
            AppLog(@"%s - start", __func__);
            
            if (![self isMediaStreamOn]) {
                AppLog(@"%s - Already stoped", __func__);
                //return NO;
            }
            
            int retVal = 1;
            
            if(_preview)
                retVal = _preview->stop();
            AppLog(@"%s - retVal : %d", __func__,retVal);
            
            self.isStopped = YES;
            
            if (retVal == ICH_SUCCEED) {
                return YES;
            } else {
                AppLog(@"%s failed", __func__);
                return NO;
            }
        } else {
            return YES;
        }
    }
    
    
}

- (BOOL)isMediaStreamOn {
  BOOL retVal = NO;
  
  if (_sdkState->isStreaming() == true) {
    retVal = YES;
  }
  return retVal;
}

- (BOOL)isMediaStreamRecording {
  BOOL retVal = NO;
  
  if (_sdkState->isMovieRecording() == true) {
    retVal = YES;
  }
  return retVal;
}

-(BOOL)isVideoTimelapseOn {
  
  BOOL retVal = NO;
  
  if (_sdkState->isTimeLapseVideoOn() == true) {
    AppLog(@"_sdkState->isTimeLapseVideoOn() == true");
    retVal = YES;
  } else {
    AppLog(@"_sdkState->isTimeLapseVideoOn() == false");
  }
  return retVal;
}

-(BOOL)isStillTimelapseOn {
  BOOL retVal = NO;
  
  if (_sdkState->isTimeLapseStillOn() == true) {
    AppLog(@"_sdkState->isTimeLapseStillOn() == true");
    retVal = YES;
  } else {
    AppLog(@"_sdkState->isTimeLapseStillOn() == false");
  }
  return retVal;
}


- (WifiCamAVData *)getFrameData {
    if (!_preview) {
        AppLog(@"SDK doesn't work!!!");
        return nil;
    }
    
  WifiCamAVData *videoFrameData = nil;
  double time = 0;
  int retVal = -1;
  NSRange maxRange;
  maxRange.location = 0;
  maxRange.length = 720 * 400 * 2;
  
  ICatchFrameBuffer *frameBuffer = NULL;
  
  
  if (_curVideoFrameBufferA) {
    self.curVideoFrameBufferA = NO;
    retVal = _preview->getNextVideoFrame(_videoFrameBufferA);
    frameBuffer = _videoFrameBufferA;
  } else {
    self.curVideoFrameBufferA = YES;
    retVal = _preview->getNextVideoFrame(_videoFrameBufferB);
    frameBuffer = _videoFrameBufferB;
  }
  
  if (retVal == ICH_SUCCEED) {
    
    if (!_imageData) {
      //      self.imageData = [NSMutableData dataWithBytesNoCopy:frameBuffer->getBuffer()
      //                                                   length:frameBuffer->getBufferSize()
      //                                             freeWhenDone:NO];
      self.imageData = [NSMutableData dataWithBytes:frameBuffer->getBuffer()
                                             length:maxRange.length];
      
    } else {
      _imageData.length = maxRange.length;
      [_imageData replaceBytesInRange:maxRange withBytes:frameBuffer->getBuffer()];
    }
    _imageData.length = frameBuffer->getFrameSize();
    
    time = frameBuffer->getPresentationTime();
    videoFrameData = [[WifiCamAVData alloc] initWithData:_imageData andTime:time];
  } else {
    AppLog(@"--> getNextVideoFrame failed : %d", retVal);
  }
  
  
  return videoFrameData;
}

- (WifiCamAVData *)getAudioData {
  WifiCamAVData *audioTrackData = nil;
  double time = 0;
  int retVal = -1;
  NSRange maxRange;
  maxRange.location = 0;
  maxRange.length = 1024 * 512;
  
  if (_audioTrackBuffer) {
    retVal = _preview->getNextAudioFrame(_audioTrackBuffer);
    if (retVal == ICH_SUCCEED) {
      if (!_audioData) {
        //        self.audioData = [NSMutableData dataWithBytesNoCopy:_audioTrackBuffer->getBuffer()
        //                                                     length:_audioTrackBuffer->getFrameSize()
        //                                               freeWhenDone:NO];
        self.audioData = [NSMutableData dataWithBytes:_audioTrackBuffer->getBuffer()
                                               length:maxRange.length];
      } else {
        _audioData.length = maxRange.length;
        [_audioData replaceBytesInRange:maxRange withBytes:_audioTrackBuffer->getBuffer()];
      }
      _audioData.length = _audioTrackBuffer->getFrameSize();
      
      time = _audioTrackBuffer->getPresentationTime();
      audioTrackData = [[WifiCamAVData alloc] initWithData:_audioData andTime:time];
    } else {
      AppLog(@"--> getNextAudioFrame failed : %d", retVal);
      audioTrackData = [[WifiCamAVData alloc] init];
      audioTrackData.time = 0;
      audioTrackData.data = nil;
    }
  }
  
  audioTrackData.state = retVal;
  return audioTrackData;
}

- (BOOL)videoStreamEnabled {
  return _preview->containsVideoStream() == true ? YES : NO;
}

- (BOOL)audioStreamEnabled {
  return _preview->containsAudioStream() == true ? YES : NO;
}

- (WifiCamAVData *)getPlaybackFrameData {
  WifiCamAVData *videoFrameData = nil;
  double time = 0;
  int retVal;
  NSRange maxRange;
  maxRange.location = 0;
  maxRange.length = 640 * 480 * 2;
  
  ICatchFrameBuffer *frameBuffer = NULL;
  if (_vplayback == NULL) {
    return nil;
  }
  if (_curVideoFrameBufferA) {
    self.curVideoFrameBufferA = NO;
    retVal = _vplayback->getNextVideoFrame(_videoFrameBufferA);
    frameBuffer = _videoFrameBufferA;
  } else {
    self.curVideoFrameBufferA = YES;
    retVal = _vplayback->getNextVideoFrame(_videoFrameBufferB);
    frameBuffer = _videoFrameBufferB;
  }
  
  //AppLog(@"getPlaybackFrameData : %d", retVal);
  
  if (retVal == ICH_SUCCEED) {
    if (!_videoPlaybackData) {
      AppLog(@"Create videoPlaybackData");
      self.videoPlaybackData = [NSMutableData dataWithBytes:frameBuffer->getBuffer()
                                             length:maxRange.length];
      
    } else {
      _videoPlaybackData.length = maxRange.length;
      [_videoPlaybackData replaceBytesInRange:maxRange withBytes:frameBuffer->getBuffer()];
    }
    _videoPlaybackData.length = frameBuffer->getFrameSize();
    
    time = frameBuffer->getPresentationTime();
    //AppLog(@"video frame presentation time: %f", time);
    videoFrameData = [[WifiCamAVData alloc] initWithData:_videoPlaybackData andTime:time];
  } else {
    AppLog(@"--> getNextVideoFrame failed : %d", retVal);
    videoFrameData = [[WifiCamAVData alloc] init];
    videoFrameData.time = 0;
    videoFrameData.data = nil;
  }
  
  videoFrameData.state = retVal;
  return videoFrameData;
}

- (WifiCamAVData *)getPlaybackAudioData {
  WifiCamAVData *audioTrackData = nil;
  double time = 0;
  NSRange maxRange;
  maxRange.location = 0;
  maxRange.length = 1024 * 512;
  
  if (_audioTrackBuffer) {
    int retVal = _vplayback->getNextAudioFrame(_audioTrackBuffer);
    if (retVal == ICH_SUCCEED) {
      if (!_audioPlaybackData) {
        AppLog(@"Create audioPlaybackData");
        //        self.audioPlaybackData = [NSMutableData dataWithBytesNoCopy:_audioTrackBuffer->getBuffer()
        //                                                     length:_audioTrackBuffer->getFrameSize()
        //                                               freeWhenDone:NO];
        self.audioPlaybackData = [NSMutableData dataWithBytes:_audioTrackBuffer->getBuffer()
                                               length:maxRange.length];
      } else {
        _audioPlaybackData.length = maxRange.length;
        [_audioPlaybackData replaceBytesInRange:maxRange withBytes:_audioTrackBuffer->getBuffer()];
      }
      _audioPlaybackData.length = _audioTrackBuffer->getFrameSize();
      
      /*
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        FILE *file;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"testAudio"];
        file = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+");
        
        fwrite(_audioTrackBuffer->getBuffer(), sizeof(char), _audioTrackBuffer->getFrameSize(), file);
        
        fclose(file);
      });
      */
      
      
      
      
      time = _audioTrackBuffer->getPresentationTime();
      //AppLog(@"audio track presentation time: %f", time);
      audioTrackData = [[WifiCamAVData alloc] initWithData:_audioPlaybackData andTime:time];
    } else {
      AppLog(@"--> getNextAudioFrame failed : %d", retVal);
    }
  } else {
    AppLog(@"_audioTrackBuffer is NULL");
  }
  
  return audioTrackData;
}

- (BOOL)videoPlaybackStreamEnabled {
  return _vplayback->containsVideoStream() == true ? YES : NO;
}

- (BOOL)audioPlaybackStreamEnabled {
  return _vplayback->containsAudioStream() == true ? YES : NO;
}

#pragma mark - CONTROL
- (WCRetrunType)capturePhoto {
  WCRetrunType retVal = WCRetSuccess;
  
  do {
    if (_sdkState->isCameraBusy() == false) {
      if (_control->capturePhoto() != ICH_SUCCEED) {
        retVal = WCRetFail;
        break;
      }
    } else {
      retVal = WCRetFail;
      break;
    }
  } while (0);
  
  return retVal;
}

- (WCRetrunType)triggerCapturePhoto
{
  WCRetrunType retVal = WCRetSuccess;
  
  do {
    if (_sdkState->isCameraBusy() == false) {
      AppLog(@"Trigger capture.");
      if (_control->triggerCapturePhoto() != ICH_SUCCEED) {
        retVal = WCRetFail;
        break;
      }
    } else {
      AppLog(@"Camera Busy!!!");
      retVal = WCRetFail;
      break;
    }
  } while (0);
  
  return retVal;
}

- (BOOL)startMovieRecord{
  int retVal = ICH_SUCCEED;
  retVal = _control->startMovieRecord();
  AppLog(@"%s : retVal: %d", __func__, retVal);
  return retVal==ICH_SUCCEED?YES:NO;
}

- (BOOL)stopMovieRecord {
  int retVal = ICH_SUCCEED;
  
  retVal = _control->stopMovieRecord();
  AppLog(@"%s : retVal: %d", __func__, retVal);
  return retVal==ICH_SUCCEED?YES:NO;
}

-(BOOL)startTimelapseRecord {
  TRACE();
  int retVal = ICH_SUCCEED;
  retVal = _control->startTimeLapse();
  return retVal==ICH_SUCCEED?YES:NO;
}

-(BOOL)stopTimelapseRecord {
  TRACE();
  int retVal = ICH_SUCCEED;
  retVal = _control->stopTimeLapse();
  return retVal==ICH_SUCCEED?YES:NO;
}

- (void)addObserver:(ICatchEventID)eventTypeId listener:(ICatchWificamListener *)listener isCustomize:(BOOL)isCustomize
{
  AppLog(@"%s", __func__);
  if (listener != NULL && _control != NULL) {
    
    if (isCustomize) {
      AppLog(@"add customize eventTypeId: %d", eventTypeId);
      _control->addCustomEventListener(eventTypeId, listener);
    } else {
      AppLog(@"add eventTypeId: %d", eventTypeId);
      _control->addEventListener(eventTypeId, listener);
    }
  } else  {
    AppLog(@"listener is null");
    //NSAssert(listener != NULL, @"");
  }
  
}

-(void)addObserver:(WifiCamObserver *)observer;
{
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_NULL;
            ret = ICatchWificamSession::addEventListener(observer.eventType, observer.listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Add global event(%d) listener succeed.", observer.eventType);
            } else {
                AppLog(@"Add global event(%d) listener failed.", observer.eventType);
            }
            return;
        } else {
            if (_control) {
                if (observer.isCustomized) {
                    AppLog(@"add customize eventTypeId: %d", observer.eventType);
                    _control->addCustomEventListener(observer.eventType, observer.listener);
                } else {
                    AppLog(@"add eventTypeId: %d", observer.eventType);
                    _control->addEventListener(observer.eventType, observer.listener);
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
}

-(void)removeObserver:(WifiCamObserver *)observer {
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_NULL;
            ret = ICatchWificamSession::delEventListener(observer.eventType, observer.listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove global event(%d) listener succeed.", observer.eventType);
            } else {
                AppLog(@"Remove global event(%d) listener failed.", observer.eventType);
            }
            return;
        } else {
            if (_control) {
                if (observer.isCustomized) {
                    AppLog(@"Remove customize eventTypeId: %d", observer.eventType);
                    _control->delCustomEventListener(observer.eventType, observer.listener);
                } else {
                    AppLog(@"Remove eventTypeId: %d", observer.eventType);
                    _control->delEventListener(observer.eventType, observer.listener);
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
            
        }
    } else  {
        AppLog(@"listener is null");
    }
}

- (void)removeObserver:(ICatchEventID)eventTypeId listener:(ICatchWificamListener *)listener isCustomize:(BOOL)isCustomize
{
  AppLog(@"%s", __func__);
  if (listener != NULL && _control != NULL) {
    if (isCustomize) {
      _control->delCustomEventListener(eventTypeId, listener);
    } else {
      _control->delEventListener(eventTypeId, listener);
    }
    
  } else  {
    AppLog(@"listener is null");
  }
}

- (BOOL)formatSD {
  int retVal = ICH_SUCCEED;
  retVal = _control->formatStorage();
  return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)checkSDExist {
  BOOL retVal = YES;
  
  if (_control->isSDCardExist() == false) {
    retVal = NO;
    AppLog(@"Please insert an SD card");
  }
  
  return retVal;
}

- (BOOL)zoomIn {
  int ret = _control->zoomIn();
  if (ret != ICH_SUCCEED) {
    AppLog(@"ZoomIn failed.");
    return NO;
  } else {
    return YES;
  }
  
}

- (BOOL)zoomOut {
  int ret = _control->zoomOut();
  if (ret != ICH_SUCCEED) {
    AppLog(@"zoomOut failed.");
    return NO;
  } else {
    return YES;
  }
}


#pragma mark - PLAYBACK
- (vector<ICatchFile>)requestFileListOfType:(WCFileType)fileType
{
  vector<ICatchFile> list;
  switch (fileType) {
    case WCFileTypeImage:
      _playback->listFiles(TYPE_IMAGE, list);
      break;
      
    case WCFileTypeVideo:
      _playback->listFiles(TYPE_VIDEO, list);
      break;
      
    case WCFileTypeAll:
      _playback->listFiles(TYPE_ALL, list);
      break;
      
    case WCFileTypeAudio:
    case WCFileTypeText:
    case WCFileTypeUnknow:
    default:
      break;
  }
  
  AppLog(@"listSize: %lu", list.size());
  return list;
}

- (UIImage *)requestThumbnail:(ICatchFile *)f {
  UIImage *retImg = nil;
  ICatchFrameBuffer *thumbBuf = new ICatchFrameBuffer(640*360*2);
  
  do {
    if (f == NULL) {
      AppLog(@"fileHandle is nil");
      break;
    }
    if (thumbBuf == NULL) {
      AppLog(@"new failed");
      break;
    }
    if (ICH_BUF_TOO_SMALL == _playback->getThumbnail(f, thumbBuf)) {
      AppLog(@"ICH_BUF_TOO_SMALL");
      break;
    }
    if (thumbBuf->getFrameSize() <=0) {
      AppLog(@"thumbBuf's data size <= 0");
      break;
    }
    NSData *imageData = [NSData dataWithBytes:thumbBuf->getBuffer()
                                       length:thumbBuf->getFrameSize()];
    
    
    UIImage *thumbnail = [UIImage imageWithData:imageData];
    
    if (f->getFileType() == TYPE_VIDEO
        && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      UIImage *videoIcon = [UIImage imageNamed:@"image_video"];
      NSArray *imgArray = [[NSArray alloc] initWithObjects:videoIcon, nil];
      NSArray *imgPointArray = [[NSArray alloc] initWithObjects:@(5.0), @(thumbnail.size.height - videoIcon.size.height/2.0 - 5.0), nil];
      retImg = [Tool mergedImageOnMainImage:thumbnail WithImageArray:imgArray AndImagePointArray:imgPointArray];
    } else {
      retImg = thumbnail;
    }
    
    
  } while (0);
  
  delete thumbBuf;
  thumbBuf = NULL;
  
  return retImg;
}

- (UIImage *)requestImage:(ICatchFile *)f
{
  UIImage* image = nil;
  ICatchFrameBuffer *picBuf = new ICatchFrameBuffer(3648*2736/2);
  if (picBuf == NULL) {
    AppLog(@"new failed");
    return nil;
  }
  //int ret = _playback->downloadFile(f, picBuf);
  int ret = _playback->getQuickview(f, picBuf);
  
  if (ret == ICH_BUF_TOO_SMALL) {
    delete picBuf;
    picBuf = NULL;
    picBuf = new ICatchFrameBuffer(3648*2736);
    if (picBuf == NULL) {
      AppLog(@"New failed");
      return nil;
    }
    _playback->downloadFile(f, picBuf);
  }
  
  if (picBuf->getFrameSize() <=0) {
    AppLog(@"picBuf is empty");
    return nil;
  }
  NSData *imageData = [NSData dataWithBytes:picBuf->getBuffer()
                                     length:picBuf->getFrameSize()];
  delete picBuf;
  picBuf = NULL;
  image = [UIImage imageWithData:imageData];
  
  return image;
}

-(BOOL)deleteFile:(ICatchFile *)f
{
  int ret = -1;
  if (!f) {
    AppLog(@"Invalid ICatchFile pointer used for delete.");
    return NO;
  }
  switch (f->getFileType()) {
    case TYPE_IMAGE:
      ret = _playback->deleteFile(f);
      break;
      
    case TYPE_VIDEO:
      ret = _playback->deleteFile(f);
      break;
      
    case TYPE_AUDIO:
    case TYPE_TEXT:
    case TYPE_ALL:
    case TYPE_UNKNOWN:
    default:
      break;
  }
  
  if (ret != ICH_SUCCEED) {
    AppLog(@"Delete failed.");
    return NO;
  } else {
    return YES;
  }
}

-(void)cleanTemp
{
  NSArray *tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
  for (NSString *file in  tmpDirectoryContents) {
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:nil];
  }
}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo;
{
  if (error) {
    AppLog("Error: %@", [error userInfo]);
  } else {
    AppLog(@"image Saved");
  }
}

- (void)               video: (NSString *) videoPath
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo;
{
  
  if (error) {
    AppLog("Error: %@", [error userInfo]);
  } else {
    AppLog(@"video Saved");
  }
}

- (void)cancelDownload
{
    if (_playback) {
        _playback->cancelFileDownload();
        AppLog(@"Downloading Canceled");
    } else {
        AppLog(@"Downloading failed to cancel.");
    }

}

- (NSString *)p_downloadFile:(ICatchFile *)f {
  NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
  NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
  int ret = _playback->downloadFile(f, [locatePath cStringUsingEncoding:NSUTF8StringEncoding]);
  AppLog(@"Download File, ret : %d", ret);
  if (ret != ICH_SUCCEED) {
    locatePath = nil;
  } else {
    AppLog(@"locatePath: %@", locatePath);
  }
  
  return locatePath;
}

-(BOOL)downloadFile:(ICatchFile *)f
{
  BOOL ret = NO;
  NSString *locatePath = nil;
  switch (f->getFileType()) {
    case TYPE_IMAGE:
      locatePath = [self p_downloadFile:f];
      if (locatePath) {
        UIImage *image = [UIImage imageWithContentsOfFile:locatePath];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        ++self.downloadedTotalNumber;
        ret = YES;
      }
      break;
      
    case TYPE_VIDEO:
      // locatePath:
      //  /private/var/mobile/Applications/973FF993-84F4-44BB-BC96-2F6F52EDB5A0/tmp/20120601_001121.MOV
      //  /private/var/mobile/Applications/973FF993-84F4-44BB-BC96-2F6F52EDB5A0/tmp/20120601_001121.MOV
      locatePath = [self p_downloadFile:f];
      if (!UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
        AppLog(@"The specified video can not be saved to user’s Camera Roll album");
      }
      if (locatePath && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(locatePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        ++self.downloadedTotalNumber;
        ret = YES;
      }
      break;
      
    case TYPE_AUDIO:
    case TYPE_TEXT:
    case TYPE_ALL:
    case TYPE_UNKNOWN:
    default:
      break;
  }

  return ret;
}

#pragma mark - Video PB
- (BOOL)videoPlaybackEnabled
{
  return _control->supportVideoPlayback() == true ? YES : NO;
}

- (double)play:(ICatchFile *)file; {
  double videoFileTotalSecs = 0;
  AppLog(@"start call play");
  int ret = _vplayback->play(*file);
  AppLog(@"play return");
  if (ret != ICH_SUCCEED) {
    AppLog(@"play failed.");
    return 0;
  }
  
  // Get info after playback started
  _vplayback->getLength(videoFileTotalSecs);
  
  return videoFileTotalSecs;
}

- (void)pause {
  if (_vplayback != NULL) {
    _vplayback->pause();
    AppLog(@"pause");
  }
}

- (void)resume {
  if (_vplayback != NULL) {
    _vplayback->resume();
    AppLog(@"resume");
  }
}

- (void)stop {
  if (_vplayback != NULL) {
    _vplayback->stop();
    AppLog(@"stop");
  }
}

- (void)seek:(double)point {
  if (_vplayback != NULL) {
    _vplayback->seek(point);
    AppLog(@"seek");
  }
}


#pragma mark - Customize properties
//------------------- modify by allen.chuang 20140703 -----------------
/*
 guo.jiang[20140918]
 
 */
// support customer property code
-(int)getCustomizePropertyIntValue:(int)propid {
  unsigned int value;
  _prop->getCurrentPropertyValue(propid, value);
  printf("property int value: %d\n", value);
  return value;
}

-(NSString *)getCustomizePropertyStringValue:(int)propid {
  string value;
  _prop->getCurrentPropertyValue(propid, value);
  printf("property string value: %s\n", value.c_str());
  return [NSString stringWithFormat:@"%s", value.c_str()];
}

-(BOOL)setCustomizeIntProperty:(int)propid value:(uint)value {
  int ret = _prop->setPropertyValue(propid, value);
  AppLog(@"setProperty id:%d, value:%d",propid,value);
  return ret == ICH_SUCCEED ? YES : NO;
}

-(BOOL)setCustomizeStringProperty:(int)propid value:(NSString *)value {
  string stringValue = [value cStringUsingEncoding:NSUTF8StringEncoding];
  printf("set customized string property to : %s\n", stringValue.c_str());
  int ret = _prop->setPropertyValue(propid, stringValue);
  AppLog(@"setProperty id:%d, value:%@, ret : %d",propid,value, ret);
  return ret == ICH_SUCCEED ? YES : NO;
}

// check the customerid is valid or not
-(BOOL)isValidCustomerID:(int)customerid {
  int retid = [self getCustomizePropertyIntValue:0xD613];
  return retid  == customerid ? YES : NO;
}
#pragma mark - READONLY

-(uint)previewCacheTime {
    if (!_prop) {
        AppLog(@"SDK isn't working");
    }
    uint cacheTime = 0;
    _prop->getPreviewCacheTime(cacheTime);
    return cacheTime;
}

-(ICatchAudioFormat)getAudioFormat {
    ICatchAudioFormat format;
    if (_preview) {
        _preview->getAudioFormat(format);
    } else {
        AppLog(@"SDK doesn't work!!!");
    }
    
    return format;
}
-(ICatchAudioFormat)getPlaybackAudioFormat {
    ICatchAudioFormat format;
    if (_vplayback) {
        _vplayback->getAudioFormat(format);
    } else {
        AppLog(@"SDK doesn't work!!!");
    }
    
    return format;
}

@end
