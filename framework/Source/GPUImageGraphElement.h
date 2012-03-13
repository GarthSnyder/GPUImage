#import "GPUImageProtocols.h"

// Simple, inheritable implementation of GPUImageFlow protocol.
// See GPUImageProtocols.h for details.

@interface GPUImageGraphElement : NSObject <GPUImageFlow>
{
    NSMutableSet *parents;
    GPUImageTimestamp lastChangeTime;
}

// Do whatever is needed to make myself current. Return NO on error.
- (BOOL) render;

@end
