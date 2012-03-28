#import "GPUImagePixellateFilter.h"

NSString *const kGPUImagePixellationFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;

    uniform highp float fractionalWidthOfPixel;

    void main()
    {
        highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel);

        highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
        gl_FragColor = texture2D(inputImage, samplePos );
    }
);

@implementation GPUImagePixellateFilter

@synthesize fractionalWidthOfAPixel = _fractionalWidthOfAPixel;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImagePixellationFragmentShaderString;
        self.fractionalWidthOfAPixel = 0.05;
    }
    return self;
}

- (BOOL) render
{
    if (!self.size.width || !self.size.height) {
        self.size = self.inputImage.backingStore.size;
    }

    // Convert fractional width of a pixel
    CGFloat singlePixelSpacing;
    if (self.size.width) {
        singlePixelSpacing = 1.0 / self.size.width;
    } else {
        singlePixelSpacing = 1.0 / 2048.0;
    }
    if (_fractionalWidthOfAPixel < singlePixelSpacing) {
        _fractionalWidthOfAPixel = singlePixelSpacing;
    }

    [self.program setValue:[NSNumber numberWithFloat:_fractionalWidthOfAPixel] 
                    forKey:@"fractionalWidthOfPixel"];
    return [super render];
}

@end
