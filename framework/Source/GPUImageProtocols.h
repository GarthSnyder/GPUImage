// Garth Snyder - 3/14/2012

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// A GPUImageTimestamp is a simple, guaranteed-unique, monotonically increasing
// integer. Used to facilitate flooding of updates through a filter network.

typedef unsigned int GPUImageTimestamp;

extern GPUImageTimestamp GPUImageGetCurrentTimestamp();

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
- (GPUImageTimestamp) timeLastChanged;
- (BOOL) update;

@optional

// Give a hint to a parent that we prefer to consume a renderbuffer rather than
// a texture. Generally of interest only to texture objects that can be a 
// target of rendering. Can potentially avoid a texture-to-renderbuffer
// conversion, but it's a very small optimization.

- (void) requestRenderbuffer;

@end

// Used by some filters

typedef struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
} GPUVector4;

typedef struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
} GPUMatrix4x4;

