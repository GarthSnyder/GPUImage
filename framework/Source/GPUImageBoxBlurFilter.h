#import "GPUImage.h"
#import "GPUIMageFilter.h"

@interface GPUImageBoxBlurFilter : GPUImage
{
    GPUImageFilter *stageOne, *stageTwo;
    id <GPUImageSource> trueParent;
}

@end
