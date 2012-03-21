#import "GPUImageBase.h"
#import "GPUImageTextureBuffer.h"
#import "GPUImageRenderbuffer.h"

@interface GPUImageBase
- (void) createBackingStore;
- (void) setTextureParameters;
@end

@implementation GPUImageBase

@synthesize size = _size;
@synthesize baseFormat = _baseFormat;
@synthesize pixType = _pixType;

@synthesize useRenderbuffer = _useRenderbuffer;
@synthesize generateMipmap = _generateMipmap;

@synthesize magFilter = _magFilter;
@synthesize minFilter = _minFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

@synthesize backingStore = _backingStore;
@synthesize layer = _layer;

#pragma mark -
#pragma mark Basic setup and accessors

- (id) init
{
    if (self = [super init]) {
        self.filter = GL_LINEAR;
        self.wrap = GL_CLAMP_TO_EDGE;
        self.pixType = GL_UNSIGNED_BYTE;
    }
    return self;
}

- (GLenum) filter
{
    NSAssert(self.magFilter == self.minFilter, 
        @"GPUImage::filter called when filters have inconsistent values");
    return self.magFilter;
}

- (void) setFilter:(GLenum)filter
{
    self.magFilter = filter;
    self.minFilter = filter;
}

- (GLenum) wrap
{
    NSAssert(self.wrapS == self.wrapT, 
        @"GPUImage::wrap called when S and T wraps have inconsistent values");
    return self.wrapS;
}

- (void) setWrap:(GLenum)wrap
{
    self.wrapS = wrap;
    self.wrapT = wrap;
}

- (void) setUseRenderbuffer:(BOOL)use
{
    if (self.useRenderbuffer != use) {
        _useRenderbuffer = use;
        [self releaseBackingStore];
    }
}

- (void) setLayer:(CAEAGLLayer *)layer
{
    if (_layer != layer) {
        _useRenderbuffer = YES;
        _layer = layer;
        [self releaseBackingStore];
    }
}

- (void) setSize:(GLsize)newSize
{
    if ((newSize.width != self.size.width) || (newSize.height != self.size.height)) {
        _size = newSize;
        [self releaseBackingStore];
    }
}

- (void) setBaseFormat:(GLenum)fmt
{
    if (_baseFormat != fmt) {
        _baseFormat = fmt;
        [self releaseBackingStore];
    }
}

- (void) setPixType:(GLenum)pix
{
    if (_pixType != pix) {
        _pixType = pix;
        [self releaseBackingStore];
    }
}

- (void) setGenerateMipmap:(BOOL)gen
{
    if (self.generateMipmap == gen) {
        return;
    }
    if (gen) {
        NSAssert(!self.useRenderbuffer, @"Renderbuffers cannot have mipmaps");
        _generateMipmap = gen;
        if (timeLastChanged > 0) {
            GPUImageTextureBuffer *buffer = (GPUImageTextureBuffer *)self.backingStore;
            [buffer generateMipmap];
        }
    }
}

- (void) adoptParametersFrom:(GPUImage *)other
{
    if (!self.size.width || !self.size.height) {
        self.size = other.size;
    }
    if (!self.baseFormat) {
        self.baseFormat = other.baseFormat;
    }
    if (!self.pixType) {
        self.pixType = other.pixType;
    }
}

#pragma mark -
#pragma mark Interactions with backing store

// Must know at least size and base format, or for layer-based renderbuffers,
// the layer id.

- (void) createBackingStore
{
    NSAssert(self.layer || (self.size.width && self.size.height && self.baseFormat),
             @"Cannot bindAsFramebuffer without at least size and base format.");
    if (self.useRenderbuffer) {
        if (self.layer) {
            self.backingStore = [[GPUImageRenderbuffer alloc] initWithLayer:self.layer];
            self.size = self.backingStore.size;
            self.baseFormat = self.backingStore.format;
        } else {
            self.backingStore = [[GPUImageRenderbuffer alloc] initWithSize:self.size
                                                                baseFormat:self.baseFormat];
        }
    } else {
        if (!self.pixType) {
            self.pixType = GL_UNSIGNED_BYTE;
        }
        self.backingStore = [[GPUImageTextureBuffer alloc] initWithSize:self.size
                                                             baseFormat:self.baseFormat pixType:self.pixType];
        [self setTextureParams];
    }
    timeLastChanged = 0;
}

- (void) releaseBackingStore
{
    _backingStore = nil;
    timeLastChanged = 0;
}

// Propagate configuration parameters for textures through to the OpenGL
// wrapper layer.

- (void) setTextureParams
{
    if (self.useRenderbuffer || !self.backingStore) {
        return;
    }
    GPUImageTextureBuffer *store = (GPUImageTextureBuffer *)self.backingStore;
    [store bind];
    if (self.magFilter > 0) {
        store.magFilter = self.magFilter;
    }
    if (self.minFilter > 0) {
        store.minFilter = self.minFilter;
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
    if (!self.backingStore) {
        [self createBackingStore];
    }
    [self.backingStore bindAsFramebuffer];
}

#pragma mark -
#pragma mark Drawing

- (void) drawWithProgram:(GPUImageProgram *)prog
{
    static const GLfloat squareVertices[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0,  1.0,
        1.0,  1.0,
    };
    
    static const GLfloat squareTextureCoordinates[] = {
        0.0,  0.0,
        1.0,  0.0,
        0.0,  1.0,
        1.0,  1.0,
    };
    
    GLint position = [prog indexOfAttribute:@"position"];
    GLint itc = [prog indexOfAttribute:@"inputTextureCoordinate"];
    
    glVertexAttribPointer(position, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(position);
    
    glVertexAttribPointer(itc, 2, GL_FLOAT, 0, 0, squareTextureCoordinates);
    glEnableVertexAttribArray(itc);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

#pragma mark -
#pragma mark Exporting images

- (GLuint *) getRawContents
{
    return [self.backingStore rawDataFromFramebuffer];
}

- (CGImageRef) getCGImage
{
    return [self.backingStore CGImageFromFramebuffer];
}

- (UIImage *) getUIImage
{
    CGImageRef cgRef = [self.backingStore CGImageFromFramebuffer];
    UIImage *finalImage = [UIImage imageWithCGImage:cgRef scale:1.0
        orientation:UIImageOrientationLeft];
    CGImageRelease(cgRef);
    return finalImage;
}

@end
