//
//  Tracker.m
//  AR
//
//  Created by Jiyue Wang on 6/11/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import "Tracker.h"

using namespace opt_ar;

@implementation Tracker

#pragma mark alloc/dealloc
- (id)init {
    if (self = [super init]) {
        planeTracker = new PlaneTracker();
        if (!planeTracker)
            NSLog(@"Cannot create a plane tracker\n");
    }
    return self;
}

- (id)initWithRefImg:(const ColorImage&)refImg {
    if (self = [[Tracker alloc]init]) {
        planeTracker->initialize(refImg);
        
    }
    return self;
}

- (void)dealloc {
    
    if (planeTracker) delete(planeTracker);
    [super dealloc];
}

#pragma mark public methods

- (float)getMarkerScale {
    return planeTracker->getMarkerScale();
}

- (BOOL)isLost {
    return planeTracker->getMarker() == NULL ? YES:NO;
}

- (void)setCamMat:(cv::Mat&)cam DistCoeff:(cv::Mat&)distCoeff {
    
    planeTracker->setCamIntrinsics(cam, distCoeff);
    
}

- (void)detectFrame: (const cv::Mat *)frame {
    assert(frame);
    planeTracker->setInputFrame(*frame);
    planeTracker->track();
    //planeTracker->estimateMarkersPoses();
}

- (void)updateFrame {
    
    
}

- (cv::Mat *)getOutputFrame {
    return planeTracker->getOutputFrame();
    
}

- (const float *)getMarkerPoseMatPtr {
    return planeTracker->getMarkerPoseMatPtr();
}

- (float *)getProjMatWithViewW: (float)w ViewH: (float)h {
    return planeTracker->getProjMat(w, h);
}

#pragma mark private methods

@end
