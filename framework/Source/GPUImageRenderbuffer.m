#import <QuartzCore/QuartzCore.h>
#import "GPUImageRenderbuffer.h"
#import "GPUImageOpenGLESContext.h"

@interface GPUImageRenderbuffer ()
{
    BOOL hasBoundRenderbufferToFramebuffer;
}
@end

@implementation GPUImageRenderbuffer

- (id) initWithSize:(GLsize)size baseFormat:(GLenum)format
{
    if (self = [super init]) {
        glGenRenderbuffers(1, &_handle);
        glBindRenderbuffer(GL_RENDERBUFFER, _handle);
        glRenderbufferStorage(GL_RENDERBUFFER, format, size.width, size.height);
        _size = size;
        _format = format;
    }
    return self;
}

- (id) initWithLayer:(CAEAGLLayer *)layer
{
    if (self = [super init]) {
        glGenRenderbuffers(1, &_handle);
        glBindRenderbuffer(GL_RENDERBUFFER, _handle);
        [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext].context 
            renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_size.width);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_size.height);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_INTERNAL_FORMAT, (GLint *)&_format);
    }
    return self;
}

- (void) bind
{
    if (_handle) {
        glBindRenderbuffer(GL_RENDERBUFFER, _handle);
    }
}

- (void) bindAsFramebuffer
{
    [super bindAsFramebuffer];
    if (!hasBoundRenderbufferToFramebuffer) {
        hasBoundRenderbufferToFramebuffer = YES;
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
            GL_RENDERBUFFER, self.handle);
        [self validateFramebuffer]; // TODO: remove for performance
    }
}

- (void) dealloc
{
    if (_handle > 0) {
        glDeleteRenderbuffers(1, &_handle);
    }
}

@end



