#import "GPUImageFilter.h"

@interface GPUImageBoxBlurFilter : GPUImageFilter
{
    GPUImageFilter *stageOne;
}

@end
