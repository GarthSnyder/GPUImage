//
// Created by Garth Snyder on 3/13/12.
//
// This class is internal to GPUImage. You should not create or interact 
// with it directly. Use GPUImageProgram instead - it handles both shader
// compilation and the management of uniforms.

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define SHADER_STRINGIZE(x) #x
#define SHADER_STRINGIZE2(x) SHADER_STRINGIZE(x)
#define SHADER_STRING(text) @ SHADER_STRINGIZE2(text)

@interface GPUImageShader : NSObject
{
    NSString *sourceText;
    NSMutableArray *_attributes;
    NSMutableDictionary *_uniforms;
}

- (GPUImageShader *) initWithSourceText:(NSString *)shader;
- (GPUImageShader *) initWithFilename:(NSString *)filename;

- (BOOL) compileAsShaderType:(GLenum)type;
- (void) delete;

- (GLint) handleForAttribute:(NSString *)attr;
- (GLint) handleForUniform:(NSString *)attr;

- (NSString *) logForOpenGLObject:(GLuint)object;

@property (nonatomic, readonly) GLint shaderHandle;
@property (nonatomic, readonly) NSArray *attributes;
@property (nonatomic, readonly) NSArray *uniforms;

@end
