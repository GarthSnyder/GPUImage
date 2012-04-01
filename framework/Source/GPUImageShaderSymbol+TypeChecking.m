#import "GPUImageShaderSymbol+TypeChecking.h"

@implementation GPUImageShaderSymbol (TypeWrangling)

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
        regularExpressionWithPattern:@"\\{[^=]+=([^{}]+)\\}" options:0 error:&err];
    BOOL done = NO;
    do {
        newString = [deStruct stringByReplacingMatchesInString:type
            options:0 range:NSMakeRange(0, [type length]) withTemplate:@"$1"];
        done = [type isEqualToString:newString];
        type = newString;
    } while (!done);
    
    // Then expand [4ff] to 4 x ff (for example)
    NSRegularExpression *findArray = [NSRegularExpression 
        regularExpressionWithPattern:@"\\[(\\d+)([^\\]\\[]+)\\]" options:0 error:&err];
    NSTextCheckingResult *match;
    while ((match = [findArray firstMatchInString:type options:0 range:NSMakeRange(0, [type length])])) {
        NSRange matchedRange = [match range];
        NSString *prefix = [type substringToIndex:matchedRange.location];
        NSString *postfix = [type substringFromIndex:matchedRange.location
            + matchedRange.length];
        int arrayLength = [[type substringWithRange:[match rangeAtIndex:1]] intValue];
        NSString *typeSpec = [type substringWithRange:[match rangeAtIndex:2]];
        NSMutableString *newType = [NSMutableString stringWithCapacity:[typeSpec length] * arrayLength];
        for (int i = 0; i < arrayLength; i++) {
            [newType appendString:typeSpec];
        }
        type = [NSString stringWithFormat:@"%@%@%@", prefix, newType, postfix];
    }
    return type;
}

- (NSUInteger) sizeOfObjCType:(const char *)typeEncoding
{
    NSUInteger incrementalSize, totalSize = 0;
    while (*typeEncoding) {
        typeEncoding = NSGetSizeAndAlignment(typeEncoding, &incrementalSize, NULL);
        totalSize += incrementalSize;
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

- (BOOL) valueTypeMatchesOpenGLType
{
    NSValue *myValue = self.value;
    NSString *objCType = [NSString stringWithCString:myValue.objCType 
                                            encoding:NSUTF8StringEncoding];
    objCType = [self flattenedObjCType:objCType];
    if (![self objCTypeIsHomogenous:objCType]) {
        return NO;
    }
    NSString *openGLTypeEncoding = [self flattenedObjCTypeForOpenGLType:self.type];
    if ([openGLTypeEncoding characterAtIndex:0] != [objCType characterAtIndex:0]) {
        return NO;
    }
    int openGLTypeLength = [openGLTypeEncoding length];
    int totalLength = openGLTypeLength * self.count;
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

- (NSString *) flattenedObjCTypeForOpenGLType:(GLenum)type
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
            NSAssert(NO, @"Unknown OpenGL uniform type");
    }
    return @"";
}

@end
