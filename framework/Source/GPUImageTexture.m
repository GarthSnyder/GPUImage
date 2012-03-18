//
//  GPUImageTexture.m
//  GPUImage
//
//  Created by Lion User on 3/14/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageTexture.h"
#import "GPUImageTextureBuffer.h"
// #import "GPUImageRenderbuffer.h"

@interface GPUImageTexture ()
{
    BOOL _renderbufferRequested;
}

- (void) disposeBacking;

@end

@implementation GPUImageTexture

@synthesize size = _size;
@synthesize baseFormat = _baseFormat;
@synthesize magnificationFilter = _magnificationFilter;
@synthesize minificationFilter = _minificationFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

@synthesize backingStore = _backingStore;

#pragma mark -
#pragma mark Basic setup and accessors

+ (id) texture
{
    return [[GPUImageTexture alloc] init];
}

- (GLenum) filter
{
    NSAssert(self.magnificationFilter == self.minificationFilter, 
        @"GPUImageTexture::filter called when filters have inconsistent values");
    return self.magnificationFilter;
}

- (void) setFilter:(GLenum)filter
{
    self.magnificationFilter = filter;
    self.minificationFilter = filter;
}

- (GLenum) wrap
{
    NSAssert(self.wrapS == self.wrapT, 
        @"GPUImageTexture::wrap called when S and T wraps have inconsistent values");
    return self.wrapS;
}

- (void) setWrap:(GLenum)wrap
{
    self.wrapS = wrap;
    self.wrapT = wrap;
}

- (void) adoptParametersFrom:(GPUImageTexture *)other
{
    GLsize newSize = self.size;
    if (!newSize.width || !newSize.height) {
        newSize = other.size;
        self.size = newSize;
    }
    
    if (!self.baseFormat) {
        self.baseFormat = other.baseFormat;
    }
}

- (void) makeRenderbuffer
{
    if (!self.isRenderbuffer) {
        self.backingStore = nil;
        _renderbufferRequested = YES;
    }
}
     
- (BOOL) isRenderbuffer
{
    return _renderbufferRequested;
}

#pragma mark -
#pragma mark Rendering and buffer management

// Rendering/updating can mean several different things in the context of a 
// texture:
//
// If our parent is a filter (that is, anything other than another texture),
// then this texture is a rendering destination. We need do nothing at 
// rendering time because the drawing has already occurred -- the parent filter
// called bindAsFramebuffer on us when it was ready to draw, and the backing
// store was validated at that time.
//
// If our parent is another texture, then this texture's contents are expected
// to reflect that texture's contents after rendering.
//
// If our size and color model are compatible with the parent texture's settings,
// we can simply share that texture's backing store and set ancillary params
// as needed. (It's fine to override the parent's filter and wraps because the
// parent will reset them when it next gets drawn into.)
//
// If our parent is a texture of incompatible size or backing store, then we
// need to do a conversion. This is currently unimplemented but would be 
// straightforward to add.
//
// The GPUImageFlow protocol allows multiple parents, but textures should only
// have one parent. What would it mean to reflect two other textures or be
// the end product of multiple filters?

- (BOOL) render
{
    NSAssert([parents count] == 1, @"Textures should have only one parent.");
    if (![[parents anyObject] isKindOfClass:[GPUImageTexture class]]) {
        return YES;
    }
    
    GPUImageTexture *parent = [parents anyObject];
    NSAssert(![self parentRequiresConversion:parent],
        @"Automatic texture size and format conversions are not yet supported.");
    _backingStore = [parent backingStore];
    [self setTextureParams];
    return YES;
}

- (void) setTextureParams
{
    GPUImageTextureBuffer *store = self.backingStore;
    if (self.isRenderbuffer || !store) {
        return;
    }
    [store bind];
    if (self.magnificationFilter > 0) {
        store.magnificationFilter = self.magnificationFilter;
    }
    if (self.minificationFilter > 0) {
        store.minificationFilter = self.minificationFilter;
    }
    if (self.wrapS > 0) {
        store.wrapS = self.wrapS;
    }
    if (self.wrapT > 0) {
        store.wrapT = self.wrapT;
    }
}

- (void) bindAsFramebuffer
{
    if (self.backingStore) {
        [self.backingStore bindAsFramebuffer];
        return;
    }
}

- (void) generateMipmap;


- (UIImage *) convertToUIImage;

@end

GL_ALPHA              
GL_RGB                
GL_RGBA               
GL_LUMINANCE          
GL_LUMINANCE_ALPHA    


- (void)initializeOutputTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &outputTexture);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)setFilterFBO;
{
    if (!filterFramebuffer)
    {
        CGSize currentFBOSize = [self sizeOfFBO];
        [self createFilterFBOofSize:currentFBOSize];
        [self setupFilterForSize:currentFBOSize];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
    
    CGSize currentFBOSize = [self sizeOfFBO];
    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
}

- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &filterFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
    
    //    NSLog(@"Filter size: %f, %f", currentFBOSize.width, currentFBOSize.height);
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)destroyFilterFBO;
{
    if (filterFramebuffer)
	{
		glDeleteFramebuffers(1, &filterFramebuffer);
		filterFramebuffer = 0;
	}	
}

void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}



- (UIImage *) imageFromCurrentlyProcessedOutput;
{
    [self setOutputFBO];
    
    CGSize currentFBOSize = [self sizeOfFBO];
    
    NSUInteger totalBytesForImage = (int)currentFBOSize.width * (int)currentFBOSize.height * 4;
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    glReadPixels(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImageFromBytes = CGImageCreate((int)currentFBOSize.width, (int)currentFBOSize.height, 8, 32, 4 * (int)currentFBOSize.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *finalImage = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:UIImageOrientationLeft];
    
    CGImageRelease(cgImageFromBytes);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    //    free(rawImagePixels);
    
    return finalImage;
}


- clear

glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
glClear(GL_COLOR_BUFFER_BIT);


@end
