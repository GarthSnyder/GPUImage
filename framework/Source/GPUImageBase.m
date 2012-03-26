#import "GPUImageBase.h"
#import "GPUImageTextureBuffer.h"
#import "GPUImageRenderbuffer.h"

@interface GPUImageBase ()
{
    GPUImageBuffer *_backingStore;
}
- (void) createBackingStore;
- (void) setTextureParameters;
@end

@implementation GPUImageBase

@synthesize size = _size;
@synthesize baseFormat = _baseFormat;
@synthesize pixType = _pixType;

@synthesize usesRenderbuffer = _usesRenderbuffer;
@synthesize generatesMipmap = _generatesMipmap;

@synthesize magFilter = _magFilter;
@synthesize minFilter = _minFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

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

- (void) setUsesRenderbuffer:(BOOL)use
{
    if (self.usesRenderbuffer != use) {
        _usesRenderbuffer = use;
        [self releaseBackingStore];
    }
}

- (void) setLayer:(CAEAGLLayer *)layer
{
    if (_layer != layer) {
        _usesRenderbuffer = YES;
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

- (void) setGeneratesMipmap:(BOOL)gen
{
    if (self.generatesMipmap == gen) {
        return;
    }
    if (gen) {
        NSAssert(!self.usesRenderbuffer, @"Renderbuffers cannot have mipmaps");
        _generatesMipmap = YES;
        if (self.backingStore && (timeLastChanged > 0)) {
            GPUImageTextureBuffer *buffer = (GPUImageTextureBuffer *)self.backingStore;
            [buffer generateMipmap:NO];
            timeLastChanged = 0;
        }
    }
}

- (void) adoptParametersFrom:(id <GPUImageProvider>)other
{
    GPUImageBuffer *obs = other.backingStore;
    
    if (!self.size.width || !self.size.height) {
        self.size = obs.size;
    }
    if (!self.baseFormat) {
        self.baseFormat = obs.baseFormat;
    }
    if (!self.pixType && !self.usesRenderbuffer && [obs isKindOfClass:[GPUImageTextureBuffer class]]) {
        self.pixType = ((GPUImageTextureBuffer *)obs).pixType;
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
    if (self.usesRenderbuffer) {
        if (self.layer) {
            _backingStore = [[GPUImageRenderbuffer alloc] initWithLayer:self.layer];
            self.size = self.backingStore.size;
            self.baseFormat = self.backingStore.format;
        } else {
            _backingStore = [[GPUImageRenderbuffer alloc] initWithSize:self.size
                                                            baseFormat:self.baseFormat];
        }
    } else {
        if (!self.pixType) {
            self.pixType = GL_UNSIGNED_BYTE;
        }
        _backingStore = [[GPUImageTextureBuffer alloc] initWithSize:self.size
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
    if (self.usesRenderbuffer || !self.backingStore) {
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

- (void) clearFramebuffer:(vec4)backgroundColor
{
    if (!self.backingStore) {
        [self createBackingStore];
    }
    [self.backingStore clearFramebuffer:backgroundColor];
}

- (void) clearFramebuffer
{
    vec4 opaqueBlack = {0.0, 0.0, 0.0, 1.0};
    [self clearFramebuffer:opaqueBlack];
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
    // Capture image with current device orientation
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    UIImageOrientation imageOrientation = UIImageOrientationLeft;
	switch (deviceOrientation)
    {
		case UIDeviceOrientationPortrait:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationRight;
			break;
		default:
			imageOrientation = UIImageOrientationUp;
			break;
	}
    UIImage *finalImage = [UIImage imageWithCGImage:cgRef scale:1.0
        orientation:imageOrientation];
    CGImageRelease(cgRef);
    return finalImage;
}

@end
