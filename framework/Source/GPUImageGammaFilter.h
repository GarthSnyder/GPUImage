#import "GPUImageFilter.h"

@interface GPUImageGammaFilter : GPUImageFilter

@property (nonatomic) CGFloat gamma;  // Range 0.0 to 3.0, 1 = normal

@end
