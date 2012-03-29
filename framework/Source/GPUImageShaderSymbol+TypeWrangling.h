// These methods deal with type matching between OpenGL ES data types 
// and NSValues. They're the messy glue that supports the ability to 
// set uniform values on programs using property syntax, e.g.
//
// program.inputImage = otherFilter

#import "GPUImageShaderSymbol.h"

@interface GPUImageShaderSymbol (TypeChecking)

- (BOOL) valueTypeMatchesOESType;
- (NSString *) flattenedObjCType:(NSString *)type;
- (NSString *) flattenedObjCTypeForOESType:(GLenum)type;
- (BOOL) objCTypeIsHomogenous:(NSString *)type;
- (NSUInteger) sizeOfObjCType:(const char *)typeEncoding;

@end
