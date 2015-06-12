//
//  Tracker.h
//  AR
//
//  Created by Jiyue Wang on 6/11/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//
#include "opt_ar.h"

#import <Foundation/Foundation.h>
@protocol TrackerProtocol<NSObject>

- (void)setCamMat:(cv::Mat&)cam DistCoeff:(cv::Mat&)distCoeff;

- (void)detectFrame: (const cv::Mat *)frame;
- (void)updateFrame;

- (const float *)getMarkerPoseMatPtr;
- (BOOL)isLost;
- (float)getMarkerScale;
- (float *)getProjMatWithViewW: (float)w ViewH: (float)h;


@end

@interface Tracker : NSObject<TrackerProtocol> {
    opt_ar::PlaneTracker* planeTracker;
    
}

- (id)initWithRefImg:(const opt_ar::ColorImage&)refImg;

- (cv::Mat *)getOutputFrame; // debugging

@end
