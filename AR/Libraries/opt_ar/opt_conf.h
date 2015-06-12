//
//  opt_conf.h
//  AR
//
//  Created by Jiyue Wang on 6/5/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#ifndef __OpticalFlow__conf_h
#define __OpticalFlow__conf_h

#define CV_TERMCRIT_ITER    1
#define CV_TERMCRIT_EPS     2

#define OPT_AR_CONF_PROJMAT_NEAR_PLANE  0.01f   // opengl projection matrix near plane
#define OPT_AR_CONF_PROJMAT_FAR_PLANE   100.0f  // opengl projection matrix far plane

#define OPT_AR_CONF_SMOOTHING_HIST_SIZE 5

#define OPT_AR_CONF_DEFAULT_MARKER_SIZE_REAL    0.05f   // "real world" marker size in meters
#endif
