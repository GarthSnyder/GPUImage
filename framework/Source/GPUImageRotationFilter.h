#import "GPUImageFilter.h"

typedef enum { kGPUImageRotateLeft, kGPUImageRotateRight, kGPUImageFlipVertical, kGPUImageFlipHorizonal, kGPUImageRotateRightFlipVertical} GPUImageRotationMode;

@interface GPUImageRotationFilter : GPUImageFilter

@property (nonatomic) GPUImageRotationMode rotationMode;

@end
