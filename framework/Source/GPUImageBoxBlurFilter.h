#import "GPUImageFilter.h"

@interface GPUImageBoxBlurFilter : GPUImageFilter <GPUImageProgramDelegate>
{
    GPUImageFilter *stageOne;
}

@end
