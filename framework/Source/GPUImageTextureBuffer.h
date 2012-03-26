#import "GPUImageBuffer.h"

@interface GPUImageTextureBuffer : GPUImageBuffer

@property (nonatomic) GLenum magFilter;
@property (nonatomic) GLenum minFilter;
@property (nonatomic) GLenum wrapS;
@property (nonatomic) GLenum wrapT;

@property (readonly, nonatomic) BOOL hasMipmap;
@property (readonly, nonatomic) GLenum pixType;

- initWithSize:(GLsize)size baseFormat:(GLenum)format pixType:(GLenum)pix;
- initWithTexture:(GLint)texHandle size:(GLsize)size format:(GLenum)fmt;

- (void) generateMipmap:(BOOL)force;

@end
