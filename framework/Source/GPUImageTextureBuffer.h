//  Created by Garth Snyder on 3/17/12.

#import "GPUImageBuffer.h"

@interface GPUImageTextureBuffer : GPUImageBuffer

@property (nonatomic) GLenum magnificationFilter;
@property (nonatomic) GLenum minificationFilter;
@property (nonatomic) GLenum wrapS;
@property (nonatomic) GLenum wrapT;

@property (readonly, nonatomic) BOOL hasMipmap;

- initWithSize:(GLsize)size baseFormat:(GLenum)format pixType:(GLenum)pix;

- (void) generateMipmap;

@end
