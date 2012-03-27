// This category allows filters to tie properties directly to shader program
// uniforms without having to provide glue methods. For example, if the
// filter's .h file declares
//
// @property (nonatomic) GLFloat gamma;
//
// Then this category automatically implements the equivalent of the following
// methods:
//
// - (void) setGamma:(CGFloat)newValue {
//     [program setValue:UNIFORM(newValue) forKey:@"gamma"];
// }
//
// - (CGFloat) gamma {
//     return [[program valueForKey:@"gamma"] floatValue];
// }

#import "GPUImageFilter.h"

@interface GPUImageFilter (Uniforms)
- (NSUInteger) sizeOfObjCType:(const char *)typeEncoding;
@end

@implementation GPUImageFilter (Uniforms)

- (NSMethodSignature *) methodSignatureForSelector:(SEL)sel
{
    NSString *selName = NSStringFromSelector(sel);
    BOOL isSetter = NO;
    
    if ([selName hasPrefix:@"set"]) {
        // setFoo: -> foo
        selName = [NSString stringWithFormat:@"%c%@", tolower([selName characterAtIndex:3]),
            [[selName substringFromIndex:4] stringByReplacingOccurrencesOfString:@":" withString:@""]];
        isSetter = YES;
    }
    objc_property_t prop = class_getProperty([self class], [selName UTF8String]);
    if (!prop) {
        return [super methodSignatureForSelector:sel];
    }
    const char *type = property_getTypeString(prop);
    NSString *signature = [NSString stringWithFormat:@"%s@:%s", 
        isSetter ? "v" : type, 
        isSetter ? type : ""];
    return [NSMethodSignature signatureWithObjCTypes:[signature UTF8String]];
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selName = NSStringFromSelector(anInvocation.selector);
    BOOL isSetter = NO;
    
    if ([selName hasPrefix:@"set"]) {
        // setFoo: -> foo
        selName = [NSString stringWithFormat:@"%c%@", tolower([selName characterAtIndex:3]),
                    [[selName substringFromIndex:4] stringByReplacingOccurrencesOfString:@":" withString:@""]];
        isSetter = YES;
    }
    objc_property_t prop = class_getProperty([self class], [selName UTF8String]);
    if (!prop) {
        return [super forwardInvocation:anInvocation];
    }
    const char *type = property_getTypeString(prop);
    if (isSetter) {
        const char *type = [[anInvocation methodSignature] getArgumentTypeAtIndex:2];
        NSUInteger size = [self sizeOfObjCType:type];
        void *buff = malloc(size);
        [anInvocation getArgument:buff atIndex:2];
        if (!strcmp(type, "@")) {
            [program setValue:*((id *)buff) forKey:selName];
        } else {
            [program setValue:[NSValue valueWithBytes:buff objCType:type] forKey:selName];
        }
        free(buff);
    } else {
        id value = [program valueForKey:selName];
        if ([value isKindOfClass:[NSValue class]]) {
            NSUInteger size = [self sizeOfObjCType:[value objCType]];
            void *buff = malloc(size);
            [value getValue:buff];
            [anInvocation setReturnValue:buff];
            free(buff);
        } else {
            [anInvocation setReturnValue:&value];
        }
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

@end
