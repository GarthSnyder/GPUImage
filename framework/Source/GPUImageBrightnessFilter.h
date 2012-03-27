#import "GPUImageFilter.h"

@interface GPUImageBrightnessFilter : GPUImageFilter

// Brightness ranges from -1.0 to 1.0, with 0.0 as the normal level
@property (nonatomic) CGFloat brightness; 

@end
