//  Thin overlay for an OpenGL ES renderbuffer object.

#import "GPUImageBuffer.h"

@interface GPUImageRenderbuffer : GPUImageBuffer

- (id) initWithLayer:(CAEAGLLayer *)layer;

@end
