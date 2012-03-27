#import "GPUImageFilter.h"

@interface GPUImageColorMatrixFilter : GPUImageFilter

@property (nonatomic) mat4 colorMatrix;
@property (nonatomic) CGFloat intensity;

@end
