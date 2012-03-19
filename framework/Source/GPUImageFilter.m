#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

@implementation GPUImageFilter

#pragma mark -
#pragma mark Rendering and drawing

- (id) init
{
    if (self = [super init]) {
        program = [GPUImageProgram program];
    }
    return self;
}

- (BOOL) render
{
    [self takeUnknownParametersFrom:parent];
    [program setValue:parent forKey:@"inputTexture"];
    if (![program use] || ![self bindAsFramebuffer]) {
        return NO;
    }
    [self draw];
    self.timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

- (void) draw
{
    static const GLfloat squareVertices[] = {
        -1.0, -1.0,
         1.0, -1.0,
        -1.0,  1.0,
         1.0,  1.0,
    };
    
    static const GLfloat squareTextureCoordinates[] = {
         0.0,  0.0,
         1.0,  0.0,
         0.0,  1.0,
         1.0,  1.0,
    };
    
    GLint position = [program indexOfAttribute:@"position"];
    GLint itc = [program indexOfAttribute:@"inputTextureCoordinate"];
    
    glVertexAttribPointer(position, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(position);
    
    glVertexAttribPointer(itc, 2, GL_FLOAT, 0, 0, squareTextureCoordinates);
    glEnableVertexAttribArray(itc);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

#pragma mark -
#pragma mark Still image convenience methods

- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToFilter];
    [self deriveFrom:stillImageSource];
    [self update];
    [self deriveFrom:nil];
    return [self getUIImage];
}

#pragma mark -
#pragma mark Attribute and uniform processing

// TODO: Handle attribs and uniforms on behalf of program

@end
