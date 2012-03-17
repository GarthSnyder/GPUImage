#import "GPUImageContrastFilter.h"

NSString *const kGPUImageContrastFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputTexture;
    uniform lowp float contrast;

    void main()
    {
        lowp vec3 textureColor = texture2D(inputTexture, textureCoordinate).rgb;
        gl_FragColor = vec4(((textureColor - vec3(0.5)) * contrast + vec3(0.5)), 1.0);
    }
);

@implementation GPUImageContrastFilter

@synthesize contrast = _contrast;

- (id) init;
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageContrastFragmentShaderString;
        self.contrast = 1.0;
    }
    return self;
}

- (void) setContrast:(GLfloat)contrast
{
    _contrast = contrast;
    [self.program setValue:[NSNumber numberWithFloat:contrast] forKey:@"contrast"];
}

@end
