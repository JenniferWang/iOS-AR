/**
 * Based on OcvARBasicNativeCam - Basic ocv_ar example for iOS with native camera usage
 * by  Markus Konrad <konrad@htw-berlin.de>, June 2014,
 * INKA Research Group, HTW Berlin - http://inka.htw-berlin.de/
 * BSD licensed (see LICENSE file).
 *
 * gl view - implementation file.
 *
 * Modified by Jiyue Wang, Shaohan Xu
 */

#import "GLView.h"
#import "lg_cocacola_can.h"
#import "cube.h"

#define QUAD_VERTICES 				4
#define QUAD_COORDS_PER_VERTEX      3
#define QUAD_TEXCOORDS_PER_VERTEX 	2
#define QUAD_VERTEX_BUFSIZE 		(QUAD_VERTICES * QUAD_COORDS_PER_VERTEX)
#define QUAD_TEX_BUFSIZE 			(QUAD_VERTICES * QUAD_TEXCOORDS_PER_VERTEX)

const NSString *TAG = @"GLView";

#pragma mark - helper
void copyMatrix4(const float *input, float* output) {
    for( int i = 0; i < 16; i ++) {
        output[i] = input[i];
    }
}

@interface GLView(Private)

- (void)setupGL;

- (void)initShaders;

- (BOOL)buildShader:(Shader *)shader src:(NSString *)src;

- (void)drawMarker:(const ocv_ar::Marker *)marker;

- (GLKMatrix4)updateModelViewMat: (const ocv_ar::Marker *)marker WithTapAtX:(float) x Y:(float) y;

- (BOOL)unProjectAtWinPos:(const GLKVector3 &)winpos WithModelViewMat:(const GLKMatrix4 &)modelViewMat ProjectMat:(const GLKMatrix4 &)projMat ObjectPos:(GLKVector3 &)objectPos;

- (BOOL)getObjectPost:(GLKVector3 &)objectPos RecivedTapAt:(CGPoint)tapPos WithModelViewMat:(const GLKMatrix4 &)modelViewMat ProjectMat:(const GLKMatrix4 &) projMat;

@end


@implementation GLView

@synthesize tracker;
@synthesize markerProjMat;
@synthesize markerScale;
@synthesize showMarkers;

#pragma mark init/dealloc

- (id)initWithFrame:(CGRect)frame {
    // create context
    EAGLContext *ctx = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    [EAGLContext setCurrentContext:ctx];
    
    // init
    self = [super initWithFrame:frame context:ctx];
    
    if (self) {
        // defaults
        glInitialized = NO;
        showMarkers = YES;
        
        markerProjMat = NULL;
        color[0] = 0.0;
        color[1] = 0.0;
        color[2] = 0.0;
        
        memset(markerScaleMat, 0, sizeof(GLfloat) * 16);
        [self setMarkerScale:2.0f];
        
        // add the render method of our GLView to the main run loop in order to
        // render every frame periodically
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        // configure
        [self setEnableSetNeedsDisplay:NO]; // important to render every frame periodically and not on demand!
        [self setOpaque:NO];                // we have a transparent overlay
        
        [self setDrawableColorFormat:GLKViewDrawableColorFormatRGBA8888];
        [self setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
        [self setDrawableStencilFormat:GLKViewDrawableStencilFormat8];
        
    }
    
    return self;
}

#pragma mark parent methods
- (void)drawRect:(CGRect)rect {
    if (!glInitialized) return;
    
    // Clear the framebuffer
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);   // 0.0f for alpha is important for non-opaque gl view!
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glViewport(0, 0, viewportSize.width, viewportSize.height);
    
    if (!showMarkers) return;   // break here in order not to display markers
    
    // update the tracker to smoothly move to new marker positions
    tracker->update();
    
    // use the marker shader
    markerDispShader.use();
    
    if (markerProjMat) {
        tracker->lockMarkers();     // lock the tracked markers, because they might get updated in a different thread
        
        // draw each marker
        const ocv_ar::MarkerMap *markers = tracker->getMarkers();
        for (ocv_ar::MarkerMap::const_iterator it = markers->begin();
             it != markers->end();
             ++it)
        {
            [self drawMarker:&(it->second)];
        }
        
        tracker->unlockMarkers();   // unlock the tracked markers again
    }
}

- (void)resizeView:(CGSize)size {
    NSLog(@"GLView: resizing to frame size %dx%d",
          (int)size.width, (int)size.height);
    
    if (!glInitialized) {
        NSLog(@"GLView: initializing GL");
        
        [self setupGL];
    }
    
    // handle retina displays, too:
    float scale = [[UIScreen mainScreen] scale];
    viewportSize = CGSizeMake(size.width * scale, size.height * scale);
    
    [self setNeedsDisplay];
}

- (NSUInteger) findColorWithTapAtX:(float) x Y:(float) y {
    
    Byte pixelColor[4] = {0,};
    CGFloat scale = UIScreen.mainScreen.scale;
    glReadPixels(x * scale, (viewportSize.height - (y * scale)), 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixelColor);
    
    return pixelColor[0];
}

#pragma mark public methods

- (void)handleColorVectorX:(float)colorX Y:(float)colorY Z:(float)colorZ {
    
    color[0] = colorX;
    color[1] = colorY;
    color[2] = colorZ;
    
}


- (void)render:(CADisplayLink *)displayLink {
    [self display];
}

- (void)setMarkerScale:(float)s {
    markerScale = s;
    
    // set 4x4 matrix diagonal to s
    // markerScaleMat must be zero initialized!
    for (int i = 0; i < 3; ++i) {
        markerScaleMat[i * 5] = s * 0.5f;
    }
    markerScaleMat[15] = 1.0f;
}

- (BOOL)intersectAtX:(float)x Y:(float)y;{
    
    if (!self.markerProjMat) {
        return NO;
    }
    const ocv_ar::MarkerMap *markers = tracker->getMarkers();
    if (markers->empty()) {
        return NO;
    }
    
    // currently only support one object
    GLKVector3 bojectPos;
    return [self getObjectPost:bojectPos RecivedTapAt:CGPointMake(x, y) WithModelViewMat:
            markerModelViewMat ProjectMat:markerProjectionMat];
    
}

#pragma mark private methods

- (BOOL)getObjectPost:(GLKVector3 &)objectPos RecivedTapAt:(CGPoint)tapPos WithModelViewMat:(const GLKMatrix4 &)modelViewMat ProjectMat:(const GLKMatrix4 &) projMat  {
    
    GLKVector3 winPos = GLKVector3Make(tapPos.x, viewportSize.height - tapPos.y, 1.0);
    return [self unProjectAtWinPos:winPos WithModelViewMat:modelViewMat ProjectMat:projMat ObjectPos:objectPos];
}

// TODO: not returning the correct decision
- (BOOL)unProjectAtWinPos:(const GLKVector3 &)winpos WithModelViewMat:(const GLKMatrix4 &)modelViewMat ProjectMat:(const GLKMatrix4 &)projMat ObjectPos:(GLKVector3 &)objectPos {
    
    //Transformation matrices
    bool isInvertible;
    GLKVector4 inVec, outVec;
    GLKVector4 viewPort = GLKVector4Make(0.0, 0.0, viewportSize.width, viewportSize.height);
    
    //Calculation for inverting a matrix, compute projection x modelview
    //and store in A[16]
    GLKMatrix4 A = GLKMatrix4Multiply(projMat, modelViewMat);
    GLKMatrix4 inverse = GLKMatrix4Invert(A, &isInvertible);
    
    if (!isInvertible) {
        NSLog(@"%@: matrix not invertible", TAG);
        return NO;
    }
    inVec.x = (winpos.x - viewPort.x) / viewPort.z * 2.0 - 1.0;
    inVec.y = (winpos.y - viewPort.y) / viewPort.w * 2.0 - 1.0;
    inVec.z = 2.0 * winpos.z - 1.0;
    inVec.w = 1.0;

    //Objects coordinates
    outVec = GLKMatrix4MultiplyVector4(inverse, inVec);
    if (outVec.w == (GLfloat)0.0) {
        NSLog(@"%@: w is 0", TAG);
        return NO;
    }
    outVec.w = 1.0 / outVec.w;
    objectPos.x = outVec.x * outVec.w;
    objectPos.y = outVec.y * outVec.w;
    objectPos.z = outVec.z * outVec.z;
    
    NSLog(@"%@: object pos at (%f, %f, %f)", TAG, objectPos.x, objectPos.y, objectPos.z);
    
    return YES;
}

- (void)drawMarker:(const ocv_ar::Marker *)marker {

    // update transform matrixes
    float mat[16];
    copyMatrix4(marker->getPoseMatPtr(), mat);
    markerModelViewMat = GLKMatrix4MakeWithArray(mat);
    markerProjectionMat = GLKMatrix4MakeWithArray(markerProjMat);

    glUniformMatrix4fv(shMarkerProjMat, 1, false, markerProjMat);
    glUniformMatrix4fv(shMarkerModelViewMat, 1, false, markerModelViewMat.m);
    glUniformMatrix4fv(shMarkerTransformMat, 1, false, markerScaleMat);
    
    float markerColor[] = { color[0], color[1], color[2], 0.75f };
    glUniform4fv(shMarkerColor, 1, markerColor);
    
    // set geometry
    glEnableVertexAttribArray(shAttrPos);
    glVertexAttribPointer(shAttrPos,
                          QUAD_COORDS_PER_VERTEX,
                          GL_FLOAT,
                          GL_FALSE,
                          0,
                          cubePositions);
    
    // draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, cubeVertices);
    
    // cleanup
    glDisableVertexAttribArray(shAttrPos);

}

- (void)setupGL {
    [self initShaders];
    
    glDisable(GL_CULL_FACE);
    
    glInitialized = YES;
}

- (void)initShaders {
    [self buildShader:&markerDispShader src:@"marker"];
    shMarkerProjMat = markerDispShader.getParam(UNIF, "uProjMat");
    shMarkerModelViewMat = markerDispShader.getParam(UNIF, "uModelViewMat");
    shMarkerTransformMat = markerDispShader.getParam(UNIF, "uTransformMat");
    shMarkerColor = markerDispShader.getParam(UNIF, "uColor");
}

- (BOOL)buildShader:(Shader *)shader src:(NSString *)src {
    NSString *vshFile = [[NSBundle mainBundle] pathForResource:[src stringByAppendingString:@"_v"]
                                                        ofType:@"glsl"];
    NSString *fshFile = [[NSBundle mainBundle] pathForResource:[src stringByAppendingString:@"_f"]
                                                        ofType:@"glsl"];
    
    const NSString *vshSrc = [NSString stringWithContentsOfFile:vshFile encoding:NSASCIIStringEncoding error:NULL];
    if (!vshSrc) {
        NSLog(@"GLView: could not load shader contents from file %@", vshFile);
        return NO;
    }
    
    const NSString *fshSrc = [NSString stringWithContentsOfFile:fshFile encoding:NSASCIIStringEncoding error:NULL];
    if (!fshSrc) {
        NSLog(@"GLView: could not load shader contents from file %@", fshFile);
        return NO;
    }
    
    return shader->buildFromSrc([vshSrc cStringUsingEncoding:NSASCIIStringEncoding],
                                [fshSrc cStringUsingEncoding:NSASCIIStringEncoding]);
}

@end