#import "GPUImageGaussianSelectiveBlurFilter.h"

NSString *const kGPUImageGaussianSelectiveBlurFragmentShaderString = SHADER_STRING
(
    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage; // The un-blurred image

    const lowp int GAUSSIAN_SAMPLES = 9;

    uniform lowp float excludeCircleRadius;
    uniform lowp vec2 excludeCirclePoint;
    uniform lowp float excludeBlurSize;

    uniform mediump float gaussianValues[9];

    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main()
    {
        lowp vec4 sum = vec4(0.0);

        sum += texture2D(inputImage, blurCoordinates[0]) * 0.05;
        sum += texture2D(inputImage, blurCoordinates[1]) * 0.09;
        sum += texture2D(inputImage, blurCoordinates[2]) * 0.12;
        sum += texture2D(inputImage, blurCoordinates[3]) * 0.15;
        sum += texture2D(inputImage, blurCoordinates[4]) * 0.18;
        sum += texture2D(inputImage, blurCoordinates[5]) * 0.15;
        sum += texture2D(inputImage, blurCoordinates[6]) * 0.12;
        sum += texture2D(inputImage, blurCoordinates[7]) * 0.09;
        sum += texture2D(inputImage, blurCoordinates[8]) * 0.05;

        lowp vec4 overlay = texture2D(auxilliaryImage, textureCoordinate);
        lowp float d = distance(textureCoordinate, excludeCirclePoint);

        sum = mix(overlay, sum, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, d));

        gl_FragColor = sum;
    }
);

@implementation GPUImageGaussianSelectiveBlurFilter

@synthesize excludeCirclePoint = _excludeCirclePoint;
@dynamic excludeBlurSize, excludeCircleRadius;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageGaussianSelectiveBlurFragmentShaderString;
        self.blurSize = 2.0;
        self.excludeCircleRadius = 60.0/320.0;
        self.excludeCirclePoint = CGPointMake(0.5f, 0.5f);
        self.excludeBlurSize = 30.0/320.0;
    }
    return self;
}

- (void) setExcludeCirclePoint:(CGPoint)excludeCirclePoint 
{
    _excludeCirclePoint = excludeCirclePoint;
    
    GLfloat excludeCirclePosition[2];
    excludeCirclePosition[0] = _excludeCirclePoint.x;
    excludeCirclePosition[1] = _excludeCirclePoint.y;
    
    [self.program setValue:UNIFORM(excludeCirclePosition) forKey:@"excludeCirclePoint"];
}

@end
