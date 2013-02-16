#import "GPUImageStretchDistortionFilter.h"

NSString *const kGPUImageStretchDistortionFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;

    uniform highp vec2 center;

    void main()
    {
        highp vec2 normCoord = 2.0 * textureCoordinate - 1.0;
        highp vec2 normCenter = 2.0 * center - 1.0;

        normCoord -= normCenter;
        mediump vec2 s = sign(normCoord);
        normCoord = abs(normCoord);
        normCoord = 0.5 * normCoord + 0.5 * smoothstep(0.25, 0.5, normCoord) * normCoord;
        normCoord = s * normCoord;

        normCoord += normCenter;

        mediump vec2 textureCoordinateToUse = normCoord / 2.0 + 0.5;

        gl_FragColor = texture2D(inputImage, textureCoordinateToUse );
    }
);

@implementation GPUImageStretchDistortionFilter

@dynamic center;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageStretchDistortionFragmentShaderString;
    }
    self.center = CGPointMake(0.5, 0.5);
    return self;
}

@end
