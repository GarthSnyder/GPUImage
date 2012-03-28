#import "GPUImageVignetteFilter.h"

NSString *const kGPUImageVignetteFragmentShaderString = SHADER_STRING
(
    uniform sampler2D inputImage;
    varying highp vec2 textureCoordinate;

    uniform highp float vignetteX;
    uniform highp float vignetteY;

    void main()
    {
        lowp vec3 rgb = texture2D(inputImage, textureCoordinate).xyz;
        lowp float d = distance(textureCoordinate, vec2(0.5,0.5));
        rgb *= smoothstep(vignetteX, vignetteY, d);
        gl_FragColor = vec4(vec3(rgb),1.0);
    }
);


@implementation GPUImageVignetteFilter

@dynamic x, y;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageVignetteFragmentShaderString;
        self.x = 0.75;
        self.y = 0.50;
    }
    return self;
}

@end
