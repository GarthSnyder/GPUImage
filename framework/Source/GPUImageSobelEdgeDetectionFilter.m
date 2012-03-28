#import "GPUImageSobelEdgeDetectionFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImage3x3ConvolutionFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageSobelEdgeDetectionVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    uniform highp float imageWidthFactor; 
    uniform highp float imageHeightFactor; 

    varying vec2 textureCoordinate;
    varying vec2 leftTextureCoordinate;
    varying vec2 rightTextureCoordinate;

    varying vec2 topTextureCoordinate;
    varying vec2 topLeftTextureCoordinate;
    varying vec2 topRightTextureCoordinate;

    varying vec2 bottomTextureCoordinate;
    varying vec2 bottomLeftTextureCoordinate;
    varying vec2 bottomRightTextureCoordinate;

    void main()
    {
        gl_Position = position;

        vec2 widthStep = vec2(imageWidthFactor, 0.0);
        vec2 heightStep = vec2(0.0, imageHeightFactor);
        vec2 widthHeightStep = vec2(imageWidthFactor, imageHeightFactor);
        vec2 widthNegativeHeightStep = vec2(imageWidthFactor, -imageHeightFactor);

        textureCoordinate = inputTextureCoordinate.xy;
        leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
        rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;

        topTextureCoordinate = inputTextureCoordinate.xy + heightStep;
        topLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
        topRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;

        bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
        bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
        bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
    }
);

//   Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 
NSString *const kGPUImageSobelEdgeDetectionFragmentShaderString = SHADER_STRING
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

        float mag = length(vec2(h, v));

        gl_FragColor = vec4(vec3(mag), 1.0);
    }
);

@implementation GPUImageSobelEdgeDetectionFilter

@dynamic imageHeightFactor, imageWidthFactor;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageSobelEdgeDetectionVertexShaderString;
        self.program.fragmentShader = kGPUImageSobelEdgeDetectionFragmentShaderString;
        GPUImageGrayscaleFilter *grayFilter = [[GPUImageGrayscaleFilter alloc] init];
        self.inputImage = grayFilter;
    }
    return self;
}

- (BOOL) render
{
    if (![self.program valueForKey:@"imageWidthFactor"]
        || ![self.program valueForKey:@"imageHeightFactor"])
    {
        self.imageWidthFactor = self.size.width;
        self.imageHeightFactor = self.size.height;
    }
    return [super render];
}

// Normally we'd set this on our own program, but here, we pass it along as
// input to the luminance filter.

- (void) setInputImage:(id <GPUImageSource>)img
{
    [[program valueForKey:@"inputImage"] setValue:img forKey:@"inputImage"];
}

@end

