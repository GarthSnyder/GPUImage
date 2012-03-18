#import "GPUImageProgram.h"
#import "GPUImageShader.h"
#import "GPUImageShaderSymbol.h"
#import "GPUImageTextureUnit.h"

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

@interface GPUImageProgram ()
{
    GPUImageShader *vertexShader;
    GPUImageShader *fragmentShader;
}

- (BOOL) compileShaders;
- (void) delete;
- (void) readSymbols;
- (NSString *) logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunc 
    logFunc:(GLLogFunction)logFunc;

@end

@implementation GPUImageProgram

#pragma mark -
#pragma mark Initialization and shader specification

+ (GPUImageProgram *)program
{
    return [[GPUImageProgram alloc] init];
}

- (GPUImageProgram *) init
{
    if (self = [super init]) {
        self.vertexShader = kGPUImageDefaultVertexShader;
        self.fragmentShader = kGPUImageDefaultFragmentShader;
        programHandle = -1;
        uniforms = [NSMutableDictionary dictionary];
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

#pragma mark Compilation and linking

- (BOOL) use
{
    BOOL status = [self link];
    if (status == YES) {
        glUseProgram(programHandle);
        [self setUniformValues];
    }
    return status;
}

- (BOOL) link
{
    if (programHandle >= 0) {
        return YES; // idempotent
    }
    if ([self compileShaders] == NO) {
        return NO;
    }
    
    programHandle = glCreateProgram();
    
    glAttachShader(programHandle, vertexShader.handle);
    glAttachShader(programHandle, fragmentShader.handle);
    
    glLinkProgram(programHandle);
    glValidateProgram(programHandle);
    
    GLint status;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"%@", [self logs]);
        [self delete];
        return NO;
    }
    return YES;
}

- (BOOL) compileShaders
{
    NSAssert(vertexShader && fragmentShader, @"Need two shaders to compile an OpenGL ES program.");
    return [vertexShader compileAsShaderType:GL_VERTEX_SHADER] &&
        [fragmentShader compileAsShaderType:GL_FRAGMENT_SHADER];
}

#pragma mark Management of uniform values

// Records the value for later use; does not issue any OpenGL commands

- (void) setValue:(id)obj forKey:(NSString *)key
{
    GPUImageShaderSymbol *uniform;
    if ((uniform = [uniforms objectForKey:key])) {
        if ([uniform.value isEqual:obj]) {
            return;
        }
        uniform.value = obj;
    } else {
        uniform = [GPUImageShaderSymbol symbol];
        uniform.name = key;
        uniform.value = obj;
    }
}

- (id) valueForKey:(NSString *)key
{
    GPUImageShaderSymbol *uniform = [uniforms valueForKey:key];
    return uniform ? uniform.value : nil;
}

// Set all uniform values in OpenGL in preparation for drawing. Only sets
// uniforms whose values have changed since the last call. For textures,
// always sets up the appropriate texture units since these setups do not
// stick to the program.

- (void) setUniformValues
{
    for (GPUImageShaderSymbol *uniform in uniforms) {
        [uniform gatherOESDetailsForProgram:programHandle];
        // Make sure textures have a texture unit assigned
        if ([uniform.value isKindOfClass:[GPUImageTexture class]] && !uniform.textureUnit) {
            uniform.textureUnit = [GPUImageTextureUnit unitAtIndex:nextTextureUnit++];
        }
        [uniform setOESValue];
    }
}

#pragma mark -
#pragma mark Logging

- (NSString *) logForOpenGLObject:(GLuint)object 
{
    GLint logLength = 0, charsWritten = 0;
    
    glGetProgramiv(object, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1) {
        return nil;
    }
    
    char *logBytes = malloc(logLength);
    glGetProgramInfoLog(object, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
        length:logLength encoding:NSUTF8StringEncoding];
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

#pragma mark -
#pragma mark Compilation, binding, and unbinding

- (void) delete
{
    if (programHandle >= 0) {
        glDeleteProgram(programHandle);
        programHandle = -1;
    }
}

- (void) dealloc
{
    [self delete];
}

@end
