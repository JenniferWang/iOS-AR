//
//  ImgMarker.cpp
//  AR
//
//  Created by Jiyue Wang on 6/5/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#include "ImgMarker.h"
#include "Tools.h"

namespace opt_ar{
    
#pragma mark public methods
    
    /*
    ImgMarker::ImgMarker(PointVec &pts){
        for (int i = 0; i < 4; i++) {
            points.push_back(cv::Point2f(pts[i].x, pts[i].y));
        }
        
        init();
    }
    */
    ImgMarker::ImgMarker(Point2fVec &bds) {
        points.assign(bds.begin(), bds.begin() + 4);
        bounds.assign(bds.begin(), bds.begin() + 4);
        init();
    }
    
    ImgMarker::ImgMarker(Point2fVec &pts, Point2fVec &bds) {
        points.assign(pts.begin(), pts.begin() + 4);
        bounds.assign(bds.begin(), bds.begin() + 4);
        init();
    }
    
    ImgMarker::ImgMarker(const ImgMarker &other) {
        setPoints(other.getPoints());
        init();
        
        rVec = other.getRVec().clone();
        tVec = other.getTVec().clone();
            //    updatePoseMat(other.getRVec(), other.getTVec());
 
    }
    
    ImgMarker::~ImgMarker() {
        printf("opt_ar::Marker (%p) - deconstructor call\n", this);
    }
    
    void ImgMarker::updateDetectionTime() {
        detectMs = Tools::nowMs();
    }
    
    void ImgMarker::updateForTracking(const ImgMarker &other) {
        
        // copy the vertex points
        setPoints(other.getPoints());
        
        const cv::Mat r = other.getRVec().clone();
        const cv::Mat t = other.getTVec().clone();
        
        if (!r.data || !t.data) return;
        
        // r and t are double vectors from solvePnP
        // convert them to floats and save them as member
        // variables <rVec> and <tVec>
        r.convertTo(rVec, CV_32F);
        t.convertTo(tVec, CV_32F);
        
        // re-calculate the pose matrix from <rVec> and <tVec>
        calcPoseMat();
    }
    
    void ImgMarker::updatePoseMat(const cv::Mat &r, const cv::Mat &t) {
        if (!r.data || !t.data) return;
        
        // r and t are double vectors from solvePnP
        // convert them to floats and save them as member
        // variables <rVec> and <tVec>
        r.convertTo(rVec, CV_32F);
        t.convertTo(tVec, CV_32F);
        
        // re-calculate the pose matrix from <rVec> and <tVec>
        calcPoseMat();
        
    }
    
    void ImgMarker::updatePoints(const Homography &H) {
        
        //points = cv::multiply(points, H, points);
        perspectiveTransform(bounds, points, H);
    }
    
#pragma mark private methods
    void ImgMarker::init() {
        // set defaults
        rVec.zeros(3, 1, CV_32F);
        tVec.zeros(3, 1, CV_32F);
    
        sortPoints();
        calcShapeProperties();
        updateDetectionTime();  // set to now
        
    }
    
    void ImgMarker::sortPoints() {
       	// Sort the points in anti-clockwise order
        cv::Point v1 = points[1] - points[0];
        cv::Point v2 = points[2] - points[0];
        
        // if the third point is in the left side,
        // sort in anti-clockwise order
        if ((v1.x * v2.y) - (v1.y * v2.x) < 0.0) {
            swap(points[1], points[3]);
        }
    }
    
    void ImgMarker::calcShapeProperties() {
        // centroid is the mean of all points
        centroid = 0.25f * (points[0] + points[1] + points[2] + points[3]);
        
        // perimeter radius is the maximum distance between the centroid
        // and a corner point
        float maxDist = std::numeric_limits<float>::min();
        for (Point2fVec::iterator it = points.begin();
             it != points.end();
             ++it) {
            float d = cv::norm(centroid - *it);
            maxDist = cv::max(maxDist, d);
        }
        
        perimeterRad = maxDist;
        
    }
    
    void ImgMarker::calcPoseMat(){
        // create rotation matrix
        cv::Mat rotMat(3, 3, CV_32FC1);
        cv::Rodrigues(rVec, rotMat);
        
        /* BEGIN modified code from ArUco lib */
        float para[3][4];
        for (int i=0; i < 3; i++) {
            float *rotMatRow = rotMat.ptr<float>(i);
            for (int j = 0; j < 3; j++) {
                para[i][j] = rotMatRow[j];
            }
        }
        //now, add the translation
        float *tVecData = tVec.ptr<float>(0);
        para[0][3] = tVecData[0];
        para[1][3] = tVecData[1];
        para[2][3] = tVecData[2];
        
        // create and init modelview_matrix
        memset(poseMat, 0, 16 * sizeof(float));	// init with zeros
        
        for (int i = 0; i < 3; i++) {
            float sign = (i != 2) ? 1.0f : -1.0f;
            for (int j = 0; j < 4; j++) {
                poseMat[i + j * 4] = sign * para[i][j];
            }
        }
        
        poseMat[15] = 1.0f;
        /* END modified code from ArUco lib */
    }
}