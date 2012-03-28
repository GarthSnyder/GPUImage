#import "GPUImageFilter.h"

extern NSString *const kGPUImageSobelEdgeDetectionVertexShaderString;

@interface GPUImageSobelEdgeDetectionFilter : GPUImageFilter

// The image width and height factors tweak the appearance of the edges.
// By default, they match the filter size in pixels.

@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end
