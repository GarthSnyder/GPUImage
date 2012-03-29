//  Thin wrapper for OpenGL ES texture and renderbuffer objects. The
//  GPUImageBase class handles these objects from an abstract perspective,
//  whereas a GPUImageBuffer always corresponds to a specific, real OpenGL
//  image buffer. (By contrast, a GPUImage may not have an actual buffer;
//  think of it as a "specification for a buffer".)
//
//  The point of wrapping is to ensure sharability of the underlying
//  buffers and to ensure that buffers are deleted when no one refers to them 
//  any longer.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"

@interface GPUImageBuffer : NSObject
{
    GLuint _handle;
    GLuint _fboHandle;
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
- (BOOL) validateFramebuffer;

- (void) clearFramebuffer:(vec4)backgroundColor;

// Callers are responsible for freeing these
- (GLubyte *) rawDataFromFramebuffer;
- (CGImageRef) CGImageFromFramebuffer;

@end
