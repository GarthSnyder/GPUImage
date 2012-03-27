#import "GPUImageGaussianBlurFilter.h"

@interface GPUImageGaussianSelectiveBlurFilter : GPUImageGaussianBlurFilter {
    GLint verticalExcludeCircleRadiusUniform,
        verticalExcludeCirclePointUniform,
        verticalExcludeCircleBlurSizeUniform;
    
    GLuint originalinputTexture;
}

@property (readwrite, nonatomic) CGFloat excludeCircleRadius;
@property (readwrite, nonatomic) CGPoint excludeCirclePoint;
@property (readwrite, nonatomic) CGFloat excludeBlurSize;

@end
