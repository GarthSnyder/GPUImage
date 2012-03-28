#import "GPUImageChromaKeyBlendFilter.h"

// Shader code based on Apple's CIChromaKeyFilter example: https://developer.apple.com/library/mac/#samplecode/CIChromaKeyFilter/Introduction/Intro.html

NSString *const kGPUImageChromaKeyBlendFragmentShaderString = SHADER_STRING
(
    precision highp float;

    varying highp vec2 textureCoordinate;

    uniform float thresholdSensitivity;
    uniform float smoothing;
    uniform vec3 colorToReplace;
    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        vec3 textureColor = texture2D(inputImage, textureCoordinate).rgb;
        vec3 textureColor2 = texture2D(auxilliaryImage, textureCoordinate).rgb;

        float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
        float maskCr = 0.7132 * (colorToReplace.r - maskY);
        float maskCb = 0.5647 * (colorToReplace.b - maskY);

        float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
        float Cr = 0.7132 * (textureColor.r - Y);
        float Cb = 0.5647 * (textureColor.b - Y);

        //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
        float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
        gl_FragColor = vec4(mix(textureColor, textureColor2, blendValue), 1.0);
    }
);

@implementation GPUImageChromaKeyBlendFilter

@dynamic smoothing, thresholdSensitivity, colorToReplace;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageChromaKeyBlendFragmentShaderString;
        self.thresholdSensitivity = 0.4;
        self.smoothing = 0.1;
        self.colorToReplace = (vec3){0.0, 1.0, 0.0};
    }
    return self;
}

@end

