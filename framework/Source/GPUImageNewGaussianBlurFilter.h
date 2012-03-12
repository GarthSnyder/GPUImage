#import "GPUImageTwoPassFilter.h"

@interface GPUImageNewGaussianBlurFilter : GPUImageTwoPassFilter {
    GLint horizontalWindowSizeUniform,
        horizontalXStepUniform,
        horizontalYStepUniform,
        horizontalGaussianArrayUniform;
    GLint verticalWindowSizeUniform,
        verticalXStepUniform,
        verticalYStepUniform,
        verticalGaussianArrayUniform;
}

@property (readwrite, nonatomic) CGFloat sigma;

- (void) calculateGaussianWeights;

@end
