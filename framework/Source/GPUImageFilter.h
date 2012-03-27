#import <UIKit/UIKit.h>
#import "GPUImageProgram.h"
#import "GPUImage.h"
#import "GPUImageProgram.h"

// A GPUImageFilter is a GPUImage that uses an OpenGL program to transform
// its input image. 
//
// By convention, the OpenGL uniform for the input texture should be
// named inputImage. The vertex attribute for position should be 
// named "position" and the input texture coordinate, "inputImageCoordinate".
//
// It's possible to use different names with a few lines of overridden code, 
// but conforming to these conventions will enhance clarity.
//
// It is perfectly legitimate to instantiate GPUImageFilter directly.
//
// GPUImageFilter automatically adopts as parents the values of all OpenGL
// uniforms that are GPUImageSource-compliant objects. For example, the line
//
// program.inputImage = otherImage
//
// makes GPUImageFilter validate otherImage before rendering itself.

@interface GPUImageFilter : GPUImageBase <GPUImageSource>
{
    GPUImageProgram *program;
    GPUImageTimestamp timeLastChanged;
}

@property (nonatomic, retain) GPUImageProgram *program;

// These properties are defined for convenience. They will not necessarily
// be used by all filters. Values are passed on to the OpenGL program.

@property (nonatomic, retain) id <GPUimageSource> inputImage;
@property (nonatomic, retain) id <GPUimageSource> auxilliaryImage;

- (BOOL) render;

// Called as part of render; override if you don't want std triangulation
- (void) draw;

// Still image processing convenience methods
- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter;

@end
