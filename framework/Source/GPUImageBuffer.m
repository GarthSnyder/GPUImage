//  Created by Garth snyder on 3/17/12.

#import "GPUImageBuffer.h"

@implementation GPUImageBuffer

@synthesize handle = _handle;

- initWithSize:(GLsize)size baseFormat:(GLenum)type 
{
    NSAssert(NO, @"GPUImageBuffer subclasses must implement initWithSize:baseType:");
    return nil;
}

- (void) bindAsFramebuffer
{
    NSAssert(NO, @"GPUImageBuffer subclasses must implement bind.");
}

@end
