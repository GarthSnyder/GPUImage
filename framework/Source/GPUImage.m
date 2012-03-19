//  Created by Garth Snyder on 3/14/12.

#import "GPUImage.h"
#import "GPUImageTextureBuffer.h"
#import "GPUImageRenderbuffer.h"

@interface GPUImage ()
{
    BOOL _renderbufferRequested;
}

@end

@implementation GPUImage

@synthesize size = _size;
@synthesize baseFormat = _baseFormat;
@synthesize pixType = _pixType;

@synthesize useRenderbuffer = _useRenderbuffer;
@synthesize generateMipmap = _generateMipmap;

@synthesize magnificationFilter = _magnificationFilter;
@synthesize minificationFilter = _minificationFilter;
@synthesize wrapS = _wrapS;
@synthesize wrapT = _wrapT;

@synthesize backingStore = _backingStore;
@synthesize layer = _layer;

#pragma mark -
#pragma mark Basic setup and accessors

+ (id) texture
{
    return [[GPUImage alloc] init];
}

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
    NSAssert(self.magnificationFilter == self.minificationFilter, 
        @"GPUImage::filter called when filters have inconsistent values");
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
        lastChangeTime = 0;
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
        if (lastChangeTime > 0) {
            GPUImageTextureBuffer *buffer = (GPUImageTextureBuffer *)self.backingStore;
            [buffer generateMipmap];
        }
    }
}

- (void) adoptParametersFrom:(GPUImage *)other
{
    GLsize newSize = self.size;
    if (!newSize.width || !newSize.height) {
        newSize = other.size;
        self.size = newSize;
    }
    
    if (!self.baseFormat) {
        self.baseFormat = other.baseFormat;
    }
    
    if (!self.pixType) {
        self.pixType = other.pixType;
    }
}

#pragma mark -
#pragma mark Rendering and buffer management

// Rendering/updating can mean several different things in the context of a 
// texture:
//
// If our parent is a filter (that is, anything other than another texture),
// then this texture is a rendering destination. The only thing we need to 
// worry about at render time is mipmap generation, because the base drawing
// has already occurred - the parent filter called bindAsFramebuffer on us
// when it was ready to draw, and the backing store was validated at that time.
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
    
    if ([[parents anyObject] isKindOfClass:[GPUImage class]]) {
        GPUImage *parent = [parents anyObject];
        NSAssert(![self parentRequiresConversion:parent],
            @"Automatic texture size and format conversions are not yet supported.");
        self.backingStore = parent.backingStore;
        [self setTextureParams];
    }
    if (!self.useRenderbuffer && self.generateMipmap) {
        GPUImageTextureBuffer *store = (GPUImageTextureBuffer *)self.backingStore;
        [store generateMipmap];
    }
    lastChangeTime = GPUImageGetCurrentTimestamp();
    return YES;
}

// Is there anything about the parent texture that makes it impossible for us
// to share the parent's backing texture?

- (BOOL) parentRequiresConversion:(GPUImage *)parent
{
    return ((self.useRenderbuffer != parent.useRenderbuffer) 
        || (self.size.width != parent.size.width) 
        || (self.size.height != parent.size.height)
        || (self.baseFormat != parent.baseFormat) 
        || (!self.useRenderbuffer && (self.pixType != parent.pixType)));
}

- (void) setTextureParams
{
    GPUImageTextureBuffer *store = (GPUImageTextureBuffer *)self.backingStore;
    if (self.useRenderbuffer || !store) {
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
    // We're going to have to create the backing store. Must know at least 
    // size and base format.
    NSAssert(self.size.width && self.size.height && self.baseFormat,
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

- (GLuint *) getRawContents;

- (CGImageRef) convertToCGImage;

- (UIImage *) convertToUIImage
{
    CGImageRef cgRef = [self.backingStore CGImageFromFramebuffer];
    UIImage *finalImage = [UIImage imageWithCGImage:cgRef scale:1.0
        orientation:UIImageOrientationLeft];
    CGImageRelease(cgRef);
    return finalImage;
}

@end
