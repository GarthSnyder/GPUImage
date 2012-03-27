#import "GPUImageAdaptiveThresholdFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputTexture;
    uniform sampler2D inputTexture2; 

    void main()
    {
        highp vec4 textureColor = texture2D(inputTexture, textureCoordinate);
        highp float localLuminance = texture2D(inputTexture2, textureCoordinate).r;
        highp float thresholdResult = step(localLuminance - 0.05, textureColor.r);

        gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
        //     gl_FragColor = vec4(localLuminance, textureColor.r, 0.0, textureColor.w);
    }
);

@implementation GPUImageAdaptiveThresholdFilter

- (id) init
{
    if (self = [super init]) 
    {
        grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
        boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
        
        [boxBlurFilter deriveFrom:grayscaleFilter];
        self.accessoryTexture = boxBlurFilter;
        
        program.fragmentShader = kGPUImageAdaptiveThresholdFragmentShaderString;
        [program setValue:boxBlurFilter forKey:@"acc
         
        // First pass: reduce to luminance
        [self.filters addObject:[[GPUImageGrayscaleFilter alloc] init]];
        
        // Second pass: perform a box blur
        [self.filters addObject:[[GPUImageBoxBlurFilter alloc] init]];
        
        // Third pass: compare the blurred background luminance to the local value
        GPUImageFilter *adaptiveThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
        [self addFilter:adaptiveThresholdFilter];
        
        [self setTargetFilter:boxBlurFilter forFilter:luminanceFilter];
        [self setTargetFilter:adaptiveThresholdFilter forFilter:luminanceFilter];
        [self setTargetFilter:adaptiveThresholdFilter forFilter:boxBlurFilter];
        
        return self;
       
    }
    
     // First pass: reduce to luminance
     GPUImageGrayscaleFilter *luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
     [self addFilter:luminanceFilter];
     
     // Second pass: perform a box blur
     GPUImageBoxBlurFilter *boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
     [self addFilter:boxBlurFilter];
     
     // Third pass: compare the blurred background luminance to the local value
     GPUImageFilter *adaptiveThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
     [self addFilter:adaptiveThresholdFilter];
         
     boxBlurFilter.inputTexture = luminanceFilter;
     adaptiveThresholdFilter.inputTexture = luminanceFilter;
     adaptiveThresholdFilter.accessoryTexture = boxBlurFilter;
     
     [self setTargetFilter:boxBlurFilter forFilter:luminanceFilter];
     [self setTargetFilter:adaptiveThresholdFilter forFilter:luminanceFilter];
     [self setTargetFilter:adaptiveThresholdFilter forFilter:boxBlurFilter];
         
         
    // First pass: reduce to luminance
    GPUImageGrayscaleFilter *luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
    [self addFilter:luminanceFilter];
    
    // Second pass: perform a box blur
    GPUImageBoxBlurFilter *boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [self addFilter:boxBlurFilter];
    
    // Third pass: compare the blurred background luminance to the local value
    GPUImageFilter *adaptiveThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
    [self addFilter:adaptiveThresholdFilter];
    
    [luminanceFilter addTarget:boxBlurFilter];
    [luminanceFilter addTarget:adaptiveThresholdFilter];
    [boxBlurFilter addTarget:adaptiveThresholdFilter];
    
    self.initialFilters = [NSArray arrayWithObject:luminanceFilter];
    self.terminalFilter = adaptiveThresholdFilter;
    
    return self;
}

@end
