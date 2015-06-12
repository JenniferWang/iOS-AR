#include "PlaneTracker.h"
#include "Tools.h"
#include "opencv2/core/core.hpp"
#include "opencv2/features2d.hpp"
#include <iostream>

using namespace cv;

namespace opt_ar
{

    static const char* TAG = "PlaneTracker";

#pragma mark - init/delloc
    void PlaneTracker::initialize(const ColorImage &frame) {
        int max_points = 8000;
        cv::Size win_size = cv::Size(5, 5);

        refFrame = new Mat();
        if(!refFrame) {
            printf("%s: reference frame cannot be initiallized\n", TAG);
            exit(EXIT_FAILURE);
        }
        cv::cvtColor(frame, *refFrame, cv::COLOR_RGBA2GRAY);
        
        kltTracker = KLTTracker(max_points, win_size);
        kltTracker.initialize(*refFrame);
        orbTracker.initialize(*refFrame);
        
        inputFrameW = frame.cols;
        inputFrameH = frame.rows;
        
        procFrame = new Mat(inputFrameW, inputFrameW, CV_8UC1);
        outFrame = new Mat(inputFrameW, inputFrameW, CV_8UC1);
        inFrameOrigGray = new Mat(inputFrameW, inputFrameW, CV_8UC1);
        
        if (!procFrame || !outFrame || !inFrameOrigGray) {
            printf("%s: proc/out/inFrame cannot be initiallized\n", TAG);
            exit(EXIT_FAILURE);
        }
        
        calcFrameBounds(inputFrameH, inputFrameW);
        internalH = Homography(1, 0, 0,
                               0, 1, 0,
                               0, 0, 1);
        
        foundMarker = new ImgMarker(frameBounds);
        isLost = true;
        
        markerScale = OPT_AR_CONF_DEFAULT_MARKER_SIZE_REAL;
        printf("%s: initialization finished", TAG);
    }

    PlaneTracker::~PlaneTracker() {
        if (refFrame) delete refFrame;
        if (procFrame) delete procFrame;
        if (outFrame) delete outFrame;
        if (inFrameOrigGray) delete inFrameOrigGray;
        if (foundMarker) delete foundMarker;
        
    }
    
#pragma mark - public methods
    // Implement the tracking logic as described on the project page.
    // Your implementation should follow the logic described in the flowchart.
    bool PlaneTracker::track()
    {
        bool estimation_successful = false;
        MatchHandler match_handler = [&](const PointArray& src_points, const PointArray& dst_points) {
            assert(src_points.size() == dst_points.size());
            if(dst_points.size()>=4) {
                estimation_successful = this->estimateHomography(src_points, dst_points, currentH);
            }
            else {
                std::cout << "Tracker provided less than 4 correspondences for homography estimation!" << std::endl;
            }
        };
        
        if (!isLost) {
            kltTracker.track(*inFrameOrigGray, match_handler);
        }
        
        if (!estimation_successful || isLost) {
            internalH = Homography(1, 0, 0,
                                   0, 1, 0,
                                   0, 0, 1);
            orbTracker.track(*inFrameOrigGray, match_handler);
            if (estimation_successful) {
                kltTracker.initialize(*inFrameOrigGray, ransacInliers);
                isLost = false;
            }
            else {
                isLost = true;
                
            }
        }
        
        if (!isLost) {
            foundMarker->updatePoints(internalH);
            estimateMarkerPoses();
        }
        return estimation_successful;
    }

    void PlaneTracker::setCamIntrinsics(const cv::Mat &cam, const cv::Mat &dist) {
        camIntrinsics = cam;
        distCoeff = dist;   // this mat can also be empty
    }
    
    float *PlaneTracker::getProjMat(float viewW, float viewH) {
        
        assert(!camIntrinsics.empty() && viewH > 0.0f && viewW > 0.0f);
        
        if (viewW != projMatUsedSize.width || viewH != projMatUsedSize.height) {
            calcProjMat(viewW, viewH);
        }
        return projMat;
    }
    
    void PlaneTracker::setFrameOutputLevel(FrameProcLevel level) {
        if (outFrameProcLvl == level) return;
        
        outFrameProcLvl = level;
        //TODO
    }
    
    void PlaneTracker::setInputFrame(const ColorImage &frame) {
        cv::cvtColor(frame, *inFrameOrigGray, cv::COLOR_RGB2GRAY);
        //TODO
    }
    
    const float* PlaneTracker::getMarkerPoseMatPtr(){
        if(isLost) return NULL;
        return foundMarker->getPoseMatPtr();
    }
    
    void PlaneTracker::estimateMarkerPoses() {
        
        if (foundMarker != NULL) {
            // find marker pose from 3D-2D point correspondences between <normMarkerCoord3D>
            // and 2D points in <marker->getPoints()>
            cv::Mat rVec;   // pose rotation vector
            cv::Mat tVec;   // pose translation vector
            cv::solvePnP(normMarkerCoord3D, foundMarker->getPoints(),
                         camIntrinsics, distCoeff,
                         rVec, tVec,
                         false);
            
            // generate an OpenGL model-view matrix from the rotation and translation vectors
            foundMarker->updatePoseMat(rVec, tVec);
        }
    }
    
    Mat* PlaneTracker::getOutputFrame() const{
        if (outFrameProcLvl == PROC_LEVEL_DEFAULT) return NULL;
        return outFrame;
    }
    
    
#pragma mark - private methods
    void PlaneTracker::calcFrameBounds(int inputFrameH, int inputFrameW) {
        //TODO: should be anti-clockwise
        frameBounds.clear();
        frameBounds.push_back(Point2f(0, 0));
        frameBounds.push_back(Point2f(inputFrameH, 0));
        frameBounds.push_back(Point2f(inputFrameH, inputFrameW));
        frameBounds.push_back(Point2f(0, inputFrameW));

    }
    
    void PlaneTracker::setOutputFrameOnCurProcLevel(FrameProcLevel curLvl, cv::Mat *srcFrame) {
        assert(srcFrame);
        if (curLvl == outFrameProcLvl) {
            srcFrame->copyTo(*outFrame);
        }
    }
    
    void PlaneTracker::drawMarker(cv::Mat &img, const ImgMarker &m) {
        
        Point2fVec mCorners = m.getPoints();
        cv::line(img, mCorners[0], mCorners[1], cv::Scalar(0, 255, 0), 2);
        cv::line(img, mCorners[1], mCorners[2], cv::Scalar(0, 255, 0), 2);
        cv::line(img, mCorners[2], mCorners[3], cv::Scalar(0, 255, 0), 2);
        cv::line(img, mCorners[3], mCorners[0], cv::Scalar(0, 255, 0), 2);
    }
    
    void PlaneTracker::calcProjMat(float viewW, float viewH) {
        
        printf("opt_ar::Detect - calculating projection matrix for view size %dx%d\n",
               (int)viewW, (int)viewH);
        
        const float projNear = OPT_AR_CONF_PROJMAT_NEAR_PLANE;
        const float projFar  = OPT_AR_CONF_PROJMAT_FAR_PLANE;
        
        projMatUsedSize = cv::Size(viewW, viewH);
        
        // intrinsics mat contains doubles. we need floats
        cv::Mat intrFloats(3, 3, CV_32F);
        camIntrinsics.convertTo(intrFloats, CV_32F);
        
        // get cam parameters
        /* BEGIN modified code from ArUco lib */
        const float Ax = viewW;
        const float Ay = viewH;
        const float f_x = intrFloats.at<float>(0, 0) * Ax;	// Focal length in x axis
        const float f_y = intrFloats.at<float>(1, 1) * Ay;	// Focal length in y axis
        const float c_x = intrFloats.at<float>(0, 2) * Ax; 	// Camera primary point x
        const float c_y = intrFloats.at<float>(1, 2) * Ay;	// Camera primary point y
        
        float cparam[3][4] =
        {
            {f_x,   0,  c_x, 0},
            {  0, f_y,  c_y, 0},
            {  0,   0,    1, 0}
        };
        
        cparam[0][2] *= -1.0;
        cparam[1][2] *= -1.0;
        cparam[2][2] *= -1.0;
        
        float   icpara[3][4];
        float   trans[3][4];
        float   p[3][3], q[4][4];
        
        Tools::arParamDecompMat(cparam, icpara, trans);
        
        for (int i = 0; i < 3; i++ )
        {
            for (int j = 0; j < 3; j++ )
            {
                p[i][j] = icpara[i][j] / icpara[2][2];
            }
        }
        
        q[0][0] = (2.0 * p[0][0] / viewW);
        q[0][1] = (2.0 * p[0][1] / viewW);
        q[0][2] = ((2.0 * p[0][2] / viewW)  - 1.0);
        q[0][3] = 0.0;
        
        q[1][0] = 0.0;
        q[1][1] = (2.0 * p[1][1] / viewH);
        q[1][2] = ((2.0 * p[1][2] / viewH) - 1.0);
        q[1][3] = 0.0;
        
        q[2][0] = 0.0;
        q[2][1] = 0.0;
        q[2][2] = (projFar + projNear)/(projFar - projNear);
        q[2][3] = -2.0 * projFar * projNear / (projFar - projNear);
        
        q[3][0] = 0.0;
        q[3][1] = 0.0;
        q[3][2] = 1.0;
        q[3][3] = 0.0;
        
        for (int i = 0; i < 4; i++ )
        {
            for (int j = 0; j < 3; j++ )
            {
                projMat[i+j*4] = q[i][0] * trans[0][j]
                + q[i][1] * trans[1][j]
                + q[i][2] * trans[2][j];
            }
            projMat[i+3*4] = q[i][0] * trans[0][3]
            + q[i][1] * trans[1][3]
            + q[i][2] * trans[2][3]
            + q[i][3];
        }
        
//        if (flipProj == FLIP_H) {
//            projMat[1]  = -projMat[1];
//            projMat[5]  = -projMat[5];
//            projMat[9]  = -projMat[9];
//            projMat[13] = -projMat[13];
//        } else if (flipProj == FLIP_V) {
//            projMat[0] = -projMat[0];
//            projMat[4]  = -projMat[4];
//            projMat[8]  = -projMat[8];
//            projMat[12]  = -projMat[12];
//        }
        
        /* END modified code from ArUco lib */
    }
    
    // Given a set of correspondences, compute the homography using RANSAC.
    // Compute the inlier ratio (number of RANSAC inliers/number of correspondences),
    // and return true if it's above a certain threshold. Otherwise, return false.
    // Use the test videos to determine a reasonable threshold.
    bool PlaneTracker::estimateHomography(const PointArray& src_points, const PointArray& dst_points, Homography& H) {
        
        assert(src_points.size() == dst_points.size());
        
        float inlier_ratio = 0.6; //TODO //0.6
        int ransac_threshold = 8; // 2
        
        ransacInliers.clear();
        cv::Mat mask;
        H = cv::findHomography(src_points, dst_points, cv::FM_RANSAC, ransac_threshold, mask);
        
            std::cout << "there are "<< cv::sum(mask)[0] << "inliers" << std::endl;
            std::cout << "there are "<< mask.size() << " in total" << std::endl;
        
        if (cv::sum(mask)[0]/src_points.size() < inlier_ratio) {
            std::cout << "not enough inlier" << std::endl;
            return false;
        }
        
        for (int i = 0; i < src_points.size(); i++) {
            if (mask.at<uchar>(0, i)) {
                ransacInliers.push_back(src_points[i]);
            }
        }
        
        internalH = H * internalH ;
        H = internalH;
        return true;
    }


} 