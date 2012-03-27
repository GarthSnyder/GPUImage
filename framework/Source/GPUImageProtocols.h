// Garth Snyder - 3/14/2012

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"
#import "GPUimageBuffer.h"

// The GPUImageSource protocol lets an object vend its GPUImageBuffer object
// and participate in the GPUImage graph update protocol.
//
// The update protocol is bottom-up: a terminal consumer updates itself, and
// this causes cascading updates from all of that object's suppliers.
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

@protocol GPUImageSource <NSObject>
- (BOOL) update;
- (GPUImageTimestamp) timeLastChanged;
- (GPUImageBuffer *) backingStore;
@end

// The GPUImageConsumer protocol is intentionally agnostic about how many
// ancestors an element might have. Basic texture objects will have only one and 
// should enforce this limit. Objects such as filters may expand their 
// interpretation of -deriveFrom to allow multiple ancestors, or they may
// collect ancestor information implicitly.

@protocol GPUImageConsumer <NSObject>
- (void) deriveFrom:(id <GPUImageSource>)parent; // Pass nil to undo
@end
