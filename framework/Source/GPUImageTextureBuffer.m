#import "GPUImageTextureBuffer.h"

@interface GPUImageTextureBuffer ()
{
    BOOL hasBoundTextureToFramebuffer;
}
@end

@implementation GPUImageTextureBuffer

@synthesize magFilter = _magFilter;
@synthesize minFilter = _minFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

@synthesize hasMipmap = _hasMipmap;
@synthesize pixType = _pixType;

static GLint lastBoundTexture = -1;

- initWithSize:(GLsize)size baseFormat:(GLenum)format pixType:(GLenum)pix
{
    if (self = [super init]) {
        glGenTextures(1, &_handle);
        glBindTexture(GL_TEXTURE_2D, _handle);
        glTexImage2D(GL_TEXTURE_2D, 0, format, size.width, size.height, 0,
            format, pix, NULL);
        _size = size;
        _format = format;
        _pixType = pix;
    }
    return self;
}

- initWithSize:(GLsize)size baseType:(GLenum)type
{
    return [self initWithSize:size baseFormat:type pixType:GL_UNSIGNED_INT];
}

- initWithTexture:(GLint)texHandle size:(GLsize)size format:(GLenum)fmt
{
    if (self = [super init]) {
        _handle = texHandle;
        _size = size;
        _format = fmt;
        _pixType = GL_UNSIGNED_BYTE;
    }
    return self;
}

- (void) setMagFilter:(GLenum)filt
{
    if (filt != _magFilter) {
        _magFilter = filt;
        [self bind];
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filt);
    }
}

- (void) setMinFilter:(GLenum)filt
{
    if (filt != _minFilter) {
        _minFilter = filt;
        [self bind];
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filt);
    }
}

- (void) setWrapS:(GLenum)wrap
{
    if (wrap != _wrapS) {
        _wrapS = wrap;
        [self bind];
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap);
    }
}

- (void) setWrapT:(GLenum)wrap
{
    if (wrap != _wrapT) {
        _wrapT = wrap;
        [self bind];
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap);
    }
}

// TODO: Generate mipmaps for non-square/non-power-of-two images

- (void) generateMipmap:(BOOL)force
{
    if (force || !self.hasMipmap) {
        unsigned int uWidth = self.size.width;
        unsigned int uHeight = self.size.height;
        // x & (x - 1) flips the rightmost 1 bit of x to 0
        // power of two -> only one 1 bit
        BOOL widthIsPowerOf2 = ((uWidth & (uWidth - 1)) == 0);
        BOOL heightIsPowerOf2 = ((uHeight & (uHeight - 1)) == 0);
        NSAssert(widthIsPowerOf2 && heightIsPowerOf2 && (uWidth == uHeight),
            @"Mipmaps for non-square or non-power-of-two textures are not yet implemented.");
        [self bind];
        glGenerateMipmap(GL_TEXTURE_2D);
        _hasMipmap = YES;
    }
}

- (void) bind
{
    NSAssert(_handle > 0, @"Cannot bind uninitialized texture buffer.");
    if (lastBoundTexture != _handle) {
        glBindTexture(GL_TEXTURE_2D, _handle);
        lastBoundTexture = _handle;
    }
}

- (void) bindAsFramebuffer
{
    [super bindAsFramebuffer];
    if (!hasBoundTextureToFramebuffer) {
        hasBoundTextureToFramebuffer = YES;
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.handle, 0);
    }
}

- (void) dealloc
{
    if (_handle > 0) {
        glDeleteTextures(1, &_handle);
        if (lastBoundTexture == _handle) {
            lastBoundTexture = -1;
        }
    }
}

@end


