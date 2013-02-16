#import "GPUImageSobelEdgeDetectionFilter.h"

@interface GPUImageThresholdEdgeDetection : GPUImageSobelEdgeDetectionFilter

// Any edge above this threshold will be black, and anything below white.
@property (nonatomic) CGFloat threshold; // 0.0 to 1.0, default = 0.9

@end
