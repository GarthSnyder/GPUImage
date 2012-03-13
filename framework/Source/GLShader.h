//
//  Created by Garth Snyder on 3/13/12.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLShader : NSObject

- (GLShader *) initWithSourceText:(NSString *)shader;
- (GLShader *) initWithFilename:(NSString *)filename;

- (BOOL) compileAsShaderType:(GLenum)type;
- (void) delete;

@property (nonatomic, readonly) GLint shaderName;
@property (nonatomic, readonly) NSArray *attributes;
@property (nonatomic, readonly) NSArray *uniforms;

@end
