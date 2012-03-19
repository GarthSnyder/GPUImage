#import "GPUImageProtocols.h"

// Simple, inheritable implementation of GPUImageFlow protocol.
// See GPUImageProtocols.h for details.

@interface GPUImageElement : NSObject <GPUImageFlow>
{
    NSMutableSet *parents;
    GPUImageTimestamp lastChangeTime;
}

- (BOOL) render;

@end
