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
     mediump vec4 whiteColor = vec4(1.0);
     gl_FragColor = abs(textureColor2 - textureColor);
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

