//
//  ImgMarker.h
//  AR
//
//  Created by Jiyue Wang on 6/5/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#ifndef __OpticalFlow__ImgMarker__
#define __OpticalFlow__ImgMarker__

#include "Common.h"

namespace opt_ar{
    
class ImgMarker {
public:
    
    ImgMarker(PointVec &pts);
    
    ImgMarker(Point2fVec &pts);
    
    ~ImgMarker();
    
    // Updates <detectMs> to "now".
    void updateDetectionTime();
    
    //Return the timestamp for the last detection time in milliseconds.
    double getDetectionTimeMs() const { return detectMs; }
    
    // Return the corner points of this marker.
    Point2fVec getPoints() const { return points; }
    
    // Set the points in <pVec>.
    void setPoints(const Point2fVec &pVec) { points.assign(pVec.begin(), pVec.end()); }
    
    
    void clearPoints() { points.clear(); }
    
    cv::Point2f getCentroid() const { return centroid; }

    // Return the 3D pose rotation vector.
    const cv::Mat &getRVec() const { return rVec; };

    //Return the 3D pose translation vector.
    const cv::Mat &getTVec() const { return tVec; };
    
    // Update the 3D pose by rotation vector <r> and translation vector <t>.
    void updatePoseMat(const cv::Mat &r, const cv::Mat &t);
    
    /**
     * Update the 3D pose for tracking, which means the T and R vectors from
     * <other> will be copied and interpolated with previous T and R vectors
     * to achieve a smooth transition between marker poses.
     */
    void updateForTracking(const ImgMarker &other);
    
    /**
     * Return the 4x4 OpenGL 3D pose model-view matrix as pointer to
     * the internal float[16].
     */
    const float *getPoseMatPtr() const { return poseMat; };
    
private:
    
    void init();
    
    //Sort the points in anti-clockwise order.
    void sortPoints();
    
    // Calculate the shape properties from the corner points like centroid
    // and perimeter radius.
    void calcShapeProperties();
    
    // Update vector history arrays for smoothing (<tVecHist> and <rVecHist>) with
    // elements from <r> and <t> (3-component vectors each).
    void pushVecsToHistory(const float *r, const float *t);
    
    /**
     * Updates <r> and <t> with new values calulated by taking into account the former
     * pose vector values in <rVecHist> and <tVecHist>. <r> and <t> are 3-component
     * vectors each.
     */
    void calcSmoothPoseVecs(float *r, float *t);

    // Calculate the 3D pose matrix from translation and rotation vectors <rVec> and
    // <tVec>.
    void calcPoseMat();
    
    double detectMs;        // timestamp of last detection in milliseconds
    
    Point2fVec points;      // corner points
    
    cv::Point2f centroid;   // centroid formed by the corner points
    float perimeterRad;     // perimenter radius formed by the corner points
    
    cv::Mat rVec;           // 3D pose rotation vector
    cv::Mat tVec;           // 3D pose translation vector
    
    int pushedHistVecs;     // number of vectors in <tVecHist> and <rVecHist>
    
    float *tVecHist;        // marker position history with N * 3 elements for smoothing effect
    float *rVecHist;        // marker rotation history with N * 3 elements (euler vectors) for smoothing effect
    
    float poseMat[16];      // OpenGL 4x4 matrix with model-view-transformation
};
    
}

#endif
