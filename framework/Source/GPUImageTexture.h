#import "GPUImageGraphElement.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "GPUImageBuffer.h"

@interface GPUImageTexture : GPUImageGraphElement

@property (nonatomic) GLsize size;
@property (nonatomic) GLenum baseFormat;
@property (nonatomic) GLenum magnificationFilter;
@property (nonatomic) GLenum minificationFilter;
@property (nonatomic) GLenum wrapS;
@property (nonatomic) GLenum wrapT;

// For setting both filters or both wraps at once
@property (nonatomic) GLenum filter;
@property (nonatomic) GLenum wrap;

// Let the texture manage this! Not part of the general API.
@property (nonatomic) GPUImageBuffer *backingStore;

+ (id) texture;

- (GLint) textureHandle;

- (void) makeRenderbuffer;
- (BOOL) isRenderbuffer;

- (void) bindAsFramebuffer;
- (void) generateMipmap;

// Adopts size and base format only, and only if unknown
- (void) adoptParametersFrom:(GPUImageTexture *)other;

- (UIImage *) convertToUIImage;

@end

