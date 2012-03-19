//  Created by Garth snyder on 3/17/12.

#import "GPUImageBuffer.h"

static GLuint lastBoundFramebuffer = 0;

static void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation GPUImageBuffer

@synthesize handle = _handle;
@synthesize size = _size;
@synthesize format = _format;
@synthesize fboHandle = _fboHandle;

- (id) initWithSize:(GLsize)size baseFormat:(GLenum)type 
{
    NSAssert(NO, @"GPUImageBuffer subclasses must implement bufferWithSize:baseType:");
    return nil;
}

- (void) bind
{
    // NOP
}

- (void) bindAsFramebuffer
{
    if (!_fboHandle) {
        glGenFramebuffers(1, &_fboHandle);
        glBindFramebuffer(GL_FRAMEBUFFER, _fboHandle);
        glViewport(0, 0, self.size.width, self.size.height);
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    } else if (_fboHandle != lastBoundFramebuffer) {
        glBindFramebuffer(GL_FRAMEBUFFER, _fboHandle);
    }
    lastBoundFramebuffer = _fboHandle;
}

- (void) clearFramebuffer
{
    [self bindAsFramebuffer];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (GLubyte *) rawDataFromFramebuffer
{
    [self bindAsFramebuffer];
    NSUInteger totalBytesForImage = self.size.width * self.size.height * 4;
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    glReadPixels(0, 0, self.size.width, self.size.height, GL_RGBA, 
         GL_UNSIGNED_BYTE, rawImagePixels);
    return rawImagePixels;
}

- (CGImageRef) CGImageFromFramebuffer
{
    GLubyte *rawImagePixels = [self rawDataFromFramebuffer];
    
    NSUInteger totalBytesForImage = self.size.width * self.size.height * 4;
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, 
        rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImageFromBytes = CGImageCreate(self.size.width, self.size.height, 
        8, 32, 4 * self.size.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault, 
        dataProvider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    return cgImageFromBytes;
}

- (void) dealloc
{
    if (_fboHandle) {
        glDeleteFramebuffers(1, &_fboHandle);
    }
}

@end
