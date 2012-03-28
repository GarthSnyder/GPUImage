#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageTypes.h"
#import "GPUImageProgram.h"

// GPUImageBase is the drawing and texture management portion of GPUImage.
// On top of this platform, GPUImage adds the GPUImageSource 
// protocol implementation to form a general-purpose GPUImage graph element
// object. See header comments in GPUImage.h for more details.

@interface GPUImageBase : NSObject
{
    GPUImageTimestamp timeLastChanged;
    GPUImageBuffer *_backingStore;
}

@property (nonatomic) GLsize size;
@property (nonatomic) GLenum baseFormat;    // GL_RGBA, etc.
@property (nonatomic) GLenum pixType;       // GL_UNSIGNED_BYTE, etc.

// Setting an associated layer automatically turns on usesRenderbuffer and
// prepares the GPUImage object for rendering to an onscreen view.
//
// However, you can use a renderbuffer without an associated CAEAGLLayer.

@property (assign, nonatomic) CAEAGLLayer *layer;
@property (nonatomic) BOOL usesRenderbuffer;

@property (nonatomic) GLenum wrapS, wrapT;          // Texture edge handling
@property (nonatomic) GLenum magFilter, minFilter;  // Linear, nearest, etc.

// Convenience properties for setting both filters or both wraps at once
@property (nonatomic) GLenum wrap;
@property (nonatomic) GLenum filter;

// Automatically maintain a mipmap for this texture. 
// Incompatible with usesRenderbuffer.
@property (nonatomic) BOOL generatesMipmap;

- (void) bindAsFramebuffer;
- (void) clearFramebuffer;                       // Also binds
- (void) clearFramebuffer:(vec4)backgroundColor; // Also binds

- (void) drawWithProgram:(GPUImageProgram *)prog;
- (void) drawWithProgram:(GPUImageProgram *)prog vertices:(const GLfloat *)v textureCoordinates:(const GLfloat *)t;

// Adopts size and base format only, and only if receiver's are unknown
- (void) adoptParametersFrom:(id <GPUImageSource>)other;

// Methods for getting image data out of OpenGL
- (GLubyte *) getRawContents;
- (CGImageRef) getCGImage;
- (UIImage *) getUIImage;

// Generally not necessary to access these directly

- (GPUImageBuffer *) backingStore;
- (void) createBackingStore;
- (void) releaseBackingStore;
- (void) setTextureParameters;

@end
