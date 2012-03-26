// Garth Snyder - 3/14/2012

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"
#import "GPUimageBuffer.h"

// The GPUImageSource protocol lets an object vend its
// GPUImageBuffer object, which wraps its renderbuffer or texture buffer
// and FBO. The caller may adjust scalar attributes of the buffer (e.g.,
// texture edge treatment params), but should not change the contents. This
// convention allows efficient sharing of texture buffers, since buffers
// can often be treated as logically separate even if they share an OpenGL
// buffer.
//
// All objects that participate in a filter graph should implement 
// GPUImageUpdating, but terminal objects (that is, objects that are image
// consumers only) need not implement GPUImageSource.

@protocol GPUImageSource <NSObject>

- (GPUImageBuffer *) backingStore;

@end

// An object conforming to GPUImageUpdating can participate in GPUImage's 
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

@protocol GPUImageUpdating <NSObject>

typedef id <GPUImageUpdating, GPUImageSource> GPUImageSource;

- (void) deriveFrom:(GPUImageSource)parent; // Pass nil to undo
- (GPUImageTimestamp) timeLastChanged;
- (BOOL) update;

@end
