#import "GPUImageShaderSymbol.h"
#import "GPUImageShaderSymbol+TypeChecking.h"

@interface GPUImageShaderSymbol ()
- (void) setOESTextureValue;
@end

@implementation GPUImageShaderSymbol

@synthesize name = _name;
@synthesize index = _index;
@synthesize type = _type;
@synthesize count = _count;
@synthesize textureUnit = _textureUnit;
@synthesize value = _value;
@synthesize knowsOESDetails = _knowsOESDetails;
@synthesize dirty = _dirty;

- (id) init
{
    self = [super init];
    self.index = -1;
    // Start dirty because OES binding isn't initially known.
    self.dirty = YES;
    return self;
}

- (void) setValue:(id)value
{
    _value = value;
    self.dirty = YES;
}

- (GPUImageTextureUnit *) textureUnit
{
    // Make sure textures have a texture unit assigned
    if (!_textureUnit && [self.value conformsToProtocol:@protocol(GPUImageSource)]) {
        _textureUnit = [GPUImageTextureUnit textureUnit];
    }
    return _textureUnit;
}

// Retrieve uniform information from OpenGL if necessary.

- (void) gatherOESDetailsForProgram:(GLint)program
{
    if (self.knowsOESDetails) {
        return;
    }
    const char *name = [_name UTF8String];
    self.index = glGetUniformLocation(program, name);
    if (self.index >= 0) { // Allow unused uniforms
        glGetActiveUniform(program, self.index, 0, NULL, &_count, &_type, NULL);
    }
    self.knowsOESDetails = YES;
}

// Communicate uniform value to OES. The relevant program context must already
// be set up.

- (void) setOESValue
{
    if (!self.dirty || (self.index < 0)) {
        return;
    }
    if ([self.value conformsToProtocol:@protocol(GPUImageSource)]) {
        [self setOESTextureValue];
        return;
    }
    
    NSAssert1([self.value isKindOfClass:[NSValue class]], 
        @"Value of uniform '%@' is neither NSValue nor texture provider.", _name);
    NSAssert1([self valueTypeMatchesOESType], 
        @"Value provided for uniform '%@' appears to be of wrong type.", _name);

    NSValue *value = self.value;
    NSUInteger valueSize = [self sizeOfObjCType:value.objCType];
    char *buffer = malloc(valueSize);
    [value getValue:buffer];
    
    switch (self.type) {
        case GL_FLOAT:
            glUniform1fv(_index, _count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC2:
            glUniform2fv(_index, _count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC3:
            glUniform3fv(_index, _count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_VEC4:
            glUniform4fv(_index, _count, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT2:
            glUniformMatrix2fv(_index, _count, FALSE, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT3:
            glUniformMatrix3fv(_index, _count, FALSE, (GLfloat *)buffer);
            break;
        case GL_FLOAT_MAT4:
            glUniformMatrix4fv(_index, _count, FALSE, (GLfloat *)buffer);
            break;
        case GL_INT:
            glUniform1iv(_index, _count, (GLint *)buffer);
            break;
        case GL_INT_VEC2:
            glUniform2iv(_index, _count, (GLint *)buffer);
            break;
        case GL_INT_VEC3:
            glUniform3iv(_index, _count, (GLint *)buffer);
            break;
        case GL_INT_VEC4:
            glUniform4iv(_index, _count, (GLint *)buffer);
            break;
        case GL_BOOL:
        case GL_BOOL_VEC2:
        case GL_BOOL_VEC3:
        case GL_BOOL_VEC4:
        {
            // Boolean values are actually transmitted as ints, so we need to convert.
            char *cBuffer =  malloc(valueSize * (sizeof(GLint) / sizeof(GLboolean)));
            GLboolean *bPtr = (GLboolean *)buffer;
            GLint *iPtr = (GLint *)cBuffer;
            for (int i = 0; i < valueSize/sizeof(GLboolean); i++) {
                *iPtr++ = *bPtr++;
            }
            switch (_type) {
                case GL_BOOL:
                    glUniform1iv(_index, _count, (GLint *)cBuffer);
                    break;
                case GL_BOOL_VEC2:
                    glUniform2iv(_index, _count, (GLint *)cBuffer);
                    break;
                case GL_BOOL_VEC3:
                    glUniform3iv(_index, _count, (GLint *)cBuffer);
                    break;
                case GL_BOOL_VEC4:
                    glUniform4iv(_index, _count, (GLint *)cBuffer);
            }
        }
            break;
        default:
            NSAssert1(NO, @"Unknown OpenGL type for uniform '%@'", self.name);
    }
    self.dirty = NO;
}

- (void) setOESTextureValue
{
    id <GPUImageSource> tBuff = self.value;
    GPUImageTexture *texture = (GPUImageTexture *)tBuff.canvas;
    NSAssert1(self.type == GL_SAMPLER_2D, 
        @"Uniform '%@' has texture value but type != GL_SAMPLER_2D", _name);
    NSAssert1([texture isKindOfClass:[GPUImageTexture class]], 
        @"Value of uniform '%@' is not convertible to a texture buffer", self.name);
    if (self.textureUnit.currentTextureHandle != texture.handle) {
        [_textureUnit bindTexture:texture];
        glUniform1i(self.index, self.textureUnit.textureUnitNumber);
    }
}

@end
