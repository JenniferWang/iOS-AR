/**
 * Based on OcvARBasicNativeCam - Basic ocv_ar example for iOS with native camera usage
 * by  Markus Konrad <konrad@htw-berlin.de>, June 2014,
 * INKA Research Group, HTW Berlin - http://inka.htw-berlin.de/
 * BSD licensed (see LICENSE file).
 * gl view - implementation file.
 *
 * Main view controller - header file.
 *
 * Modified by Jiyue Wang
 */

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#include "ocv_ar.h"
#include "opt_ar.h"

#import "CamView.h"
#import "GLView.h"

// change to following lines to adjust to your setting:

#define MARKER_REAL_SIZE_M  0.042f
#define CAM_SESSION_PRESET  AVCaptureSessionPresetHigh
#define USE_DIST_COEFF      NO
#define PROJ_FLIP_MODE      ocv_ar::FLIP_H

/**
 * Main view controller.
 * Handles UI initialization and interactions. Handles camera frame input.
 */
@interface GameViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    NSString *camIntrinsicsFile;                // camera intrinsics file to use
    AVCaptureSession *camSession;               // controlls the camera session
    AVCaptureDeviceInput *camDeviceInput;       // input device: camera
    AVCaptureVideoDataOutput *vidDataOutput;    // controlls the video output
    
    cv::Mat curFrame;           // currently grabbed camera frame (grayscale)
    cv::Mat *dispFrame;         // frame to display. is NULL when the "normal" camera preview is displayed
    
    UIView *baseView;           // root view
    UIImageView *procFrameView; // view for processed frames
    CamView *camView;           // shows the grabbed video frames ("camera preview")
    
    ocv_ar::Detect *detector;   // ocv_ar::Detector for marker detection
    ocv_ar::Track *tracker;     // ocv_ar::Track for marker tracking and motion interpolation
    
    //opt_ar::ORBTracker *orbTracker;
    
    BOOL useDistCoeff;      // use distortion coefficients in camera intrinsics?
    BOOL isMultiMode;
    BOOL isGameRunning;
    BOOL isHost;
    
    float r;
    float g;
    float b;
}

@property (nonatomic, readonly) GLView *glView;  // gl view displays the highlighted markers

-(void)setMultiMode;
-(void)setSingleMode;
-(void)startGame;

@end
