#import "GPUImageFilter.h"

@interface GPUImageSharpenFilter : GPUImageFilter

// Sharpness ranges from -4.0 to 4.0, with 0.0 as the normal level
@property (nonatomic) CGFloat sharpness; 

@end
