#import "GPUImageOutput.h"
#import <UIKit/UIKit.h>

@interface GPUImageFilter : GPUImageGraphElement
{
    NSMutableArray *programs;
    NSMutableArray *outputTextures; 
    BOOL renderbufferRequested;
}

// These property names are conventional. If there are multiple program stages,
// these textures denote the first input and the very last output.
// More complex filters may use additional input and output textures if
// desired; they can also ignore the standard input and output textures
// with no ill effects if they wish.

@property (nonatomic) GPUImageTexture *inputTexture;
@property (nonatomic) GPUImageTexture *outputTexture;

// Override to automatically set up a framework for >1 program in series
+ (int) numberOfFilterPrograms;

// Convenience methods for subclasses
@property (readonly, nonatomic) GPUImageProgram *program;
@property (readonly, nonatomic) GPUImageProgram *programOne;
@property (readonly, nonatomic) GPUImageProgram *programTwo;
@property (readonly, nonatomic) GPUImageProgram *programThree;

// If you are not using the standard inputTexture, you'll want to override
// render in your subclass to set the proper size of the output texture.
// Then call [super render]. The default implementation sets the size
// from inputTexture if a size has not already been set.

- (BOOL) render;

// Called as part of render; override if you don't want std triangulation

- (void) draw;

// Still image processing convenience methods
- (UIImage *) outputAsUIImage;
- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter;

@end
