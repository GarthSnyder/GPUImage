#import "GPUImageElement.h"
#import "GPUImageOpenGLESContext.h"

@implementation GPUImageElement

- (void) deriveFrom:(id <GPUImageFlow>)newParent
{
    parent = newParent;
    timeLastChanged = 0; // Force update
}

- (GPUImageTimestamp) timeLastChanged 
{
    return timeLastChanged;
}

- (BOOL) update
{
    if (!parent || ![parent update]) {
        return NO;
    }
    if (self.timeLastChanged < parent.timeLastChanged) {
        [GPUImageOpenGLESContext useImageProcessingContext];
        return [self render];
    }
    return YES;
}

- (BOOL) render
{
    NSAssert(NO, "GPUImageElement subclasses must implement -render");
    return NO;
}

@end
