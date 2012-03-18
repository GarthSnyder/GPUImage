#import "GPUImageGraphElement.h"
#import "GPUImageOpenGLESContext.h"

@implementation GPUImageGraphElement

- (id) init
{
    if (self = [super init]) {
        parents = [NSMutableSet set];
    }
    return self;
}

- (void) deriveFrom:(id <GPUImageFlow>)parent
{
    [parents addObject:self];
    lastChangeTime = 0; // Force update
}

- (void) undoDerivationFrom:(id<GPUImageFlow>)parent
{
    [parents removeObject:parent];
}

- (GPUImageTimestamp) timeLastChanged 
{
    return lastChangeTime;
}

- (BOOL) update
{
    GPUImageTimestamp mostRecentParentUpdate = 0;
    
    for (id <GPUImageFlow> parent in parents) {
        if (![parent update]) {
            return NO;
        }
        GPUImageTimestamp parentUpdate = [parent timeLastChanged];
        if (mostRecentParentUpdate < parentUpdate) {
            mostRecentParentUpdate = parentUpdate;
        }
    }
    
    if (self.timeLastChanged < mostRecentParentUpdate) {
        [GPUImageOpenGLESContext useImageProcessingContext];
        [self render];
    }
    return YES;
}

- (BOOL) render
{
    NSAssert(NO, "GPUImageGraphElement subclasses must implement -render");
    return NO;
}

@end
