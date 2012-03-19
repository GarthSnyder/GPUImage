#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "GPUImageHeaders.h"

// A GPUImage is an element that knows how to render itself into a framebuffer,
// and which owns that framebuffer and its associated backing store.
//
// For most purposes, a GPUImage can be thought of as a wrapper for an OpenGL
// texture. But there are some important differences:
//
// 1) A GPUImage can be backed by a renderbuffer instead of a texture.
//
// 2) A GPUImage may or may not have an actual renderbuffer or texture 
//    associated with it, though it always has a (possibly incomplete)
//    specification of what that buffer should look like. GPUImage objects
//    may share buffers if that can be done without violating the update
//    protocol. (Specific OpenGL ES textures and renderbuffers are 
//    represented by subclasses of GPUImageBuffer.)
//
// 3) A GPUImage also has, or can produce on demand, an associated 
//    framebuffer.

@interface GPUImage : GPUImageElement

@property (nonatomic) GLsize size;
@property (nonatomic) GLenum baseFormat;
@property (nonatomic) GLenum pixType;

// Setting an associated layer automatically turns on useRenderbuffer.
// However, you can use a renderbuffer without an associated CAEAGLLayer.

@property (assign, nonatomic) CAEAGLLayer *layer;   // Associated layer, if any
@property (nonatomic) BOOL useRenderbuffer;

@property (nonatomic) GLenum wrapS, wrapT;          // Texture edge handling
@property (nonatomic) GLenum magFilter, minFilter;  // Linear, nearest, etc.

// Convenience properties for setting both filters or both wraps at once
@property (nonatomic) GLenum wrap;
@property (nonatomic) GLenum filter;

@property (nonatomic) BOOL generateMipmap;

// Let the texture manage this! Not part of the general API.
@property (strong, nonatomic) GPUImageBuffer *backingStore;

- (void) bindAsFramebuffer;

// Adopts size and base format only, and only if receiver's are unknown
- (void) adoptParametersFrom:(GPUImage *)other;

// Methods for getting image data out of OpenGL
- (GLuint *) getRawContents;
- (CGImageRef) getCGImage;
- (UIImage *) getUIImage;

@end
