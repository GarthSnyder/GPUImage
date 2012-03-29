#import "GPUImageProgram.h"
#import "GPUImageShader.h"
#import "GPUImageShaderSymbol.h"
#import "GPUImageTextureUnit.h"

// Default shaders implement a simple copy operation

NSString *const kGPUImageDefaultVertexShader = SHADER_STRING
(
     attribute vec4 position;
     attribute vec4 inputTextureCoordinate;
     
     varying highp vec2 textureCoordinate;
     
     void main()
     {
         gl_Position = position;
         textureCoordinate = inputTextureCoordinate.xy;
     }
);

NSString *const kGPUImageDefaultFragmentShader = SHADER_STRING
(
     uniform sampler2D inputImage;
     
     varying highp vec2 textureCoordinate;
     
     void main()
     {
         gl_FragColor = texture2D(inputImage, textureCoordinate);
     }
);

@interface GPUImageProgram ()
{
    GPUImageShader *vertexShader;
    GPUImageShader *fragmentShader;
}

- (BOOL) compileShaders;
- (void) delete;
- (void) setValue:(id)obj forKey:(NSString *)key;
- (id) valueForKey:(NSString *)key;
- (void) setUniformValues;

@end

@implementation GPUImageProgram

#pragma mark -
#pragma mark Initialization and shader specification

- (GPUImageProgram *) init
{
    if (self = [super init]) {
        self.vertexShader = kGPUImageDefaultVertexShader;
        self.fragmentShader = kGPUImageDefaultFragmentShader;
        programHandle = -1;
        uniforms = [NSMutableDictionary dictionary];
        attributes = [NSMutableDictionary dictionary];
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

#pragma mark Pass-alongs for default input texture names

- (id <GPUImageSource>) inputImage {
    return [self valueForKey:@"inputImage"];
}

- (id <GPUImageSource>) auxilliaryImage {
    return [self valueForKey:@"auxilliaryImage"];
}

- (void) setInputImage:(id <GPUImageSource>)inputImage {
    [self setValue:inputImage forKey:@"inputImage"];
}

- (void) setAuxilliaryImage:(id <GPUImageSource>)auxImg {
    [self setValue:auxImg forKey:@"auxilliaryImage"];
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

#pragma mark Access to vertex attributes

- (GLint) indexOfAttribute:(NSString *)name
{
    NSNumber *index = [attributes objectForKey:name];
    if (index) {
        return [index intValue];
    }
    if (![self link]) {
        return -1;
    }
    GLint loc = glGetAttribLocation(programHandle, [name UTF8String]);
    [attributes setObject:[NSNumber numberWithInt:loc] forKey:name];
    return loc;
}

#pragma mark Management of uniform values

// Records the value for later use; does not issue any OpenGL commands

- (void) setValue:(id)obj forKey:(NSString *)key
{
    GPUImageShaderSymbol *uniform;
    if ((uniform = [uniforms objectForKey:key])) {
        if (!obj) {
            [uniforms removeObjectForKey:key];
        } else if ([uniform.value isEqual:obj]) {
            return;
        }
        uniform.value = obj;
    } else if (obj) {
        uniform = [[GPUImageShaderSymbol alloc] init];
        uniform.name = key;
        uniform.value = obj;
        [uniforms setObject:uniform forKey:key];
    }
}

- (id) valueForKey:(NSString *)key
{
    GPUImageShaderSymbol *uniform = [uniforms valueForKey:key];
    return uniform ? uniform.value : nil;
}

// Any values set for uniforms that haven't been flushed out?

- (BOOL) hasDirtyUniforms
{
    for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
        if ([uniform dirty]) {
            return YES;
        }
    }
    return NO;
}

// Set all uniform values in OpenGL in preparation for drawing. Only sets
// uniforms whose values have changed since the last call. 

- (void) setUniformValues
{
    for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
        [uniform gatherOESDetailsForProgram:programHandle];
        // Make sure textures have a texture unit assigned
        if ([uniform.value conformsToProtocol:@protocol(GPUImageSource)] && !uniform.textureUnit) {
            uniform.textureUnit = [GPUImageTextureUnit textureUnit];
        }
        [uniform setOESValue];
    }
}

// Returns all uniform values that are GPUImageSources, but only if the 
// uniform is actually used.

- (NSArray *) inputImages
{
    NSMutableArray *ii = [NSMutableArray array];
    for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
        if (!uniform.knowsOESDetails || (uniform.index >= 0)) {
            if ([uniform.value conformsToProtocol:@protocol(GPUImageSource)]) {
                [ii addObject:uniform.value];
            }
        }
    }
    return ii;
}

#pragma mark -
#pragma mark Logging

- (NSString *) programLog 
{
    GLint logLength = 0, charsWritten = 0;
    
    glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1) {
        return nil;
    }
    
    char *logBytes = malloc(logLength);
    glGetProgramInfoLog(programHandle, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
        length:logLength encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}

- (NSString *) logs
{
    return [NSString stringWithFormat:@"%@: %@\n%@: %@\n%@: %@\n",
        @"Vertex shader log", [vertexShader log], 
        @"Fragment shader log", [fragmentShader log],
        @"Program log", [self programLog]];
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
