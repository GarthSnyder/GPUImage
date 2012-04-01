#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#import "GPUImageTextureUnit.h"

@interface GPUImageShaderSymbol : NSObject

@property (nonatomic, retain) NSString *name;   // Uniform name

@property (nonatomic) BOOL knowsOpenGLDetails;     // Asked OpenGL for type, etc?
@property (nonatomic) GLint index;              // OpenGL parameter index
@property (nonatomic) GLenum type;              // e.g., GL_FLOAT_VEC2
@property (nonatomic) GLint count;              // Parameter array length

@property (nonatomic) id value;
@property (nonatomic) BOOL dirty;               // Needs flushed to OpenGL context

@property (nonatomic, retain) GPUImageTextureUnit *textureUnit;  // Only for type = GL_TEXTURE_2D

// Communicate a value to OpenGL
- (void) setOpenGLValue;

// Collect details known only to OpenGL
- (void) gatherOpenGLDetailsForProgram:(GLint)program;

@end
