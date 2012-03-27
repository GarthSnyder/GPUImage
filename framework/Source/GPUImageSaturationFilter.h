#import "GPUImageFilter.h"

@interface GPUImageSaturationFilter : GPUImageFilter

// Saturation ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
@property (nonatomic) CGFloat saturation; 

@end
