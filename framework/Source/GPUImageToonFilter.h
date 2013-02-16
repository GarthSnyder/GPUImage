#import "GPUImageFilter.h"

@interface GPUImageToonFilter : GPUImageFilter

// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property (nonatomic) CGFloat imageWidthFactor;
@property (nonatomic) CGFloat imageHeightFactor; 

// The threshold at which to apply the edges, default of 0.2
@property (nonatomic) CGFloat threshold; 

// The levels of quantization for the posterization of colors within the scene, with a default of 10.0
@property (nonatomic) CGFloat quantizationLevels; 

@end
