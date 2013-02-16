#import "GPUImageFilter.h"

extern NSString *const kGPUImageNearbyTexelSamplingVertexShaderString;

@interface GPUImage3x3ConvolutionFilter : GPUImageFilter <GPUImageProgramDelegate>

// The convolution kernel is a 3x3 matrix of values to apply to the pixel and its 8 surrounding pixels.
// The matrix is specified in row-major order, with the top left pixel being [0][0] and the bottom right [2][2].
// If the values in the matrix don't add up to 1.0, the image could be brightened or darkened.

@property (nonatomic) mat3 convolutionKernel;

@end
