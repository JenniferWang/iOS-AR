/**
 * OcvARBasicNativeCam - Basic ocv_ar example for iOS with native camera usage
 *
 * gl view - implementation file.
 *
 * Author: Markus Konrad <konrad@htw-berlin.de>, June 2014.
 * INKA Research Group, HTW Berlin - http://inka.htw-berlin.de/
 *
 * BSD licensed (see LICENSE file).
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
/**
 * set up OpenGL
 */
- (void)setupGL;

/**
 * initialize shaders
 */
- (void)initShaders;

/**
 * build a shader <shader> from source <src>
 */
- (BOOL)buildShader:(Shader *)shader src:(NSString *)src;

/**
 * draw a <marker>
 */
- (void)drawMarker:(const ocv_ar::Marker *)marker;

- (GLKMatrix4)updateModelViewMat: (const ocv_ar::Marker *)marker WithTapAtX:(float) x Y:(float) y;
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
        
        deltaX = 0;
        deltaY = 0;
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

#pragma mark public methods

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

- (void)handleTapAtX:(float) x Y:(float) y {
    deltaX = x;
    deltaY = y;
}


#pragma mark private methods
// BUGGY
- (GLKMatrix4)updateModelViewMat: (const ocv_ar::Marker *)marker WithTapAtX:(float) x Y:(float) y {
    
    float mat[16];
    copyMatrix4(marker->getPoseMatPtr(), mat);
    
    GLKMatrix4 modelViewMat = GLKMatrix4MakeWithArray(mat);
    GLKMatrix4 projMat = GLKMatrix4MakeWithArray(markerProjMat);
    GLKMatrix4 projXModelViewMat = GLKMatrix4Multiply(projMat, modelViewMat);
    
    bool *isInvertible = nil;
    GLKMatrix4 invModelViewMat = GLKMatrix4Invert(projXModelViewMat, isInvertible);
    if (isInvertible != nil) {
        NSLog(@"%@: projection * modelView is singular, return previous model view matrix", TAG);
        return modelViewMat;
    }else {
        GLKVector4 tapVector = GLKVector4Make(x, y, 0, 1);
        GLKVector4 transVector = GLKMatrix4MultiplyVector4(invModelViewMat, tapVector);
        NSLog(@"%@: got translation vector (%f, %f, %f, %f)", TAG, transVector.x, transVector.y, transVector.z, transVector.w  );
        return GLKMatrix4Translate(modelViewMat, -transVector.x, -transVector.y, 0);
    }
}

- (void)drawMarker:(const ocv_ar::Marker *)marker {
    // set matrixes
//    float mat[16];
//    copyMatrix4(marker->getPoseMatPtr(), mat);
//    
//    GLKMatrix4 modelViewMat = GLKMatrix4MakeWithArray(mat);
    
    GLKMatrix4 modelViewMat = [self updateModelViewMat:marker WithTapAtX:deltaX Y:deltaY];
    modelViewMat = GLKMatrix4Rotate(modelViewMat, 3.14/3, 1, 0, 0);
    
    glUniformMatrix4fv(shMarkerProjMat, 1, false, markerProjMat);
    glUniformMatrix4fv(shMarkerModelViewMat, 1, false, modelViewMat.m);
    glUniformMatrix4fv(shMarkerTransformMat, 1, false, markerScaleMat);
    
    float markerColor[] = { 1.0, 0, 0, 0.75f };
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
    
    deltaX = 0;
    deltaY = 0;
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