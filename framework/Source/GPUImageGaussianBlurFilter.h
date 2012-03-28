#import "GPUImageFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageFilter
{
    GPUImageFilter *stageOne;
}

// A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

@end
