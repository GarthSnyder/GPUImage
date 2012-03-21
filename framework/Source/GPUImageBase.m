#import "GPUImageBase.h"
#import "GPUImageTextureBuffer.h"
#import "GPUImageRenderbuffer.h"

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
        self.filter = GL_NEAREST;
        self.wrap = GL_CLAMP_TO_EDGE;
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
        self.backingStore = nil;
        _useRenderbuffer = use;
        timeLastChanged = 0;
    }
}

- (void) setLayer:(CAEAGLLayer *)layer
{
    self.useRenderbuffer = YES;
    _layer = layer;
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
    if (self.backingStore) {
        [self.backingStore bindAsFramebuffer];
        return;
    }
    // We're going to have to create the backing store. Must know at least 
    // size and base format, or for layer-based renderbuffers, the layer id.
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
