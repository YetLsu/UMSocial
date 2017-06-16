//
//  VideoPlaybackProgressView.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-4-11.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackProgressView.h"

@implementation VideoPlaybackProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{

}
*/

-(CGRect)trackRectForBounds:(CGRect)bounds
{
  CGRect result = [super trackRectForBounds:bounds];
  result.size.height = 11.0;
  return result;
}

@end
