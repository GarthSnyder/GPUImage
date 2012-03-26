#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "GPUImageHeaders.h"

// GPUImageBase is the drawing and texture management portion of GPUImage
// minus the GPUImageUpdating protocol implementation. See header comments
// for GPUImage for more details.

@interface GPUImageBase : NSObject <GPUImageProvider>

@property (nonatomic) GLsize size;
@property (nonatomic) GLenum baseFormat;
@property (nonatomic) GLenum pixType;

// Setting an associated layer automatically turns on usesRenderbuffer.
// However, you can use a renderbuffer without an associated CAEAGLLayer.

@property (assign, nonatomic) CAEAGLLayer *layer;   // Associated layer, if any
@property (nonatomic) BOOL usesRenderbuffer;

@property (nonatomic) GLenum wrapS, wrapT;          // Texture edge handling
@property (nonatomic) GLenum magFilter, minFilter;  // Linear, nearest, etc.

// Convenience properties for setting both filters or both wraps at once
@property (nonatomic) GLenum wrap;
@property (nonatomic) GLenum filter;

@property (nonatomic) BOOL generatesMipmap;

- (void) bindAsFramebuffer;
- (void) clearFramebuffer; // Also binds
- (void) clearFramebuffer:(vec4)backgroundColor; // Also binds

- (void) drawWithProgram:(GPUImageProgram *)prog;

// Adopts size and base format only, and only if receiver's are unknown
- (void) adoptParametersFrom:(GPUImage *)other;

// Methods for getting image data out of OpenGL
- (GLuint *) getRawContents;
- (CGImageRef) getCGImage;
- (UIImage *) getUIImage;

// Generally NOT necessary to access these directly

- (void) createBackingStore;
- (void) releaseBackingStore;

@end
