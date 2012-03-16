// Garth Snyder - 3/14/2012

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTypes.h"

// An object conforming to GPUImageDataFlow is typically a texture object
// or a filter. The general algorithm for implementing update is to first
// update all your parents. If after that any parent has timeLastChanged 
// greater than yours, you must rerender (defined as "do whatever is necessary
// to make yourself current"). After rerendering, set your own timeLastChanged.
// Do not update timeLastChanged unless you actually render.
//
// update should return YES if the update was successful, NO otherwise. If 
// any parent returns NO in response to update, abort immediately and return NO.

@protocol GPUImageFlow <NSObject>

- (void) deriveFrom:(id <GPUImageFlow>)parent;
- (void) undoDerivationFrom:(id <GPUImageFlow>)parent;
- (GPUImageTimestamp) timeLastChanged;
- (BOOL) update;

@end

