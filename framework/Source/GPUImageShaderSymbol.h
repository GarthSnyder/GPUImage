//
//  Created by Garth Snyder on 3/15/12.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#import "GPUImageTextureUnit.h"

@interface GPUImageShaderSymbol : NSObject

@property (nonatomic) NSString *name;   // Uniform name
@property (nonatomic) GLint index;      // OES parameter index
@property (nonatomic) GLenum type;      // e.g., GL_FLOAT_VEC2
@property (nonatomic) GLint count;      // Parameter array length
@property (nonatomic) GPUImageTextureUnit *textureUnit;  // Only for type = GL_TEXTURE_2D
@property (nonatomic) id value;
@property (nonatomic) BOOL knowsOESDetails;
@property (nonatomic) BOOL dirty;       // Needs flushed to OES context

+ (GPUImageShaderSymbol *) symbol;

// Communicate a value to OpenGL
- (void) setOESValue;

// Collect details known only to OpenGL
- (void) gatherOESDetailsForProgram:(GLint)program;

@end
