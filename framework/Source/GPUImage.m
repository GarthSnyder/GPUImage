#import "GPUImage.h"

@implementation GPUImage ()
- (BOOL) parentRequiresConversion;
@end

@implementation GPUImage

- (void) deriveFrom:(GPUImageSource)newParent
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

// Update our contents to reflect those of the parent. The parent implements
// the GPUImageSource protocol, so we know it can produce an image buffer
// on demand. The question is, can we share this buffer, or do we need to 
// copy or adapt it?
//
// If our size and color model are compatible with the parent texture's settings,
// we can simply share that texture's backing store and set ancillary params
// as needed. (It's fine to override the parent's filter and wraps because the
// parent will reset them when it is next rendered.)
//
// If our parent is a texture of incompatible size or backing store, then we
// need to do a conversion.

- (BOOL) render
{
    NSAssert([parent backingStore], @"Parent has no backing store; should never happen.");
    NSAssert(![self parentRequiresConversion],
         @"Automatic texture size and format conversions are not yet implemented.");
    _backingStore = parent.backingStore;
    [self setTextureParams];
    if (!self.usesRenderbuffer && self.generatesMipmap) {
        GPUImageTextureBuffer *store = (GPUImageTextureBuffer *)self.backingStore;
        [store generateMipmap:NO]; // Optimized out if already done
    }
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

// Is there anything about the parent object that makes it impossible for us
// to share its backing texture?

- (BOOL) parentRequiresConversion
{
    GPUImageBuffer *pbs = parent.backingStore;
    
    if ((self.size.width != pbs.size.width) 
        || (self.size.height != pbs.size.height)
        || (self.baseFormat != pbs.format))
    {
        return YES;
    }
    if (self.usesRenderbuffer) {
        return ![pbs isKindOfClass:[GPUImageRenderbuffer class]];
    } else {
        if (![pbs isKindOfClass:[GPUImageTextureBuffer class]]) {
            return YES;
        }
        GPUImageTextureBuffer *ptb = pbs;
        if (self.pixType != ptb.pixType) {
            return YES;
        }
    }
    return NO;
}

@end
