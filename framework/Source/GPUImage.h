#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "GPUImageHeaders.h"

@interface GPUImage : GPUImageElement

@property (nonatomic) GLsize size;
@property (nonatomic) GLenum baseFormat;
@property (nonatomic) GLenum pixType;

// Setting an associated layer automatically turns on useRenderbuffer.
// However, you can use a renderbuffer without an associated CAEAGLLayer.

@property (assign, nonatomic) CAEAGLLayer *layer;   // Associated layer, if any
@property (nonatomic) BOOL useRenderbuffer;

@property (nonatomic) GLenum wrapS;
@property (nonatomic) GLenum wrapT;
@property (nonatomic) GLenum magnificationFilter;
@property (nonatomic) GLenum minificationFilter;
@property (nonatomic) BOOL generateMipmap;

// For setting both filters or both wraps at once
@property (nonatomic) GLenum filter;
@property (nonatomic) GLenum wrap;

// Let the texture manage this! Not part of the general API.
@property (strong, nonatomic) GPUImageBuffer *backingStore;

+ (id) texture;

- (void) bindAsFramebuffer;

// Adopts size and base format only, and only if receiver's are unknown
- (void) adoptParametersFrom:(GPUImage *)other;

- (GLuint *) getRawContents;
- (CGImageRef) convertToCGImage;
- (UIImage *) convertToUIImage;

@end
