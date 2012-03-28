#import "GPUImageSwirlFilter.h"

// Adapted from the shader example here: http://www.geeks3d.com/20110428/shader-library-swirl-post-processing-filter-in-glsl/

NSString *const kGPUImageSwirlFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;

    uniform highp vec2 center;
    uniform highp float radius;
    uniform highp float angle;

    void main()
    {
        highp vec2 textureCoordinateToUse = textureCoordinate;
        highp float dist = distance(center, textureCoordinate);
        textureCoordinateToUse -= center;
        if (dist < radius)
        {
             highp float percent = (radius - dist) / radius;
             highp float theta = percent * percent * angle * 8.0;
             highp float s = sin(theta);
             highp float c = cos(theta);
             textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
        }
        textureCoordinateToUse += center;
        gl_FragColor = texture2D(inputImage, textureCoordinateToUse );
    }
);

@implementation GPUImageSwirlFilter

@dynamic radius, angle;
@synthesize center = _center;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageSwirlFragmentShaderString;
        self.radius = 0.5;
        self.angle = 1.0;
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
