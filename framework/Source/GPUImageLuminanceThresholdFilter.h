#import "GPUImageFilter.h"

@interface GPUImageLuminanceThresholdFilter : GPUImageFilter

// Anything above this luminance will be white, and anything below black. Ranges from 0.0 to 1.0, with 0.5 as the default
@property (nonatomic) CGFloat threshold; 

@end
