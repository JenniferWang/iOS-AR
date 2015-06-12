#ifndef __OpticalFlow__PlaneTracker__
#define __OpticalFlow__PlaneTracker__

#include "Common.h"
#include "KLTTracker.h"
#include "ORBTracker.h"
#include "ImgMarker.h"

namespace opt_ar
{
    class PlaneTracker
    {
    public:
        
        PlaneTracker() = default;
        ~PlaneTracker();
        void initialize(const ColorImage& referFrame);
        
        void setInputFrame(const ColorImage &frame);
        void setCamIntrinsics(const cv::Mat &camMat, const cv::Mat &distCoeff);
        void setFrameOutputLevel(FrameProcLevel level);
        
        bool track();
        
        void estimateMarkerPoses();
        const float *getMarkerPoseMatPtr();
        
        
        /**
         * Get the output frame according to the "frame output level" set via
         * <setFrameOutputLevel()>. If this level is set to PROC_LEVEL_DEFAULT, it will
         * return NULL, otherwise it will return a weak pointer.
         */
        cv::Mat *getOutputFrame() const;
        ImgMarker *getMarker() const {
            return isLost? NULL: foundMarker; }
        
        /**
         * Return a 4x4 OpenGL projection matrix that can be used to display the found
         * markers. The projection matrix will be calculated depending on the OpenGL view
         * size <viewW> x <viewH>.
         * A pointer to a float[16] array will be returned.
         */
        float *getProjMat(float viewW, float viewH);
        
        // Return the set real world marker size in meters.
        float getMarkerScale() const { return markerScale; }
        
    private:
        
        // Helper function to copy the image from <srcFrame> to <outFrame> if the
        // frame processing level <curLvl> matches.
        void setOutputFrameOnCurProcLevel(FrameProcLevel curLvl, cv::Mat *srcFrame);
        
        // Helper function to draw a marker <m> to the image <img>.
        void drawMarker(cv::Mat &img, const ImgMarker &m);
        
        // Calculates the OpenGL projection matrix for a view of size <viewW> x <viewH>.
        // See <getProjMat()>
        void calcProjMat(float viewW, float viewH);
        
        void calcFrameBounds(int inputFrameH, int inputFrameW);
        
        KLTTracker kltTracker;
        ORBTracker orbTracker;
        
        GrayscaleImage* refFrame;
        GrayscaleImage* procFrame;
        GrayscaleImage* outFrame;          // output frame for debugging, grayscale
        GrayscaleImage* inFrameOrigGray;
        
        FrameProcLevel outFrameProcLvl; // frame output processing level
        
        int inputFrameW;            // original input frame width
        int inputFrameH;            // original input frame height
        
        Point2fVec frameBounds;
        
        Homography internalH; // homography between ref and current
        Homography currentH; // homography between current and previous frame
        
        PointArray ransacInliers;
        
        ImgMarker *foundMarker;
        
        bool isLost;

        bool estimateHomography(const PointArray& src_points, const PointArray& dst_points, Homography& H);

        int normMarkerSize;
        Point2fVec normMarkerCoord2D;	// standard coordinates for a normalized rectangular marker in 2D
        Point3fVec normMarkerCoord3D;	// standard coordinates for a normalized rectangular marker in 3D
        
        cv::Mat camIntrinsics;             // cam intrinsics: camera matrix
        cv::Mat distCoeff;          // cam intrinsics: distortion coefficients (may be empty)
        
        float markerScale;          // real world marker size in meters
        
        float projMat[16];          // 4x4 OpenGL projection matrix
        cv::Size projMatUsedSize;   // the view size for which <projMat> was calculated
    };
}

#endif /* defined(__Artsy__PlaneTracker__) */
