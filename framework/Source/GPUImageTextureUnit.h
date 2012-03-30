//  This is a super-simple class that tracks which textures are assigned to
//  which texture units. Unlike uniform value assignments, texture unit
//  bindings do not stick to OpenGL programs, so knowing whether a binding
//  is still current can help to optimize out redundant texture setups.
//
//  This probably doesn't yield a detectable performance improvement, but it
//  simplifies the OpenGL stream and makes texture unit numbers more
//  characteristic of specific textures to help debugging.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import "GPUImage.h"
#import "GPUImageTexture.h"

@interface GPUImageTextureUnit : NSObject

+ (GPUImageTextureUnit *) textureUnit;

// Activate a scratch texture unit - makes sure that texture bindings
// don't randomly affect a random texture unit.

+ (void) activateScratchUnit;

- (id) initWithTextureUnitNumber:(NSUInteger)tNum;
- (void) bindTexture:(GPUImageTexture *)texture;

@property (nonatomic) GLint currentTextureHandle;
@property (nonatomic) NSUInteger textureUnitNumber;

@end

