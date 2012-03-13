#import "GLProgram.h"

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

#pragma mark Definition of function pointers

typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint* params);
typedef void (*GLLogFunction) (GLuint program, GLsizei bufsize, GLsizei* length, 
    GLchar* infolog);

#pragma mark -

@interface GLProgram ()
{
    NSMutableDictionary *attributes, *uniforms;
    GLuint              program, vertShader, fragShader;
    BOOL                bound;
}

- (void) unbindAndReleaseShaders;
- (BOOL)compileShader:(NSString *)shaderString ofType:(GLenum)type name:(GLuint *)shader;
- (NSString *) logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunc 
    logFunc:(GLLogFunction)logFunc;
- (NSString *) getShaderTextFromFile:(NSString *)filename;

@end

#pragma mark -

@implementation GLProgram

@synthesize vertexShader = _vertexShader;
@synthesize vertexShaderFilename = _vertexShaderFilename;
@synthesize fragmentShader = _fragmentShader;
@synthesize fragmentShaderFilename = _fragmentShaderFilename;

- (GLProgram *)init
{
    if (self = [super init]) {
        self.vertexShader = kGPUImageDefaultVertexShader;
        attributes = [NSMutableDictionary dictionary];
        uniforms = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) setVertexShader:(NSString *)vsText
{
    [self unbindAndReleaseShaders];
    _vertexShaderFilename = nil;
    _vertexShader = vsText;
}

- (void) setVertexShaderFilename:(NSString *)vsFile
{
    [self unbindAndReleaseShaders];
    _vertexShader = nil;
    _vertexShaderFilename = vsFile;
}

- (void) setFragmentShader:(NSString *)fsText
{
    [self unbindAndReleaseShaders];
    _fragmentShaderFilename = nil;
    _fragmentShader = fsText;
}

- (void) setFragmentShaderFilename:(NSString *)fsFile
{
    [self unbindAndReleaseShaders];
    _fragmentShader = nil;
    _fragmentShaderFilename = fsFile;
}

- (NSString *) getShaderTextFromFile:(NSString *)filename
{
    NSString *foundFile = [[NSBundle mainBundle] pathForResource:filename ofType:@"glsl"];
    if (!foundFile) {
        foundFile = [[NSBundle mainBundle] pathForResource:filename ofType:@"vsh"];
    }
    if (!foundFile) {
        foundFile = [[NSBundle mainBundle] pathForResource:filename ofType:@"fsh"];
    }
    if (foundFile) {
        return [NSString stringWithContentsOfFile:foundFile encoding:NSUTF8StringEncoding error:nil];
    }
    return nil;
}

// END:compile
#pragma mark -
// START:addattribute
- (void)addAttribute:(NSString *)attributeName
{
    if (![attributes containsObject:attributeName])
    {
        [attributes addObject:attributeName];
        glBindAttribLocation(program, 
                             [attributes indexOfObject:attributeName], 
                             [attributeName UTF8String]);
    }
}
// END:addattribute
// START:indexmethods
- (GLuint)attributeIndex:(NSString *)attributeName
{
    return [attributes indexOfObject:attributeName];
}
- (GLuint)uniformIndex:(NSString *)uniformName
{
    return glGetUniformLocation(program, [uniformName UTF8String]);
}
// END:indexmethods
#pragma mark -
// START:link
- (BOOL)link
{
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return YES;
}
// END:link
// START:use
- (void)use
{
    glUseProgram(program);
}
// END:use
#pragma mark -
// START:privatelog
- (NSString *)logForOpenGLObject:(GLuint)object 
                    infoCallback:(GLInfoFunction)infoFunc 
                         logFunc:(GLLogFunction)logFunc
{
    GLint logLength = 0, charsWritten = 0;
    
    infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1)
        return nil;
    
    char *logBytes = malloc(logLength);
    logFunc(object, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
                                              length:logLength 
                                            encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}
// END:privatelog
// START:log
- (NSString *)vertexShaderLog
{
    return [self logForOpenGLObject:vertShader 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
    
}
- (NSString *)fragmentShaderLog
{
    return [self logForOpenGLObject:fragShader 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}
- (NSString *)programLog
{
    return [self logForOpenGLObject:program 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}
// END:log

- (void)validate;
{
	GLint logLength;
	
	glValidateProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}	
}

#pragma mark -
#pragma mark Compilation, binding, and unbinding

- (BOOL) compileShaders
{
    [self unbindAndReleaseShaders];
    
    NSString *vertexText = _vertexShader ? _vertexShader : 
        [self getShaderTextFromFile:_vertexShaderFilename];
    NSString *fragmentText = _fragmentShader ? _fragmentShader : 
        [self getShaderTextFromFile:_fragmentShaderFilename];
    
    if (!vertexText || !fragmentText) {
        NSLog(@"GLProgram::compileShaders called with missing shader");
        return NO;
    }

    if (![self compileShader:vertexText ofType:GL_VERTEX_SHADER name:&vertShader]) {
        NSLog(@"Failed to compile vertex shader");
    }
    if (![self compileShader:fragmentText ofType:GL_FRAGMENT_SHADER name:&fragShader]) {
        NSLog(@"Failed to compile fragment shader");
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
}

- (BOOL) compileShader:(NSString *)shaderString ofType:(GLenum)type name:(GLuint *)shader
{
    GLint status;
    const GLchar *source = (GLchar *)[shaderString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
	if (status != GL_TRUE) {
		GLint logLength;
		glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
		if (logLength > 0) {
			GLchar *log = (GLchar *)malloc(logLength);
			glGetShaderInfoLog(*shader, logLength, &logLength, log);
			NSLog(@"Shader compile log:\n%s", log);
			free(log);
		}
	}	
    return status == GL_TRUE;
}


program = glCreateProgram();

- (void) unbindAndReleaseShaders
{
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    if (vertShader) {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader) {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    bound = NO;
}

- (void) dealloc
{
    [self unbindAndReleaseShaders];
}

@end
