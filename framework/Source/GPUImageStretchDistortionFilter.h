#import "GPUImageFilter.h"

@interface GPUImageStretchDistortionFilter : GPUImageFilter

// The center about which to apply the distortion, with a default of (0.5, 0.5)
@property (nonatomic) CGPoint center;

@end
