//  Created by Garth Sndyer on 3/17/12.

#import "GPUImageTextureBuffer.h"

@implementation GPUImageTextureBuffer

@synthesize magnificationFilter = _magnificationFilter;
@synthesize minificationFilter = _minificationFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

- initWithSize:(GLsize)size baseFormat:(GLenum)format depth:(GLenum)depth
{
    if (self = [super init]) {
        glGenTextures(1, &_handle);
        glBindTexture(GL_TEXTURE_2D, _handle);
        glTexImage2D(GL_TEXTURE_2D, 0, format, size.width, size.height, 0,
            format, depth, NULL);
    }
    return self;
}

- initWithSize:(GLsize)size baseType:(GLenum)type
{
    return [self initWithSize:size baseFormat:type depth:GL_UNSIGNED_INT];
}

- (void) setMagnificationFilter:(GLenum)filt
{
    if (filt != _magnificationFilter) {
        _magnificationFilter = filt;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filt);
    }
}

- (void) setMinificationFilter:(GLenum)filt
{
    if (filt != _minificationFilter) {
        _minificationFilter = filt;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filt);
    }
}

- (void) setWrapS:(GLenum)wrap
{
    if (wrap != _wrapS) {
        _wrapS = wrap;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap);
    }
}

- (void) setWrapT:(GLenum)wrap
{
    if (wrap != _wrapT) {
        _wrapT = wrap;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap);
    }
}

- (void) bind
{
    NSAssert(_handle > 0, @"Cannot bind uninitialized texture buffer.");
    glBindTexture(GL_TEXTURE_2D, _handle);
}

- (void) dealloc
{
    if (_handle > 0) {
        glDeleteTextures(1, &_handle);
    }
}

@end


