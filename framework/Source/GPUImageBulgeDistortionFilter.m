#import "GPUImageBulgeDistortionFilter.h"

NSString *const kGPUImageBulgeDistortionFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImageTexture;

    uniform highp vec2 center;
    uniform highp float radius;
    uniform highp float scale;

    void main()
    {
        highp vec2 textureCoordinateToUse = textureCoordinate;
        highp float dist = distance(center, textureCoordinate);
        textureCoordinateToUse -= center;
        if (dist < radius) {
            highp float percent = 1.0 - ((radius - dist) / radius) * scale;
            percent = percent * percent;
            textureCoordinateToUse = textureCoordinateToUse * percent;
        }
        textureCoordinateToUse += center;
        gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    }
);

@implementation GPUImageBulgeDistortionFilter

@dynamic radius, scale;
@synthesize center = _center;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageBulgeDistortionFragmentShaderString;
        self.radius = 0.25;
        self.scale = 0.5;
        self.center = CGPointMake(0.5, 0.5);
    }
    return self;
}

- (void)setCenter:(CGPoint)newValue
{
    _center = newValue;
    vec2 centerPos = {newValue.x, newValue.y};
    [self.program setValue:UNIFORM(centerPos) forKey:@"center"];
}

@end
