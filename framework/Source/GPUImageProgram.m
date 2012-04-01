#import <objc/runtime.h>
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
- (BOOL) validateUniforms;

@end

@implementation GPUImageProgram

@synthesize delegate = _delegate;

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
    BOOL status = [self validateUniforms]; // Links
    if (status == YES) {
        glUseProgram(programHandle);
        for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
            [uniform setOpenGLValue];
        }
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

// Returns all uniform values that are GPUImageSources, but only if the 
// uniform is actually used.

- (NSArray *) inputImages
{
    NSMutableArray *inputs = [NSMutableArray array];
    if ([self validateUniforms]) {
        for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
            if (uniform.index >= 0) {
                if ([uniform.value conformsToProtocol:@protocol(GPUImageSource)]) {
                    [inputs addObject:uniform.value];
                }
            }
        }
    }
    return inputs;
}

- (BOOL) validateUniforms
{
    BOOL droppedMarker = NO;
    BOOL status;
    if ((status = [self link])) {
        for (GPUImageShaderSymbol *uniform in [uniforms allValues]) {
            if (!uniform.knowsOpenGLDetails) {
                if (!droppedMarker) {
                    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Validate uniforms: %s", 
                        class_getName([self class])] UTF8String]);
                    droppedMarker = YES;
                }
                [uniform gatherOpenGLDetailsForProgram:programHandle];
            }
        }
    }
    if (droppedMarker) {
        glPopGroupMarkerEXT();
    }
    return status;
}

#pragma mark -
#pragma mark Drawing

- (void) draw
{
    [self drawWithVertices:NULL textureCoordinates:NULL];
}

- (void) drawWithOrientation:(GPUImageOutputOrientation)orientation textureCoordinates:(const GLfloat *)t
{
    if (orientation == kGPUImageNoRotation) {
        [self drawWithVertices:NULL textureCoordinates:t];
        return;
    }
    
    static const GLfloat rotateRight[] = {
        -1.0,  1.0,
        -1.0, -1.0,
        1.0,  1.0,
        1.0, -1.0,
    };

    static const GLfloat rotateLeft[] = {
        1.0, -1.0,
        1.0, 1.0,
        -1.0, -1.0,
        -1.0, 1.0
    };

    static const GLfloat rotate180Degrees[] = {
        1.0, 1.0,
        -1.0, 1.0,
        1.0, -1.0,
        -1.0, -1.0
    };

    static const GLfloat flipVertical[] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0,  -1.0,
        1.0,  -1.0,
    };

    static const GLfloat flipHorizontal[] = {
        1.0, -1.0,
        -1.0, -1.0,
        1.0,  1.0,
        -1.0,  1.0,
    };

    static const GLfloat flip45Degrees[] = {
        1.0, 1.0,
        1.0, -1.0,
        -1.0, 1.0,
        -1.0, -1.0
    };

    static const GLfloat flipMinus45Degrees[] = {
        -1.0, -1.0,
        -1.0, 1.0,
        1.0, -1.0,
        1.0, 1.0
    };

    const GLfloat *vertices;
    switch (orientation)
    {
        case kGPUImageRotateLeft: 
            vertices = rotateLeft;
            break;
        case kGPUImageRotateRight: 
            vertices = rotateRight;
            break;
        case kGPUImageRotate180Degrees:
            vertices = rotate180Degrees;
            break;
        case kGPUImageFlipHorizontal: 
            vertices = flipHorizontal;
            break;
        case kGPUImageFlipVertical: 
            vertices = flipVertical;
            break;
        case kGPUImageFlip45Degrees: 
            vertices = flip45Degrees;
            break;
        case kGPUImageFlipMinus45Degrees: 
            vertices = flipMinus45Degrees;
            break;
        default:
            NSAssert1(NO, @"Unknown orientation: %d", (int)orientation);
    }
    [self drawWithVertices:vertices textureCoordinates:t];
}

- (void) drawWithVertices:(const GLfloat *)v textureCoordinates:(const GLfloat *)t
{
    static const GLfloat squareVertices[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0,  1.0,
        1.0,  1.0,
    };
    
    static const GLfloat squareTextureCoordinates[] = {
        0.0,  0.0,
        1.0,  0.0,
        0.0,  1.0,
        1.0,  1.0,
    };
    
    if (!v) {
        v = squareVertices;
    }
    if (!t) {
        t = squareTextureCoordinates;
    }

    if (self.delegate) {
        [self.delegate programWillDraw:self];
    }
    [self use];
    
    GLint position = [self indexOfAttribute:@"position"];
    GLint itc = [self indexOfAttribute:@"inputTextureCoordinate"];
    
    glVertexAttribPointer(position, 2, GL_FLOAT, 0, 0, v);
    glEnableVertexAttribArray(position);
    
    glVertexAttribPointer(itc, 2, GL_FLOAT, 0, 0, t);
    glEnableVertexAttribArray(itc);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
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
