#import "GPUImageHazeFilter.h"

NSString *const kGPUImageHazeFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputTexture;

    uniform lowp float distance;
    uniform highp float slope;

    void main()
    {
        //todo reconsider precision modifiers	 
        highp vec4 color = vec4(1.0);//todo reimplement as a parameter
        highp float  d = textureCoordinate.y * slope  +  distance; 
        highp vec4 c = texture2D(inputTexture, textureCoordinate) ; // consider using unpremultiply

        c = (c - d * color) / (1.0 -d); 

        gl_FragColor = c; //consider using premultiply(c);
    }
);

@implementation GPUImageHazeFilter

@dynamic distance, slope;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageHazeFragmentShaderString;
        self.distance = 0.2;
        self.slope = 0.0
    }
    return self;
}

@end

