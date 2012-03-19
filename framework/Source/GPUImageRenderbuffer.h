//  Created by Garth Snyder on 3/18/12.
//
//  Thin overlay for an OpenGL ES renderbuffer object.

#import "GPUImageBuffer.h"

@interface GPUImageRenderbuffer : GPUImageBuffer

- (id) initWithLayer:(CAEAGLLayer *)layer;

@end
