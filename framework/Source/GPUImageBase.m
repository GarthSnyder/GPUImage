#import "GPUImageBase.h"
#import "GPUImageTexture.h"
#import "GPUImageRenderbuffer.h"

@implementation GPUImageBase

@synthesize size = _size;
@synthesize baseFormat = _baseFormat;
@synthesize pixType = _pixType;
@synthesize backgroundColor = _backgroundColor;

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
        self.backgroundColor = (vec4) {0.0, 0.0, 0.0, 1.0};
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
        [self releaseCanvas];
    }
}

- (void) setLayer:(CAEAGLLayer *)layer
{
    if (_layer != layer) {
        _usesRenderbuffer = YES;
        _layer = layer;
        [self releaseCanvas];
    }
}

- (void) setSize:(GLsize)newSize
{
    if ((newSize.width != self.size.width) || (newSize.height != self.size.height)) {
        _size = newSize;
        [self releaseCanvas];
    }
}

- (void) setBaseFormat:(GLenum)fmt
{
    if (_baseFormat != fmt) {
        _baseFormat = fmt;
        [self releaseCanvas];
    }
}

- (void) setPixType:(GLenum)pix
{
    if (_pixType != pix) {
        _pixType = pix;
        [self releaseCanvas];
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
        if (self.canvas && (timeLastChanged > 0)) {
            GPUImageTexture *buffer = (GPUImageTexture *)self.canvas;
            [buffer generateMipmap:NO];
            timeLastChanged = 0;
        }
    }
}

- (GPUImageCanvas *)canvas
{
    return _canvas;
}

- (void) adoptParametersFrom:(id <GPUImageSource>)other
{
    GPUImageCanvas *obs = other.canvas;
    
    if (!self.size.width || !self.size.height) {
        self.size = obs.size;
    }
    if (!self.baseFormat) {
        self.baseFormat = obs.format;
    }
    if (!self.pixType && !self.usesRenderbuffer && [obs isKindOfClass:[GPUImageTexture class]]) {
        self.pixType = ((GPUImageTexture *)obs).pixType;
    }
}

#pragma mark -
#pragma mark Interactions with canvas

// Must know at least size and base format, or for layer-based renderbuffers,
// the layer id. This call always creates a new canvas, even if one
// already exists.

- (void) createCanvas
{
    NSAssert(self.layer || (self.size.width && self.size.height && self.baseFormat),
             @"Cannot bindAsFramebuffer without at least size and base format.");
    if (self.usesRenderbuffer) {
        if (self.layer) {
            _canvas = [[GPUImageRenderbuffer alloc] initWithLayer:self.layer];
            _size = _canvas.size;
            _baseFormat = _canvas.format;
        } else {
            _canvas = [[GPUImageRenderbuffer alloc] initWithSize:self.size
                                                            baseFormat:self.baseFormat];
        }
    } else {
        if (!self.pixType) {
            self.pixType = GL_UNSIGNED_BYTE;
        }
        _canvas = [[GPUImageTexture alloc] initWithSize:self.size
                                                         baseFormat:self.baseFormat pixType:self.pixType];
        [self setTextureParameters];
    }
    timeLastChanged = 0;
}

- (void) releaseCanvas
{
    _canvas = nil;
    timeLastChanged = 0;
}

// Propagate configuration parameters for textures through to the OpenGL
// wrapper layer.

- (void) setTextureParameters
{
    if (self.usesRenderbuffer || !self.canvas) {
        return;
    }
    GPUImageTexture *store = (GPUImageTexture *)self.canvas;
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
    if (!self.canvas) {
        [self createCanvas];
    }
    [self.canvas bindAsFramebuffer];
}

- (void) clearFramebuffer:(vec4)backgroundColor
{
    if (!self.canvas) {
        [self createCanvas];
    }
    [self.canvas clearFramebuffer:backgroundColor];
}

- (void) clearFramebuffer
{
    [self clearFramebuffer:self.backgroundColor];
}

#pragma mark -
#pragma mark Exporting images

- (GLubyte *) copyRawContents
{
    return [self.canvas copyRawDataFromFramebuffer];
}

- (CGImageRef) copyCGImage
{
    return [self.canvas copyCGImageFromFramebuffer];
}

- (UIImage *) getUIImage
{
    CGImageRef cgRef = [self.canvas copyCGImageFromFramebuffer];
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
