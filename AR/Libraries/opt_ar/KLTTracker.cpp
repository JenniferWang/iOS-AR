#include "opt_conf.h"
#include "KLTTracker.h"

using namespace cv;

namespace opt_ar
{

KLTTracker::KLTTracker(int max_points, cv::Size win_size) {
    max_points_ = max_points;
    win_size_ = win_size;
    term_crit_ = cv::TermCriteria(CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, 0.01);
}

// Initialize your tracking subsystem using the provided frame.
// If the provided keypoints array is empty, detect them using a corner detector.
// Otherwise, use the provided points to initialize your tracker.
// Note that this function may be called multiple times to restart tracking.
// Make sure you reset all necessary internal state!
void KLTTracker::initialize(const GrayscaleImage& frame, const PointArray& keypoints) {
    
    pre_points_.clear();
    if(keypoints.empty()) {
        
        double qualityLevel = 0.01; //0.01
        double minDistance = 5; //10
        int blockSize = 3;
        bool useHarrisDetector = false;
        double k = 0.04;

        goodFeaturesToTrack(frame,
                            pre_points_,
                            max_points_,
                            qualityLevel,
                            minDistance,
                            Mat(),
                            blockSize,
                            useHarrisDetector,
                            k );
        
        // Optional: use cornerSubPix to refine your corners.
        /// Set the neeed parameters to find the refined corners
//        cv::Size winSize = cv::Size(3, 3);
//        cv::Size zeroZone = cv::Size(-1, -1);
//        TermCriteria criteria = TermCriteria( CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 40, 0.001 );
//        
//        cornerSubPix( frame, pre_points_, winSize, zeroZone, criteria );
    }
    else {
        pre_points_ = keypoints;
    }
    frame.copyTo(pre_frame_);
    
}

void KLTTracker::track(const GrayscaleImage& frame, MatchHandler& match_handler) {
    
    int track_threshold = 50;
    int pyramidLevel = 5;
    
    PointArray tracked_points, pruned_tracked_ponits, pruned_prev_points;
    std::vector<unsigned char> status;
    std::vector<float> err;
    calcOpticalFlowPyrLK(pre_frame_, frame, pre_points_, tracked_points, status, err,
                         win_size_, pyramidLevel, term_crit_);
    
    if (sum(status)[0] > track_threshold) {
        for (int i = 0; i < status.size(); i++) {
            if (status[i]) {
                pruned_tracked_ponits.push_back(tracked_points[i]);
                pruned_prev_points.push_back(pre_points_[i]);
            }
        }
        
    }

    match_handler(pruned_prev_points, pruned_tracked_ponits);
    
    pre_points_ = pruned_tracked_ponits;
    
    frame.copyTo(pre_frame_);
}


}