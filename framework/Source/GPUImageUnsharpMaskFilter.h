#import "GPUImageFilter.h"

@class GPUImageGaussianBlurFilter;

@interface GPUImageUnsharpMaskFilter : GPUImageFilter
{
    GPUImageGaussianBlurFilter *blurFilter;
}

// A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

// The strength of the sharpening, from 0.0 on up, with a default of 1.0
@property(readwrite, nonatomic) CGFloat intensity;

@end
