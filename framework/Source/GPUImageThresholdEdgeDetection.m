#import "GPUImageThresholdEdgeDetection.h"

@implementation GPUImageThresholdEdgeDetection

// Invert the colorspace for a sketch
NSString *const kGPUImageThresholdEdgeDetectionFragmentShaderString = SHADER_STRING
(
    precision highp float;

    varying vec2 textureCoordinate;
    varying vec2 leftTextureCoordinate;
    varying vec2 rightTextureCoordinate;

    varying vec2 topTextureCoordinate;
    varying vec2 topLeftTextureCoordinate;
    varying vec2 topRightTextureCoordinate;

    varying vec2 bottomTextureCoordinate;
    varying vec2 bottomLeftTextureCoordinate;
    varying vec2 bottomRightTextureCoordinate;

    uniform sampler2D inputImage;
    uniform lowp float threshold;

    const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

    void main()
    {
        float i00   = texture2D(inputImage, textureCoordinate).r;
        float im1m1 = texture2D(inputImage, bottomLeftTextureCoordinate).r;
        float ip1p1 = texture2D(inputImage, topRightTextureCoordinate).r;
        float im1p1 = texture2D(inputImage, topLeftTextureCoordinate).r;
        float ip1m1 = texture2D(inputImage, bottomRightTextureCoordinate).r;
        float im10 = texture2D(inputImage, leftTextureCoordinate).r;
        float ip10 = texture2D(inputImage, rightTextureCoordinate).r;
        float i0m1 = texture2D(inputImage, bottomTextureCoordinate).r;
        float i0p1 = texture2D(inputImage, topTextureCoordinate).r;
        float h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
        float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;

        float mag = 1.0 - length(vec2(h, v));
        mag = step(threshold, mag);

        gl_FragColor = vec4(vec3(mag), 1.0);
    }
 );

#pragma mark -
#pragma mark Initialization and teardown

@dynamic threshold;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageThresholdEdgeDetectionFragmentShaderString;
    }
    self.threshold = 0.9;
    return self;
}

@end
