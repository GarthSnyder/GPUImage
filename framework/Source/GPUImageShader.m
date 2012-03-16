// Started by Garth Snyder on 3/13/12.

#import "GPUImageShader.h"

// Default shaders implement a simple copy operation

NSString *const kGPUImageDefaultVertexShader = SHADER_STRING
(
     attribute vec4 position;
     attribute vec4 inputTextureCoordinate;
     
     varying vec2 textureCoordinate;
     
     void main()
     {
         gl_Position = position;
         textureCoordinate = inputTextureCoordinate.xy;
     }
);

NSString *const kGPUImageDefaultFragmentShader = SHADER_STRING
(
     attribute vec4 position;
     attribute vec4 inputTextureCoordinate;
     
     uniform sampler2D inputTexture;
     
     varying vec2 textureCoordinate;
     
     void main()
     {
         gl_FragColor = vec4(texture2D(inputTexture, textureCoordinate).rgb, 1.0);
     }
);

@implementation GPUImageShader

@synthesize shaderHandle = _shaderHandle;
@synthesize attributes = _attributes;

#pragma mark Initializers

- (GPUImageShader *) initWithSourceText:(NSString *)shader
{
    if (self = [super init]) {
        sourceText = shader;
        _shaderHandle = -1;
    }
    return self;
}

- (GPUImageShader *) initWithFilename:(NSString *)filename;
{
    NSArray *extensions = [NSArray arrayWithObjects:@"", @"glsl", @"vsh", @"fsh", nil];
    NSString *foundFile;
    for (NSString *ext in extensions) {
        if ((foundFile = [[NSBundle mainBundle] pathForResource:filename ofType:ext])) {
            return [self initWithSourceText:[NSString stringWithContentsOfFile:foundFile
                encoding:NSUTF8StringEncoding error:nil]];
        }
    }
    return nil;
}

- (NSArray *) attributes
{
return _attributes;
}

- (NSArray *) uniforms 
{
return [_uniforms allKeys];
}

#pragma mark Compilation and handle managment

- (BOOL) compileAsShaderType:(GLenum)type
{
    if (_shaderHandle >= 0) {
        return YES;
    }

    GLint status;
    const GLchar *source = (GLchar *)[sourceText UTF8String];
    _shaderHandle = glCreateShader(type);
    glShaderSource(_shaderHandle, 1, &source, NULL);
    glCompileShader(_shaderHandle);
    glGetShaderiv(_shaderHandle, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(_shaderHandle, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(_shaderHandle, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
        [self delete];
    }	
    return status == GL_TRUE;
}

- (void) delete
{
    if (_shaderHandle >= 0) {
        glDeleteShader(_shaderHandle);
    }
    _shaderHandle = -1;
}

- (void) dealloc
{
    [self delete];
}

@end
