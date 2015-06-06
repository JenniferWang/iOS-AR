#ifndef __OpticalFlow__CornerDetection__
#define __OpticalFlow__CornerDetection__

#include "Common.h"

namespace opt_ar
{

typedef std::function<void(const GrayscaleImage&, cv::Mat&, int)> HarrisCornerDetector;

void DetectGoodFeaturesToTrack(const GrayscaleImage& image,
                               PointArray& _corners,
                               int maxCorners,
                               double qualityLevel,
                               double minDistance,
                               int blockSize,
                               HarrisCornerDetector harrisCornerDetector);
}

#endif /* defined(__Artsy__CornerDetection__) */
