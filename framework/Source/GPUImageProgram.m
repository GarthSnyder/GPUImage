#import "GPUImageProgram.h"


#pragma mark -
#pragma mark Private GPUImageShader class



#pragma mark -
#pragma mark GPUImageProgram material

@interface GPUImageProgram ()
{
    GLuint programName;
    GPUImageShader *vertexShader, *fragmentShader;
}

- (BOOL) compileShaders;
- (void) delete;
- (NSString *) logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunc 
    logFunc:(GLLogFunction)logFunc;

@end

@implementation GPUImageProgram

#pragma mark Initialization and shader specification

+ (GPUImageProgram *)program
{
    return [[GPUImageProgram alloc] init];
}

- (GPUImageProgram *)init
{
    if (self = [super init]) {
        self.vertexShader = kGPUImageDefaultVertexShader;
        self.fragmentShader = kGPUImageDefaultFragmentShader;
    }
    return self;
}

- (void) setVertexShader:(NSString *)vsText {
    vertexShader = [[GPUImageShader alloc] initWithSourceText:vsText];
}

- (void) setVertexShaderFilename:(NSString *)vsFile {
    vertexShader = [[GPUImageShader alloc] initWithFilename:vsFile];
}

- (void) setFragmentShader:(NSString *)fsText {
    fragmentShader = [[GPUImageShader alloc] initWithSourceText:fsText];
}

- (void) setFragmentShaderFilename:(NSString *)fsFile {
    fragmentShader = [[GPUImageShader alloc] initWithFilename:fsFile];
}

- (NSString *) vertexShader {
    NSAssert(NO, @"GPUImageProgram: vertexShader property is write-only.");
}

- (NSString *) vertexShaderFilename {
    NSAssert(NO, @"GPUImageProgram: vertexShaderFilename property is write-only.");
}

- (NSString *) fragmentShader {
    NSAssert(NO, @"GPUImageProgram: fragmentShader property is write-only.");
}

- (NSString *) fragmentShaderFilename {
    NSAssert(NO, @"GPUImageProgram: fragmentShaderFilename property is write-only.");
}

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

#pragma mark -

- (BOOL) compileShaders
{
    if (!vertexShader || !fragmentShader) {
        NSLog(@"GPUImageProgram: Need two shaders to compile.");
    }
    return [vertexShader compileAsShaderType:GL_VERTEX_SHADER] &&
        [fragmentShader compileAsShaderType:GL_FRAGMENT_SHADER];
}

- (BOOL) link
{
    if (programName) {
        return YES; // idempotent
    }
    if ([self compileShaders] == NO) {
        return NO;
    }
    
    programName = glCreateProgram();
    
    glAttachShader(programName, vertexShader.shaderName);
    glAttachShader(programName, fragmentShader.shaderName);
    
    glLinkProgram(programName);
    glValidateProgram(programName);
    
    GLint status;
    glGetProgramiv(programName, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        [self delete];
    }
    return YES;
}

- (BOOL) use
{
    BOOL status = [self link];
    if (status == YES) {
        glUseProgram(programName);
        status = [self set
    }
    return status;
}

#pragma mark -
#pragma mark Logging

- (NSString *) logForOpenGLObject:(GLuint)object 
{
    GLint logLength = 0, charsWritten = 0;
    
    glGetProgramiv(object, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1)
        return nil;
    
    char *logBytes = malloc(logLength);
    glGetProgramInfoLog(object, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
                                              length:logLength 
                                            encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}

- (NSString *) vertexShaderLog
{
    return [self logForOpenGLObject:vertShader];
}
                  
- (NSString *) fragmentShaderLog
{
    return [self logForOpenGLObject:fragShader];
}
                  
- (NSString *) programLog
{
    return [self logForOpenGLObject:program]; 
}

- (NSString *) logs
{
    return [NSString stringWithFormat:@"%@: %@\n%@: %@\n%@: %@\n",
        "Vertex shader log", [self vertexShaderLog], 
        "Fragment shader log", [self fragmentShaderLog],
        "Program log", [self programLog]];
}

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
    [self deleteComponents];
    
    NSString *vertexText = _vertexShader ? _vertexShader : 
        [self getShaderTextFromFile:_vertexShaderFilename];
    NSString *fragmentText = _fragmentShader ? _fragmentShader : 
        [self getShaderTextFromFile:_fragmentShaderFilename];
    
    if (!vertexText || !fragmentText) {
        NSLog(@"GPUImageProgram::compileShaders called with missing shader");
        return NO;
    }

    if (![self compileShader:vertexText ofType:GL_VERTEX_SHADER name:&vertShader]) {
        NSLog(@"Failed to compile vertex shader");
    }
    if (![self compileShader:fragmentText ofType:GL_FRAGMENT_SHADER name:&fragShader]) {
        NSLog(@"Failed to compile fragment shader");
    }
}

- (void) delete
{
    if (programName) {
        glDeleteProgram(programName);
        programName = 0;
    }
}

- (void) dealloc
{
    [self delete];
}
                  
                  - (void)setInteger:(GLint)newInteger forUniform:(NSString *)uniformName;
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
            [filterProgram use];
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            
            glUniform1i(uniformIndex, newInteger);
        }
                  
                  - (void)setFloat:(GLfloat)newFloat forUniform:(NSString *)uniformName;
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
            [filterProgram use];
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            
            glUniform1f(uniformIndex, newFloat);
        }
                  
                  - (void)setSize:(CGSize)newSize forUniform:(NSString *)uniformName;
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
            [filterProgram use];
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            GLfloat sizeUniform[2];
            sizeUniform[0] = newSize.width;
            sizeUniform[1] = newSize.height;
            
            glUniform2fv(uniformIndex, 1, sizeUniform);
        }
                  
                  - (void)setPoint:(CGPoint)newPoint forUniform:(NSString *)uniformName;
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
            [filterProgram use];
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            GLfloat sizeUniform[2];
            sizeUniform[0] = newPoint.x;
            sizeUniform[1] = newPoint.y;
            
            glUniform2fv(uniformIndex, 1, sizeUniform);
        }
                  
                  - (void)setFloatVec3:(GLfloat *)newVec3 forUniform:(NSString *)uniformName;
        {
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            [filterProgram use];
            
            glUniform3fv(uniformIndex, 1, newVec3);    
        }
                  
                  - (void)setFloatVec4:(GLfloat *)newVec4 forUniform:(NSString *)uniformName;
        {
            GLint uniformIndex = [filterProgram uniformIndex:uniformName];
            [filterProgram use];
            
            glUniform4fv(uniformIndex, 1, newVec4);    
        }
                  
                  - (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName {
                      [GPUImageOpenGLESContext useImageProcessingContext];
                      [filterProgram use];
                      GLint uniformIndex = [filterProgram uniformIndex:uniformName];
                      
                      glUniform1fv(uniformIndex, count, array);
                  }


@end
