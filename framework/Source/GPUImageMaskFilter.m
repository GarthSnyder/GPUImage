#import "GPUImageMaskFilter.h"

NSString *const kGPUImageMaskShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);

        //Averages mask's the RGB values, and scales that value by the mask's alpha
        //
        //The dot product should take fewer cycles than doing an average normally
        //
        //Typical/ideal case, R,G, and B will be the same, and Alpha will be 1.0
        lowp float newAlpha = dot(textureColor2.rgb, vec3(.33333334, .33333334, .33333334)) * textureColor2.a;
         
        gl_FragColor = vec4(textureColor.xyz, newAlpha);
    }
 );

@implementation GPUImageMaskFilter

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageMaskShaderString;
    }
    return self;
}

@end

