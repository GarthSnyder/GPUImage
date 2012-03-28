#import "GPUImagePosterizeFilter.h"

NSString *const kGPUImagePosterizeFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImage;
 uniform highp float colorLevels;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImage, textureCoordinate);
     
     gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
 }
);

@implementation GPUImagePosterizeFilter

@synthesize colorLevels = _colorLevels;

#pragma mark -
#pragma mark Initialization

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePosterizeFragmentShaderString]))
    {
		return nil;
    }
    
    colorLevelsUniform = [filterProgram uniformIndex:@"colorLevels"];
    self.colorLevels = 10;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColorLevels:(NSUInteger)newValue;
{
    _colorLevels = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(colorLevelsUniform, (GLfloat)_colorLevels);
}

@end

