#import <UIKit/UIKit.h>
#import "GPUImageProgram.h"
#import "GPUImage.h"
#import "GPUImageProgram.h"

// A GPUImageFilter is a GPUImage that uses an OpenGL program to transform
// its input image. 
//
// By convention, the OpenGL uniform for the input texture should be
// named inputTexture. The vertex attribute for position should be 
// named "position" and the input texture coordinate, "inputTextureCoordinate".
//
// It's possible to use different names with a few lines of overridden code, 
// but conforming to these conventions will generally make things clearer.

@interface GPUImageFilter : GPUImage
{
    GPUImageProgram *program;
}

- (BOOL) render;

// Called as part of render; override if you don't want std triangulation

- (void) draw;

// Still image processing convenience methods
- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter;

@end
