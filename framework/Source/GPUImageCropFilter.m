#import "GPUImageCropFilter.h"

@implementation GPUImageCropFilter

@synthesize cropRegion = _cropRegion;

- (id) initWithCropRegion:(CGRect)newCropRegion
{
    if (self = [super init]) {
        self.cropRegion = newCropRegion;
    }
    return self;
}

- (id) init
{
    return [self initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 1.0)];
}

- (void) drawWithProgram:(GPUImageProgram *)prog
{
    GLfloat cropTextureCoordinates[] = {
        _cropRegion.origin.x, _cropRegion.origin.y,
        CGRectGetMaxX(_cropRegion), _cropRegion.origin.y,
        _cropRegion.origin.x, CGRectGetMaxY(_cropRegion),
        CGRectGetMaxX(_cropRegion), CGRectGetMaxY(_cropRegion),
    };

    [self drawWithProgram:prog vertices:NULL textureCoordinates:cropTextureCoordinates];
}

@end
