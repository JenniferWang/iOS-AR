/**
 * Based on OcvARBasicNativeCam - Basic ocv_ar example for iOS with native camera usage 
 * by  Markus Konrad <konrad@htw-berlin.de>, June 2014, 
 * INKA Research Group, HTW Berlin - http://inka.htw-berlin.de/
 * BSD licensed (see LICENSE file).
 *
 * gl view - header file.
 *
 * Modified by Jiyue Wang
 */

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Tracker.h"

#include "helper/shader.h"

using namespace cv;
using namespace std;

/**
 * GLView highlights the found markers according to their estimated 3D pose.
 * It sits above the camera frame view and is not opaque.
 */
@interface GLView : GLKView {
    BOOL glInitialized;
    
    Shader markerDispShader;    // marker display shader
    
    GLint shAttrPos;            // shader attribute: vertex data
    
    GLint shMarkerProjMat;      // shader uniform: projection matrix
    GLint shMarkerModelViewMat; // shader uniform: model-view matrix
    GLint shMarkerTransformMat; // shader uniform: transform matrix
    GLint shMarkerColor;        // shader uniform: marker color
    
    CGSize viewportSize;        // real gl viewport size in pixels
    
    GLfloat markerScaleMat[16]; // global marker transform (scale) matrix
    
    GLfloat color[3];
    GLKMatrix4 markerModelViewMat;
    GLKMatrix4 markerProjectionMat; // kind of duplicate of markerProjMat

}

@property (nonatomic, assign) Tracker *tracker;   // tracker object that handles marker tracking and motion interpolation
@property (nonatomic, assign) float *markerProjMat;     // 4x4 projection matrix
@property (nonatomic, assign) float markerScale;        // marker scaling
@property (nonatomic, assign) BOOL showMarkers;         // enable/disable marker display

/**
 * set a marker scale <s> (real marker side length in meters)
 * overwrite 'assign' method
 */
- (void)setMarkerScale:(float)s;

/**
 * Resize the gl view and adjust gl properties
 */
- (void)resizeView:(CGSize)size;

/**
 * redraw the frame (will just call [self display])
 */
- (void)render:(CADisplayLink *)displayLink;

//- (void)handleTapAtX:(float) x Y:(float) y;

// now only support one object
- (BOOL)intersectAtX:(float)x Y:(float)y;

- (void)handleColorVectorX:(float)colorX Y:(float)colorY Z:(float)colorZ;


@end