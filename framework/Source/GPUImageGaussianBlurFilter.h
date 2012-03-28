#import "GPUImageFilter.h"
#import "GPUImage.h"

@interface GPUImageGaussianBlurFilter : GPUImage 
{
    GPUImageFilter *stageOne, *stageTwo;
    id <GPUImageSource> trueParent;
}

// A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

@end
