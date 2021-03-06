/**
 * Based on OcvARBasicNativeCam - Basic ocv_ar example for iOS with native camera usage
 * by  Markus Konrad <konrad@htw-berlin.de>, June 2014,
 * INKA Research Group, HTW Berlin - http://inka.htw-berlin.de/
 * BSD licensed (see LICENSE file).
 * gl view - implementation file.
 * 
 * Main view controller - implementation file.
 *
 * Modified by Jiyue Wang
 *
 */

#import "GameViewController.h"
#import "AppDelegate.h"
#import "helper/Tools.h"
#import "Data.h"
#import <sys/utsname.h>

static NSString *TAG = @"GameViewController";

/**
 * Small helper function to convert a fourCC <code> to
 * a character string <fourCC> for printf and the like
 */
void fourCCStringFromCode(int code, char fourCC[5]) {
    for (int i = 0; i < 4; i++) {
        fourCC[3 - i] = code >> (i * 8);
    }
    fourCC[4] = '\0';
}

void printFloatMat4x4(const float *m) {
    for (int y = 0; y < 4; ++y) {
        for (int x = 0; x < 4; ++x) {
            printf("%f ", m[y * 4 + x]);
        }
        
        printf("\n");
    }
}

@interface GameViewController()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) UITapGestureRecognizer *gesture;

- (void)initCam;

- (BOOL)initDetector;

//- (BOOL)initORBTracker;

/**
 * Called on the first input frame and prepares everything for the specified
 * frame size and number of color channels
 */
- (void)prepareForFramesOfSize:(CGSize)size numChannels:(int)chan;

/**
 * resize the proc frame view to CGRect in <newFrameRect> and also
 * set the correct frame for the gl view
 */
- (void)setCorrectedFrameForViews:(NSValue *)newFrameRect;

/**
 * Notify the video session about the interface orientation change
 */
- (void)interfaceOrientationChanged:(UIInterfaceOrientation)o;

/**
 * handler that is called when a output selection button is pressed
 */
- (void)procOutputSelectBtnAction:(UIButton *)sender;

/**
 * force to redraw views. this method is only to display the intermediate
 * frame processing output for debugging
 */
- (void)updateViews;

- (void)handleGesture:(UITapGestureRecognizer *)sender;
@end


@implementation GameViewController

@synthesize glView;

#pragma mark - init/dealloc
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        camIntrinsicsFile = @"ipad3-back.xml";
        useDistCoeff = USE_DIST_COEFF;
        // create the detector
        detector = new ocv_ar::Detect(ocv_ar::IDENT_TYPE_CODE_7X7,  // marker type
                                      MARKER_REAL_SIZE_M,           // real marker size in meters
                                      PROJ_FLIP_MODE);              // projection flip mode
        // create the tracker and pass it a reference to the detector object
        tracker = new ocv_ar::Track(detector);
        
        isMultiMode = NO;
        isGameRunning = NO;
    }

    //NSLog(@"%@: initWithNibName finished", TAG);
    r = 0;
    return self;
}

- (void)dealloc {
    NSLog(@"%@: now dealloc ...", TAG);
    
    [camIntrinsicsFile release];
    [self.gesture release];
    
    // release camera stuff
    [vidDataOutput release];
    [camDeviceInput release];
    [camSession release];
    
    // release views
    [glView release];
    [camView release];
    [procFrameView release];
    [baseView release];
    
    // delete marker detection and tracking objects
    if (tracker) delete tracker;
    if (detector) delete detector;
    
    [super dealloc];
}

#pragma mark - parent methods
- (void)didReceiveMemoryWarning {
    NSLog(@"memory warning!!!");
    [super didReceiveMemoryWarning];
}

- (void)loadView {
    
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    NSLog(@"loading view of size %dx%d", (int)screenRect.size.width, (int)screenRect.size.height);
    
    // create an empty base view
    CGRect baseFrame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
    baseView = [[UIView alloc] initWithFrame:baseFrame];
    
    // create the image view for the camera frames
    CGRect camFrame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    camView = [[CamView alloc] initWithFrame:camFrame];
    [baseView addSubview:camView];
    
    // create view for processed frames
    procFrameView = [[UIImageView alloc] initWithFrame:camFrame];
    [procFrameView setHidden:YES];  // initially hidden
    [baseView addSubview:procFrameView];
    
    // create the GL view
    glView = [[GLView alloc] initWithFrame:baseView.frame];
    [glView setTracker:tracker];    // pass the tracker object
    [baseView addSubview:glView];
    
    // set a list of buttons for processing output display
    NSArray *btnTitles = [NSArray arrayWithObjects:
                          @"Normal",
                          @"Preproc",
                          @"Thresh",
                          @"Contours",
                          @"Candidates",
                          @"Detected",
                          nil];
    for (int btnIdx = 0; btnIdx < btnTitles.count; btnIdx++) {
        UIButton *procOutputSelectBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [procOutputSelectBtn setTag:btnIdx - 1];
        [procOutputSelectBtn setTitle:[btnTitles objectAtIndex:btnIdx]
                             forState:UIControlStateNormal];
        int btnW = 120;
        [procOutputSelectBtn setFrame:CGRectMake(10 + 2*(btnW + 20) * btnIdx / 3, 10, btnW, 35)];
        [procOutputSelectBtn setOpaque:YES];
        [procOutputSelectBtn addTarget:self
                                action:@selector(procOutputSelectBtnAction:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [baseView addSubview:procOutputSelectBtn];
    }
    
    // finally set the base view as view for this controller
    [self setView:baseView];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%@: view will appear - start camera session", TAG);
    
    [camSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"%@: view did disappear - stop camera session", TAG);
    
    [camSession stopRunning];
    [self viewDidLoad];
}

- (void)viewDidLoad {
    NSLog(@"%@: viewDidLoad ...", TAG);
    [super viewDidLoad];

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // init detector
    if ([self initDetector]) {
        NSLog(@"cam intrinsics loaded from file %@", camIntrinsicsFile);
    } else {
        NSLog(@"detector initialization failure");
    }
    
    // set the marker scale for the GL view
    [glView setMarkerScale:detector->getMarkerScale()];
    
    // set up camera
    [self initCam];
    
    // listen to the gesture
    self.gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    [baseView addGestureRecognizer:self.gesture];
    
    // Initialize notification of data recieved
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReceivedDataWithNotification:)
                                                 name:@"AR_DidReceiveDataNotification"
                                               object:nil];
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o duration:(NSTimeInterval)duration {
    [self interfaceOrientationChanged:o];
}

#pragma mark - public methods 
- (void)setMultiMode {
    isMultiMode = YES;
}

- (void)setSingleMode {
    isMultiMode = NO;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // note that this method does *not* run in the main thread!
    
    // convert the incoming YUV camera frame to a grayscale cv mat
    [Tools convertYUVSampleBuffer:sampleBuffer toGrayscaleMat:curFrame];
    
    if (!detector->isPrepared()) {  // on first frame: prepare for the frames
        [self prepareForFramesOfSize:CGSizeMake(curFrame.cols, curFrame.rows)
                         numChannels:curFrame.channels()];
    }
    
    // tell the tracker to run the detection on the input frame
    tracker->detect(&curFrame);
    
    // get an output frame. may be NULL if no frame processing output is selected
    dispFrame = detector->getOutputFrame();
    
    // update the views on the main thread
    if (dispFrame) {
        [self performSelectorOnMainThread:@selector(updateViews)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

#pragma mark - private methods

- (void)updateViews {
    // this method is only to display the intermediate frame processing
    // output of the detector.
    // (it is slow but it's only for debugging)
    
    // when we have a frame to display in "procFrameView" ...
    // ... convert it to an UIImage
    UIImage *dispUIImage = [Tools imageFromCvMat:dispFrame];
        
    // and display it with the UIImageView "procFrameView"
    [procFrameView setImage:dispUIImage];
    [procFrameView setNeedsDisplay];
}

- (void)initCam {
    NSLog(@"initializing cam");
    
    NSError *error = nil;
    
    // set up the camera capture session
    camSession = [[AVCaptureSession alloc] init];
    [camSession setSessionPreset:CAM_SESSION_PRESET];
    [camView setSession:camSession];
    
    // get the camera device
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    assert(devices.count > 0);
    
	AVCaptureDevice *camDevice = [devices firstObject];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == AVCaptureDevicePositionBack) {
			camDevice = device;
			break;
		}
	}
    
    camDeviceInput = [[AVCaptureDeviceInput deviceInputWithDevice:camDevice error:&error] retain];
    
    if (error) {
        NSLog(@"error getting camera device: %@", error);
        return;
    }
    
    assert(camDeviceInput);
    
    // add the camera device to the session
    if ([camSession canAddInput:camDeviceInput]) {
        [camSession addInput:camDeviceInput];
        [self interfaceOrientationChanged:self.interfaceOrientation];
    }
    
    // create camera output
    vidDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [camSession addOutput:vidDataOutput];
    
    // set output delegate to self
    dispatch_queue_t queue = dispatch_queue_create("vid_output_queue", NULL);
    [vidDataOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // get best output video format
    NSArray *outputPixelFormats = vidDataOutput.availableVideoCVPixelFormatTypes;
    int bestPixelFormatCode = -1;
    for (NSNumber *format in outputPixelFormats) {
        int code = [format intValue];
        if (bestPixelFormatCode == -1) bestPixelFormatCode = code;  // choose the first as best
        char fourCC[5];
        fourCCStringFromCode(code, fourCC);
        NSLog(@"available video output format: %s (code %d)", fourCC, code);
    }

    // specify output video format
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:bestPixelFormatCode] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [vidDataOutput setVideoSettings:outputSettings];
    
//    // cap to 15 fps
//    [vidDataOutput setMinFrameDuration:CMTimeMake(1, 15)];
}

- (BOOL)initDetector {
    
    cv::FileStorage fs;
    const char *path = [[[NSBundle mainBundle] pathForResource:camIntrinsicsFile ofType:NULL]cStringUsingEncoding:NSASCIIStringEncoding];
    
    if (!path) {
        NSLog(@"could not find cam intrinsics file %@", camIntrinsicsFile);
        return NO;
    }
    
    fs.open(path, cv::FileStorage::READ);
    
    if (!fs.isOpened()) {
        NSLog(@"could not load cam intrinsics file %@", camIntrinsicsFile);
        return NO;
    }
    
    cv::Mat camMat;
    cv::Mat distCoeff;
    
    fs["Camera_Matrix"]  >> camMat;
    
    if (useDistCoeff) {
        fs["Distortion_Coefficients"]  >> distCoeff;
    }
    
    if (camMat.empty()) {
        NSLog(@"could not load cam instrinsics matrix from file %@", camIntrinsicsFile);
        
        return NO;
    }
    
    detector->setCamIntrinsics(camMat, distCoeff);
    //[self initORBTracker];
    return YES;
}

//-(BOOL)initORBTracker {
//    
//    const char *refPath = [[[NSBundle mainBundle] pathForResource:@"the-scream.jpg" ofType:NULL]cStringUsingEncoding:NSASCIIStringEncoding];
//    
//    if (!refPath) {
//        NSLog(@"could not find reference image file %@", @"the-scream.jpg");
//        return NO;
//    }
//    
//    Mat rgbRef = imread(refPath);
//    if (!rgbRef.data) {
//        NSLog(@"OpenCV could not open reference image file %@", @"the-scream.jpg");
//        return NO;
//    
//    }
//    Mat gray;
//    cvtColor(rgbRef, gray, COLOR_BGR2GRAY);
//    orbTracker->initialize(gray);
//    return YES;
//}


- (void)prepareForFramesOfSize:(CGSize)size numChannels:(int)chan {
    // WARNING: this method will not be called from the main thead!
    
    detector->prepare(size.width, size.height, chan);
    
    float frameAspectRatio = size.width / size.height;
    NSLog(@"camera frames are of size %dx%d (aspect %f)", (int)size.width, (int)size.height, frameAspectRatio);

    // update proc frame view size
    float newViewH = procFrameView.frame.size.width / frameAspectRatio;   // calc new height
    float viewYOff = (procFrameView.frame.size.height - newViewH) / 2;
    
    CGRect correctedViewRect = CGRectMake(0, viewYOff, procFrameView.frame.size.width, newViewH);
    [self performSelectorOnMainThread:@selector(setCorrectedFrameForViews:)         // we need to execute this on the main thead
                           withObject:[NSValue valueWithCGRect:correctedViewRect]   // otherwise it will have no effect
                        waitUntilDone:NO];
}

- (void)setCorrectedFrameForViews:(NSValue *)newFrameRect {
    // WARNING: this *must* be executed on the main thread
    
    // set the corrected frame for the proc frame view
    CGRect r = [newFrameRect CGRectValue];
    [procFrameView setFrame:r];
    
    // also calculate a new GL projection matrix and resize the gl view
    float *projMatPtr = detector->getProjMat(r.size.width, r.size.height);
    NSLog(@"projection matrix:");
    printFloatMat4x4(projMatPtr);
    NSLog(@"------------------");
    [glView setMarkerProjMat:projMatPtr];
    [glView setFrame:r];
    [glView resizeView:r.size];
}

- (void)procOutputSelectBtnAction:(UIButton *)sender {
    NSLog(@"proc output selection button pressed: %@ (proc type %ld)",
          [sender titleForState:UIControlStateNormal], (long)sender.tag);
    
    BOOL normalDispMode = (sender.tag < 0);
    [glView setShowMarkers:normalDispMode];   // only show markers in "normal" display mode
    [camView setHidden:!normalDispMode];      // only show original camera frames in "normal" display mode
    [procFrameView setHidden:normalDispMode]; // only show processed frames for other than "normal" display mode
    
    detector->setFrameOutputLevel((ocv_ar::FrameProcLevel)sender.tag);
}

- (void)interfaceOrientationChanged:(UIInterfaceOrientation)o {
    [[(AVCaptureVideoPreviewLayer *)camView.layer connection] setVideoOrientation:(AVCaptureVideoOrientation)o];
}

#pragma mark - gesture methods
- (void)handleGesture:(UITapGestureRecognizer *)sender {
    
    NSLog(@"%@: handleGesture", TAG);
    if(sender.state == UIGestureRecognizerStateEnded) {
        CGPoint pos = [sender locationInView:sender.view];
        NSLog(@"%@: tap at position (%f, %f)", TAG, pos.x, pos.y);
        
        if (![self.glView intersectAtX:pos.x Y:pos.y]) {
            return;
        }
        
        // get color from glview
        Byte color = [glView findColorWithTapAtX:pos.x Y:pos.y];
        NSLog(@"%@: color is %hhu", TAG, color);
        NSLog(@"%@: r is %f", TAG, r * 255);
        
        if (r * 255 == color) {
            // generate a color randomly
            r = (arc4random() % 255) / 255.0;
            g = (arc4random() % 255) / 255.0;
            b = (arc4random() % 255) / 255.0;
            
            [self.glView handleColorVectorX:r Y:g Z:b];
        }

        if ( !isMultiMode ) {
            return;
        }
        
        Data *data = [[Data alloc]initWithColorX:r Y:g Z:b];
        NSData *preparedData = [NSKeyedArchiver archivedDataWithRootObject:data];
        NSError *error = nil;
        [self.appDelegate.mpcHandler.session sendData:preparedData
                                              toPeers:self.appDelegate.mpcHandler.session.connectedPeers
                                             withMode:MCSessionSendDataReliable
                                                error:&error];
        
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
        
        [data release];
    }
    NSLog(@"%@: data sent", TAG);
}

#pragma mark - multi-player handling
- (void)handleReceivedDataWithNotification:(NSNotification *)notification {
    
    NSDictionary *playerInfoDict = [notification userInfo];
    
    NSData *receivedData = [playerInfoDict objectForKey:@"data"];
    
    NSString *message = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]autorelease];
    
    MCPeerID *senderPeerID = [playerInfoDict objectForKey:@"peerID"];
    NSString *senderDisplayName = senderPeerID.displayName;
    
    if ([message isEqualToString:@"New Game"]) {
        if (!isGameRunning) {
            NSString *alertMessage = [NSString stringWithFormat:@"%@ has started a new game.", senderDisplayName];
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"AR"
                                                            message:alertMessage
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Done", nil]autorelease];
            [alert show];
            isGameRunning = YES;
            isHost = NO;
        }
    } else {
        Data *data = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
        NSLog(@"%@: received color from %@ tap at position (%f, %f, %f)", TAG, senderDisplayName, data.colorX, data.colorY, data.colorZ);
        [self.glView handleColorVectorX:data.colorX Y:data.colorY Z:data.colorZ];
    }
}

- (void)startGame {
    if (isMultiMode && (!isGameRunning)) {
        NSString *messageToSend = @"New Game";
        NSData *messageAsData = [messageToSend dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        [self.appDelegate.mpcHandler.session sendData:messageAsData
                                              toPeers:self.appDelegate.mpcHandler.session.connectedPeers
                                             withMode:MCSessionSendDataReliable
                                                error:&error];
        if (error != nil) {
            NSLog(@"%@: %@", TAG, [error localizedDescription]);
            
        } else{
            isHost = YES;
            isGameRunning = YES;
        }
    }
}

@end
