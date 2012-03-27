#import "GPUImageDifferenceBlendFilter.h"

NSString *const kGPUImageDifferenceBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputTexture;
 uniform sampler2D inputTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputTexture2, textureCoordinate);
     gl_FragColor = vec4(abs(textureColor2.rgb - textureColor.rgb), textureColor.a);
 }
);

@implementation GPUImageDifferenceBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDifferenceBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

