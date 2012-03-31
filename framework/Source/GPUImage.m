#import "GPUImage.h"
#import "GPUImageTexture.h"
#import "GPUImageRenderbuffer.h"
#import <objc/runtime.h>

@interface GPUImage ()
- (BOOL) inputImageRequiresConversion;
@end

static GPUImageProgram *copyProgram;

@implementation GPUImage

@synthesize inputImage = _inputImage;

- (void) setInputImage:(id <GPUImageSource>)newParent
{
    if (_inputImage != newParent) {
        _inputImage = newParent;
        timeLastChanged = 0; // Force update
    }
}

- (GPUImageTimestamp) timeLastChanged 
{
    return timeLastChanged;
}

- (BOOL) update
{
    if (!self.inputImage || ![self.inputImage update]) {
        return NO;
    }
    if (self.timeLastChanged < self.inputImage.timeLastChanged) {
        return [self render];
    }
    return YES;
}

#pragma mark -
#pragma mark Rendering

// Update our contents to reflect those of the input image. The parent implements
// the GPUImageSource protocol, so we know it can produce an image buffer
// on demand. The question is, can we share this buffer, or do we need to 
// copy or adapt it?
//
// If our size and color model are compatible with the parent texture's settings,
// we can simply share that texture's canvas and set ancillary params
// as needed. (It's fine to override the parent's filter and wraps because the
// parent will reset them when it is next rendered.)
//
// If our parent is a texture of incompatible size or canvas, then we
// need to do a conversion.

- (BOOL) render
{
    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Render: %s (GPUImage)", 
        class_getName([self class])] UTF8String]);
    NSAssert([self.inputImage canvas], @"Input image has no canvas; should never happen.");
    if ([self inputImageRequiresConversion]) {
        [self bindAsFramebuffer];
        [self clearFramebuffer];
        if (!copyProgram) {
            copyProgram = [[GPUImageProgram alloc] init];
        }
        copyProgram.inputImage = self.inputImage;
        [self drawWithProgram:copyProgram];
        copyProgram.inputImage = nil;
    } else {
        _canvas = self.inputImage.canvas;
        [self setTextureParameters];
    }
    if (!self.usesRenderbuffer && self.generatesMipmap) {
        GPUImageTexture *store = (GPUImageTexture *)self.canvas;
        [store generateMipmap:NO]; // Optimized out if already done
    }
    timeLastChanged = GPUImageGetCurrentTimestamp();
    glPopGroupMarkerEXT();
    return YES;
}

// Is there anything about the parent object that makes it impossible for us
// to share its backing texture?

- (BOOL) inputImageRequiresConversion
{
    GPUImageCanvas *pbs = self.inputImage.canvas;
    
    if ((self.size.width != pbs.size.width) 
        || (self.size.height != pbs.size.height)
        || (self.baseFormat != pbs.format))
    {
        return YES;
    }
    if (self.usesRenderbuffer) {
        return ![pbs isKindOfClass:[GPUImageRenderbuffer class]];
    } else {
        if (![pbs isKindOfClass:[GPUImageTexture class]]) {
            return YES;
        }
        GPUImageTexture *ptb = (GPUImageTexture *)pbs;
        if (self.pixType != ptb.pixType) {
            return YES;
        }
    }
    return NO;
}

- (GPUImageCanvas *) canvas 
{
    return _canvas;
}

-(id<GPUImageSource>) sourceAsRenderbuffer
{
    return self;
}

@end
