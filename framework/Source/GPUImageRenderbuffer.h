//  Thin overlay for an OpenGL ES renderbuffer object.

#import "GPUImageCanvas.h"

@interface GPUImageRenderbuffer : GPUImageCanvas

- (id) initWithLayer:(CAEAGLLayer *)layer;

@end
