#import "GPUImage.h"
#import "GPUImageFilter.h"

@interface GPUImageBoxBlurFilter : GPUImage
{
    GPUImageFilter *stageOne, *stageTwo;
    id <GPUImageSource> trueParent;
}

@end
