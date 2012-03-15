#import "GPUImageGraphElement.h"

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

- (GPUImageTimestamp) timeLastChanged 
{
    return lastChangeTime;
}

// An object conforming to GPUImageDataFlow is typically a texture object
// or a filter. The general algorithm for implementing update is to first
// update all your parents. If after that any parent has timeLastChanged 
// greater than yours, you must rerender (defined as "do whatever is necessary
// to make yourself current"). After rerendering, set your own timeLastChanged.
// Do not update timeLastChanged unless you actually render.
//
// update should return YES if the update was successful, NO otherwise. If 
// any parent returns NO in response to update, abort immediately and return NO.


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
        [self render];
    }
    return YES;
}

@end
