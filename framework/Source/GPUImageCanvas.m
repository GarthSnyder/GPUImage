#import "GPUImageCanvas.h"
#import "GPUImageTexture.h"

static GLuint lastBoundFramebuffer = 0;

static void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation GPUImageCanvas

@synthesize handle = _handle;
@synthesize size = _size;
@synthesize format = _format;
@synthesize fboHandle = _fboHandle;

- (id) initWithSize:(GLsize)size baseFormat:(GLenum)type 
{
    NSAssert(NO, @"GPUImageCanvas subclasses must implement bufferWithSize:baseType:");
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
    } else if (_fboHandle != lastBoundFramebuffer) {
        glBindFramebuffer(GL_FRAMEBUFFER, _fboHandle);
        glViewport(0, 0, self.size.width, self.size.height);
    }
    lastBoundFramebuffer = _fboHandle;
}

- (BOOL) validateFramebuffer
{
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Incomplete framebuffer: %d", status);
    }
    return status == GL_FRAMEBUFFER_COMPLETE;
}

- (void) clearFramebuffer:(vec4)bc
{
    [self bindAsFramebuffer];
    glClearColor(bc.vec4[0], bc.vec4[1], bc.vec4[2], bc.vec4[3]);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (GLubyte *) copyRawDataFromFramebuffer
{
    [self bindAsFramebuffer];
    NSUInteger totalBytesForImage = self.size.width * self.size.height * 4;
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    glReadPixels(0, 0, self.size.width, self.size.height, GL_RGBA, 
         GL_UNSIGNED_BYTE, rawImagePixels);
    return rawImagePixels;
}

- (CGImageRef) copyCGImageFromFramebuffer
{
    GLubyte *rawImagePixels = [self copyRawDataFromFramebuffer];
    
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
