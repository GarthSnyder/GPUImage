//
//  GPUImageShaderSymbol.m
//  GPUImage
//
//  Created by Lion User on 3/15/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageShaderSymbol.h"

@interface GPUImageShaderSymbol ()

- (void) setOESTextureValue;

// Various type-wrangling components
- (BOOL) valueTypeMatchesOESType;
- (NSString *) flattenedObjCType:(NSString *)type;
- (NSString *) flattenedObjCTypeForOESType:(GLenum)type;
- (BOOL) objCTypeIsHomogenous:(NSString *)type;
- (NSUInteger) sizeOfObjCType:(const char *)typeEncoding;

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

+ (GPUImageShaderSymbol *) symbol
{
    return [[GPUImageShaderSymbol alloc] init];
}

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
    _dirty = YES;
}

// Retrieve uniform information from OpenGL if necessary.

- (void) gatherOESDetailsForProgram:(GLint)program
{
    if (self.knowsOESDetails) {
        return;
    }
    const char *name = [_name UTF8String];
    _index = glGetUniformLocation(program, name);
    NSAssert(_index >= 0, @"Unknown uniform '%@'", self.name);
    glGetActiveUniform(program, _index, 0, NULL, &_count, &_type, NULL);
    self.knowsOESDetails = YES;
}

// Communicate uniform value to OES. The relevant program context must already
// be set up.

- (void) setOESValue
{
    if ([_value isKindOfClass:[GPUImageTexture class]]) {
        [self setOESTextureValue];
        return;
    }
    
    if (!_dirty) {
        return;
    }
    
    NSAssert1([_value isKindOfClass:[NSValue class]], 
        @"Value of uniform '%@' is neither NSValue nor GPUImageTexture.", _name);
    NSAssert1([self valueTypeMatchesOESType], 
        @"Value provided for uniform '%@' appears to be of wrong type.", _name);

    NSValue *value = _value;
    NSUInteger valueSize = [self sizeOfObjCType:value.objCType];
    char *buffer = malloc(valueSize);
    [value getValue:buffer];
    
    switch (_type) {
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
            GLboolean *bPtr;
            GLint *iPtr;
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
            NSAssert1(NO, "Unknown OpenGL type for uniform '%@'", self.name);
    }
    self.dirty = NO;
}

- (void) setOESTextureValue
{
    GPUImageTexture *texture = _value;
    NSAssert1(_type == GL_SAMPLER_2D, 
        @"Uniform '%@' has texture value but type != GL_SAMPLER_2D", _name);
    if (_textureUnit.currentTextureHandle != texture.textureHandle) {
        [_textureUnit bindTexture:texture];
        glUniform1i(_index, _textureUnit.textureUnitID);
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
    NSError *err;
    NSString *newString = nil;
    
    // First, collapse all structs to basic types
    NSRegularExpression *deStruct = [NSRegularExpression 
        regularExpressionWithPattern:@"{[^=]+=([^{}]+)}" options:0 error:&err];
    BOOL done = NO;
    do {
        newString = [deStruct stringByReplacingMatchesInString:type
            options:0 range:NSMakeRange(0, [type length]) withTemplate:@"$1"];
        done = [type isEqualToString:newString];
        type = newString;
    } while (!done);
    
    // Then expand [4ff] to 4 x ff (for example)
    NSRegularExpression *findArray = [NSRegularExpression 
        regularExpressionWithPattern:@"\\[(\\d+)([^][{}]+)\\]" options:0 error:&err];
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

- (NSUInteger) sizeOfObjCType:(const char *)typeEncoding
{
    NSUInteger alignedSize, totalSize = 0;
    while (*typeEncoding) {
        typeEncoding = NSGetSizeAndAlignment(typeEncoding, NULL, &alignedSize);
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

- (BOOL) valueTypeMatchesOESType
{
    NSValue *value = _value;
    NSString *objCType = [NSString stringWithCString:value.objCType 
        encoding:NSUTF8StringEncoding];
    objCType = [self flattenedObjCType:objCType];
    if (![self objCTypeIsHomogenous:objCType]) {
        return NO;
    }
    NSString *oesTypeEncoding = [self flattenedObjCTypeForOESType:_type];
    if ([oesTypeEncoding characterAtIndex:0] != [objCType characterAtIndex:0]) {
        return NO;
    }
    int oesTypeLength = [oesTypeEncoding length];
    int totalLength = oesTypeLength * _count;
    return totalLength == [objCType length];
}

// Does the objC type consist of a sequence of exactly one underlying type?

- (BOOL) objCTypeIsHomogenous:(NSString *)type
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
        case GL_BOOL:           // Bools can be either C or i, accept either
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

@end
