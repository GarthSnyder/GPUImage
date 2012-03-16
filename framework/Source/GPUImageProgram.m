#import "GPUImageProgram.h"
#import "GPUImageShader.h"
#import "GPUImageShaderSymbol.h"

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
        uniformValues = [NSMutableDictionary dictionary];
        knownUniforms = [NSMutableDictionary dictionary];
        dirtyUniforms = [NSMutableArray array];
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
        NSLog([self logs]);
        [self delete];
        return NO;
    }
    return YES;
}

- (BOOL) use
{
    BOOL status = [self link];
    if (status == YES) {
        glUseProgram(programHandle);
        [self setUniformValues];
    }
    return status;
}

- (void) validate;
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

#pragma mark Management of uniform values

- (void) setValue:(id)obj forKey:(NSString *)key
{
    id currentValue;
    if ((currentValue = [uniformValues objectForKey:key])) {
        if ([currentValue isEqual:obj]) {
            return;
        }
    }
    [uniformValues setValue:obj forKey:key];
    if (![dirtyUniforms containsObject:key]) {
        [dirtyUniforms addObject:key];
    }
}

- (id) valueForKey:(NSString *)key
{
    return [uniformValues valueForKey:key];
}

// Retrieve symbol information from cache, or query OpenGL. Creates
// the symbol table entry if needed.

- (GPUImageShaderSymbol *) symbolTableEntryForUniformNamed:(NSString *)uniform
{
    GPUImageShaderSymbol *symbol;
    if (!(symbol = [knownUniforms objectForKey:uniform])) {
        const char *name = [uniform UTF8String];
        GLint loc = glGetUniformLocation(programHandle, name);
        NSAssert(loc, @"Unknown uniform '%@'", uniform);
        GLint count;
        GLenum type;
        glGetActiveUniform(programHandle, loc, 0, NULL, &count, &type, NULL);
        symbol = [[GPUImageShaderSymbol alloc] init];
        symbol.name = uniform;
        symbol.count = count;
        symbol.type = type;
        symbol.index = loc;
        if (type == GL_SAMPLER_2D) {
            symbol.textureUnit = GL_TEXTURE0 + nextTextureUnit++;
        }
        [knownUniforms setObject:symbol forKey:uniform];
    }
    return symbol;
}

// Set all uniform values in OpenGL in preparation for drawing. Only sets
// uniforms whose values have changed. Since the last call.

- (void) setUniformValues
{
    for (NSString *uniform in dirtyUniforms) {
        GPUImageShaderSymbol *symbol = [self symbolTableEntryForUniformNamed:uniform];
        id value = [uniformValues objectForKey:uniform];
        if ([value isKindOfClass:[NSValue class]]) {
            [self setValue:value forUniform:symbol];
        } else if ([value isKindOfClass:[GPUImageTexture class]]) {
            glActiveTexture(symbol.textureUnit);
            glBindTexture(GL_TEXTURE_2D, [value textureHandle]);
            glUniform1i(symbol.index, symbol.textureUnit - GL_TEXTURE0);
        } else {
            NSAssert(NO, @"GPUImageProgram uniform values should be NSValues or GPUImageTextures.");
        }
    }
    [dirtyUniforms removeAllObjects];
}

- (void) setValue:(NSValue *)value forUniform:(GPUImageShaderSymbol *)symbol
{
    if (![self actualValue:value matchesOESType:symbol.type count:symbol.count]) {
        NSLog(@"Warning: value provided for uniform '%@' appears to be of wrong type.",
            symbol.name);
    }
    NSUInteger valueSize = [self sizeOfObjCType:value.objCType];
    char *buffer = malloc(valueSize);
    [value getValue:buffer];
    switch (symbol.type) {
        case GL_FLOAT:
            glUniform1fv(symbol.index, symbol.count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC2:
            glUniform2fv(symbol.index, symbol.count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC3:
            glUniform3fv(symbol.index, symbol.count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC4:
            glUniform4fv(symbol.index, symbol.count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT2:
            glUniformMatrix2fv(symbol.index, symbol.count, FALSE, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT3:
            glUniformMatrix3fv(symbol.index, symbol.count, FALSE, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT4:
            glUniformMatrix4fv(symbol.index, symbol.count, FALSE, (GLfloat *)buffer);
            break;
        case GL_INT:
            glUniform1iv(symbol.index, symbol.count, (GLint *)buffer);
            break;
        case GL_INT_VEC2:
            glUniform2iv(symbol.index, symbol.count, (GLint *)buffer);
            break;
        case GL_INT_VEC3:
            glUniform3iv(symbol.index, symbol.count, (GLint *)buffer);
            break;
        case GL_INT_VEC4:
            glUniform4iv(symbol.index, symbol.count, (GLint *)buffer);
            break;
        case GL_BOOL:
        case GL_BOOL_VEC2:
        case GL_BOOL_VEC3:
        case GL_BOOL_VEC4:
            {
                // Boolean values are actually transmitted as ints, so we must convert.
                char *cBuffer =  malloc(valueSize * (sizeof(GLint) / sizeof(GLboolean)));
                GLboolean *bPtr;
                GLint *iPtr;
                for (int i = 0; i < valueSize/sizeof(GLboolean); i++) {
                    *iPtr++ = *bPtr++;
                }
                switch (symbol.type) {
                    case GL_BOOL:
                        glUniform1iv(symbol.index, symbol.count, (GLint *)cBuffer);
                        break;
                    case GL_BOOL_VEC2:
                        glUniform2iv(symbol.index, symbol.count, (GLint *)cBuffer);
                        break;
                    case GL_BOOL_VEC3:
                        glUniform3iv(symbol.index, symbol.count, (GLint *)cBuffer);
                        break;
                    case GL_BOOL_VEC4:
                        glUniform4iv(symbol.index, symbol.count, (GLint *)cBuffer);
                }
            }
            break;
        case GL_SAMPLER_2D:
        case GL_SAMPLER_CUBE:
            NSAssert(NO, "Texture values should not be set in setValue:forUniform:");
            break;
        default:
            NSAssert(NO, "Unknown OpenGL uniform type");
    }
}

- (NSUInteger) sizeOfObjCType:(const char *)typeString
{
    NSUInteger alignedSize, totalSize = 0;
    while (*typeString) {
        typeString = NSGetSizeAndAlignment(typeString, NULL, &alignedSize);
        totalSize += alignedSize;
    }
    return totalSize;
}

// Check to be sure a supplied NSValue actually matches the type of the uniform
// to which it's being assigned. This is for sanity checking only, so the matching
// is lenient.
//
// For example, a uniform vec2 points[2] is ultimately a sequence 
// of 4 floats, and that should match any value that ultimately maps to 4 
// floats, whether that's an array of size 4, a struct of 4 floats, or an
// array of 2 structs with 2 floats each.

- (BOOL) actualValue:(NSValue *)value matchesOESType:(GLenum)type count:(GLint)count
{
    NSString *objCType = [NSString stringWithCString:[value objCType] 
        encoding:NSUTF8StringEncoding];
    objCType = [self flattenedObjCType:objCType];
    if (![self objCTypeIsUniform:objCType]) {
        return NO;
    }
    NSString *oesTypeEncoding = [self flattenedObjCTypeForOESType:type];
    if ([oesTypeEncoding characterAtIndex:0] != [objCType characterAtIndex:0]) {
        return NO;
    }
    int oesTypeLength = [oesTypeEncoding length];
    int totalLength = oesTypeLength * count;
    return totalLength == [objCType length];
}

// Does the objC type consist of a sequence of exactly one underlying type?
- (BOOL) objCTypeIsUniform:(NSString *)type
{
    const char *cPtr = [type UTF8String];
    char firstChar = *cPtr++;
    while (*cPtr) {
        if (*cPtr != firstChar) {
            return NO;
        }
        cPtr++;
    }
    return YES;
}

- (NSString *) flattenedObjCTypeForOESType:(GLenum)type
{
    switch (type) {
        case GL_FLOAT:
            return @"f";
        case GL_FLOAT_VEC2:
            return @"ff";
        case GL_FLOAT_VEC3:
            return @"fff";
        case GL_FLOAT_VEC4:
        case GL_FLOAT_MAT2:
            return @"ffff";
        case GL_FLOAT_MAT3:
            return @"fffffffff";
        case GL_FLOAT_MAT4:
            return @"ffffffffffffffff";
        case GL_INT:
            return @"i";
        case GL_INT_VEC2:
            return @"ii";
        case GL_INT_VEC3:
            return @"iii";
        case GL_INT_VEC4:
            return @"iiii";
        case GL_BOOL:
            return @"C";
        case GL_BOOL_VEC2:
            return @"CC";
        case GL_BOOL_VEC3:
            return @"CCC";
        case GL_BOOL_VEC4:
            return @"CCCC";
        case GL_SAMPLER_2D:
        case GL_SAMPLER_CUBE:
            return @"@";
        default:
            NSAssert(NO, "Unknown OpenGL uniform type");
    }
}

// Convert an Objective-C type encoding to its basic sequence of elements.
// 
// This involves two steps: removing struct decorations and expanding 
// array notation. The former is a simple trimming operation, while the
// latter requires "unrolling" the array by replicating type strings.
//
// For @encode(), int -> 'i', float -> 'f', GLboolean -> 'C', object -> '@'
// Array of 10 mat2's: [10{mat2={vec2=ff}{vec2=ff}}]

- (NSString *) flattenedObjCType:(NSString *)type
{
    NSError *barf;
    NSString *newString = nil;

    // First, collapse all structs to basic types
    NSRegularExpression *deStruct = [NSRegularExpression 
        regularExpressionWithPattern:@"{[^=]+=([^{}]+)}" options:0 error:&barf];
    BOOL done = NO;
    do {
        newString = [deStruct stringByReplacingMatchesInString:type
            options:0 range:NSMakeRange(0, [type length]) withTemplate:@"$1"];
        done = [type isEqualToString:newString];
        type = newString;
    } while (!done);

    // Then expand [4ff] to 4 x ff (for example)
    NSRegularExpression *findArray = [NSRegularExpression 
        regularExpressionWithPattern:@"\\[(\\d+)([^][{}]+)\\]" options:0 error:&barf];
    NSTextCheckingResult *match;
    while ((match = [findArray firstMatchInString:type options:0 range:NSMakeRange(0, [type length])])) {
        NSString *prefix = [type substringToIndex:[match range].location];
        NSString *postfix = [type substringFromIndex:[match range].location
            + [match range].length];
        int arrayLength = [[type substringWithRange:[match rangeAtIndex:1]] intValue];
        NSString *typeSpec = [type substringWithRange:[match rangeAtIndex:2]];
        NSMutableString *newType = [NSMutableString stringWithCapacity:[typeSpec length] * arrayLength];
        for (int i = 0; i < arrayLength; i++) {
            [newType appendString:typeSpec];
        }
        type = [NSString stringWithFormat:@"%@%@%@", prefix, newType, postfix];
    }
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
