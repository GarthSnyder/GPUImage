#import "GPUImage.h"

@implementation GPUImage

- (void) deriveFrom:(id <GPUImageFlow>)newParent
{
    if (parent != newParent) {
        parent = newParent;
        timeLastChanged = 0; // Force update
    }
}

- (GPUImageTimestamp) timeLastChanged 
{
    return timeLastChanged;
}

- (BOOL) update
{
    if (!parent || ![parent update]) {
        return NO;
    }
    if (self.timeLastChanged < parent.timeLastChanged) {
        return [self render];
    }
    return YES;
}

#pragma mark -
#pragma mark Rendering

// We only know how to deal with parents who are themselves GPUImages. Our
// contents are expected to reflect theirs after rendering.
//
// If our size and color model are compatible with the parent texture's settings,
// we can simply share that texture's backing store and set ancillary params
// as needed. (It's fine to override the parent's filter and wraps because the
// parent will reset them when it next gets drawn into.)
//
// If our parent is a texture of incompatible size or backing store, then we
// need to do a conversion.

- (BOOL) render
{
    NSAssert([parent isKindOfClass:[GPUImageBase class]], 
         @"Sorry, GPUImage::render doesn't know how do deal with non-GPUImageBase parents.");
    GPUImageBase *gpuParent = parent;
    NSAssert(![self parentRequiresConversion:gpuParent],
         @"Automatic texture size and format conversions are not yet implemented.");
    self.backingStore = parent.backingStore;
    [self setTextureParams];
    if (!self.useRenderbuffer && self.generateMipmap) {
        GPUImageTextureBuffer *store = (GPUImageTextureBuffer *)self.backingStore;
        [store generateMipmap]; // Optimized out if already done
    }
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

// Is there anything about the parent GPUImage that makes it impossible for us
// to share the parent's backing texture?

- (BOOL) parentRequiresConversion:(GPUImage *)gp
{
    return ((self.useRenderbuffer != gp.useRenderbuffer) 
            || (self.size.width != gp.size.width) 
            || (self.size.height != gp.size.height)
            || (self.baseFormat != gp.baseFormat) 
            || (!self.useRenderbuffer && (self.pixType != gp.pixType)));
}

@end
