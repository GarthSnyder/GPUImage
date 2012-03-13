#import "GPUImageTwoPassFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageTwoPassFilter {
    GLint horizontalGaussianArrayUniform,
        imageWidthUniform,
        verticalGaussianArrayUniform,
        imageHeightUniform;
}

@property (readwrite, nonatomic) CGFloat sigma;

- (void) calculateGaussianWeights;

@end
