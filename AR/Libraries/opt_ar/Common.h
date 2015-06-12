#ifndef  __OpticalFlow__Common_h
#define  __OpticalFlow__Common_h

#include "opt_conf.h"
#include <opencv2/opencv.hpp>
#include <cassert>
#include <functional>
#include <memory>

namespace opt_ar
{

    typedef cv::Matx33f Homography;

    typedef cv::Mat ColorImage;
    
    typedef cv::Mat GrayscaleImage;
    
    typedef std::vector<cv::Point2f> PointArray;
    
    typedef std::function<void(const PointArray&, const PointArray&)> MatchHandler;
    
    
    typedef enum _FrameProcLevel {
        PROC_LEVEL_DEFAULT = -1,
        PROC_LEVEL_DETECTED_MARKERS
    } FrameProcLevel;
    
    typedef std::vector<cv::Point> PointVec;
    typedef std::vector<cv::Point2f> Point2fVec;
    typedef std::vector<cv::Point3f> Point3fVec;

}

#endif
