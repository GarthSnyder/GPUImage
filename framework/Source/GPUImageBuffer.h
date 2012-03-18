//  Created by Garth Snyder on 3/17/12
//
//  Thin overlay for OpenGL ES texture and renderbuffer objects. The
//  GPUImageTexture class handles these objects from a functional and 
//  logical perspective. This wrapper ensures sharability of the underlying
//  buffers and proper garbage collection when no one refers to them 
//  any longer.
//
//  A GPUImageTexture may or may not have an underlying buffer, depending
//  on its current state. But a GPUImageBuffer always corresponds to a 
//  single, real OpenGL buffer.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"

@interface GPUImageBuffer : NSObject
{
    GLuint _handle;
}

@property (nonatomic) GLuint handle;

- initWithSize:(GLsize)size baseFormat:(GLenum)format;
- (void) bindAsFramebuffer;

@end
