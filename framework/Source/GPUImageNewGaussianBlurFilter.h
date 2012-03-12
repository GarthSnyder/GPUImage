#import "GPUImageTwoPassFilter.h"

@interface GPUImageNewGaussianBlurFilter : GPUImageTwoPassFilter {
    GLint horizontalGaussianArrayUniform,
        imageWidthUniform,
        verticalGaussianArrayUniform,
        imageHeightUniform;
}

@property (readwrite, nonatomic) CGFloat sigma;

- (void) calculateGaussianWeights;

@end
