#import "GPUImageCanvas.h"

@interface GPUImageTexture : GPUImageCanvas

@property (nonatomic) GLenum magFilter;
@property (nonatomic) GLenum minFilter;
@property (nonatomic) GLenum wrapS;
@property (nonatomic) GLenum wrapT;

@property (readonly, nonatomic) BOOL hasMipmap;
@property (readonly, nonatomic) GLenum pixType;

// Call this to switch to a scratch texture unit and clear the texture 
// binding cache. Use this before calling iOS methods (such as the 
// OpenGLES texture cache calls) that may change texture bindings.
// You don't want those bindings to stick to whatever texture unit happens
// to have been used last.

+ (void) protectTextureContext;

- initWithSize:(GLsize)size baseFormat:(GLenum)format pixType:(GLenum)pix;
- initWithTexture:(GLint)texHandle size:(GLsize)size format:(GLenum)fmt;

- (void) generateMipmap:(BOOL)force;

@end
