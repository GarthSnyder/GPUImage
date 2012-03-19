// Garth Snyder - 3/14/2012

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"

// An object conforming to GPUImageFlow can participate in GPUImage's 
// rendering tree. The flow is bottom-up.
//
// To update itself, an object first calls -update on all the objects from
// which it derives. It then compares its modification timestamp with the
// timestamps of those ancestors. If any ancestor was updated more recently,
// the object must rerender itself. ("Render" is defined as "doing whatever
// is necessary to make yourself current" and need not involve actual
// drawing or even any OpenGL changes.)
//
// An object should not update its timeLastChanged unless it actually renders.
//
// -update should return YES if the update was successful, NO otherwise. If 
// any parent returns NO in response to update, abort immediately and return NO.
//
// Note: this base protocol is intentionally agnostic about how many ancestors
// an element may have. Basic texture objects will have only one and 
// should enforce this limit. Objects such as filters may expand their 
// interpretation of -deriveFrom to allow multiple ancestors, or they may
// collect ancestor information implicitly.

@protocol GPUImageFlow <NSObject>

- (void) deriveFrom:(id <GPUImageFlow>)parent; // Pass nil to undo
- (GPUImageTimestamp) timeLastChanged;
- (BOOL) update;

@end
