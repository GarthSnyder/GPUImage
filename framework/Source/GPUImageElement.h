#import "GPUImageProtocols.h"

// Simple, inheritable implementation of GPUImageFlow protocol.
// See GPUImageProtocols.h for details.
//
// This class adds the concept of "rendering", i.e., making yourself
// current based on your ancestors. -render is called when the standard
// protocol determines that you're out of date.

@interface GPUImageElement : NSObject <GPUImageFlow>
{
    id <GPUImageFlow> parent;
    GPUImageTimestamp timeLastChanged;
}

- (BOOL) render;

@end
