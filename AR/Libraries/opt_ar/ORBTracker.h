#ifndef __OpticalFlow__ORBTracker__
#define __OpticalFlow__ORBTracker__

#include "Common.h"

namespace opt_ar
{

class ORBTracker
{
public:

    ORBTracker();

    virtual ~ORBTracker() = default;

    void initialize(const GrayscaleImage& frame);

    void track(const GrayscaleImage& frame, MatchHandler& match_handler);

private:
    GrayscaleImage ref_frame_;
    
    std::vector<cv::KeyPoint> ref_keyptrs_;
    
    cv::Mat ref_dscrptr_;
    cv::Ptr<cv::ORB> detector;
};

}

#endif /* defined(__Artsy__ORBTracker__) */
