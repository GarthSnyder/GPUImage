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

#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>
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
    const char *type = property_getAttributes(prop); // "T<type encoding>,<more stuff>"
    NSString *typeString;
    if (*++type == '@') {
        typeString = @"@"; // NSMethodSignature doesn't like '@"<protocol>"'
    } else {
        const char *comma = type;
        while (*comma != ',') {
            comma++;
        }
        typeString = [[NSString alloc] initWithBytes:(const unichar *)type 
                                                        length:(comma - type)
                                                      encoding:NSASCIIStringEncoding];
    }
    NSString *signature = [NSString stringWithFormat:@"%@@:%@", 
        isSetter ? @"v" : typeString, 
        isSetter ? typeString : @""];
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
    if (isSetter) {
        const char *type = [[anInvocation methodSignature] getArgumentTypeAtIndex:2];
        if (!strcmp(type, "@")) {
            __unsafe_unretained id temp;
            [anInvocation getArgument:&temp atIndex:2]; // Is this ARC-correct?
            [program setValue:temp forKey:selName];
        } else {
            NSUInteger size = [self sizeOfObjCType:type];
            void *buff = malloc(size);
            [anInvocation getArgument:buff atIndex:2];
            [program setValue:[NSValue valueWithBytes:buff objCType:type] forKey:selName];
            free(buff);
        }
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

- (void) setValue:(id)value forKey:(NSString *)key
{
    [self.program setValue:value forKey:key];
}

- (id) valueForKey:(NSString *)key
{
    return [self.program valueForKey:key];
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
