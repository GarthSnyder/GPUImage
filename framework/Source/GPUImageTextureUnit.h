//  This is a super-simple class that tracks which textures are assigned to
//  which texture units. Unlike uniform value assignments, texture unit
//  bindings do not stick to OpenGL programs, so knowing whether a binding
//  is still current can help to optimize out redundant texture setups.
//
//  This probably doesn't yield a detectable performance improvement, but it
//  significantly simplifies the OpenGL stream, which aids debugging.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import "GPUImage.h"

@interface GPUImageTextureUnit : NSObject

+ (id) unitAtIndex:(GLint)i;

@property (nonatomic) GLint currentTextureHandle;
@property (nonatomic) GLenum textureUnitID;

- (void) bindTexture:(GPUImageTextureBuffer *)texture;

@end
