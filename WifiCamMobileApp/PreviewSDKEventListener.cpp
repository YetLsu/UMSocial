//
//  PreviewSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#include "PreviewSDKEventListener.h"


void PreviewSDKEventListener::eventNotify(ICatchEvent *icatchEvt) {}

PreviewSDKEventListener::PreviewSDKEventListener(ViewController *controller) {
  this->controller = controller;
}

PreviewSDKEventListener::PreviewSDKEventListener(StartViewController *startController) {
  this->startController = startController;
}

void PreviewSDKEventListener::showReconnectAlert(ICatchEvent *iCatchEvt) {
  [controller showReconnectAlert];
}
void PreviewSDKEventListener::updateMovieRecState(ICatchEvent *iCatchEvt, MovieRecState state) {
  [controller updateMovieRecState:state];
}
void PreviewSDKEventListener::updateBatteryLevel(ICatchEvent *iCatchEvt) {
  [controller updateBatteryLevel];
}
void PreviewSDKEventListener::stopStillCapture(ICatchEvent *icatchEvt) {
  [controller stopStillCapture];
}

void PreviewSDKEventListener::stopTimelapse(ICatchEvent *icatchEvt) {
  [controller stopTimelapse];
}

void PreviewSDKEventListener::timelapseStartedNotice(ICatchEvent *icatchEvt) {
  [controller timelapseStartedNotice];
}

void PreviewSDKEventListener::timelapseCompletedNotice(ICatchEvent *icatchEvt) {
  [controller timelapseCompletedNotice];
}

void PreviewSDKEventListener::postMovieRecordTime(ICatchEvent *icatchEvt) {
  [controller postMovieRecordTime];
}

void PreviewSDKEventListener::postMovieRecordFileAddedEvent(ICatchEvent *icatchEvt) {
  [controller postMovieRecordFileAddedEvent];
}