//  Created by Garth Snyder on 3/17/12
//
//  Thin overlay for OpenGL ES texture and renderbuffer objects. The
//  GPUImage class handles these objects from a functional and 
//  logical perspective. This wrapper ensures sharability of the underlying
//  buffers and proper garbage collection when no one refers to them 
//  any longer.
//
//  A GPUImage may or may not have an underlying buffer, depending
//  on its current state. But a GPUImageBuffer always corresponds to a 
//  single, real OpenGL buffer.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"

@interface GPUImageBuffer : NSObject
{
    GLuint _handle;
    GLuint _fboHandle; // Framebuffer object, if one exists
    GLsize _size;
    GLenum _format;
}

@property (readonly, nonatomic) GLuint handle;
@property (readonly, nonatomic) GLuint fboHandle;

@property (readonly, nonatomic) GLsize size;
@property (readonly, nonatomic) GLenum format;

- (id) initWithSize:(GLsize)size baseFormat:(GLenum)format;

- (void) bind;
- (void) bindAsFramebuffer;

- (void) clearFrameBuffer:(vec4)backgroundColor;

// Callers are responsible for freeing these
- (GLubyte *) rawDataFromFramebuffer;
- (CGImageRef) CGImageFromFramebuffer;

@end
