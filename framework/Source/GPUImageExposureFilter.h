#import "GPUImageFilter.h"

@interface GPUImageExposureFilter : GPUImageFilter

// Exposure ranges from -10.0 to 10.0, with 0.0 as the normal level
@property (nonatomic) CGFloat exposure; 

@end
