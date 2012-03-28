#import "GPUImageSaturationFilter.h"

NSString *const kGPUImageSaturationFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform lowp float saturation;

    // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
    const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
        lowp vec3 greyScaleColor = vec3(luminance);

        gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
    }
);

@implementation GPUImageSaturationFilter

@dynamic saturation;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageSaturationFragmentShaderString;
        self.saturation = 1.0;
    }
    return self;
}

@end

