#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

@interface GPUImageFilter
- (GPUImageProgram *) filterProgramAtIndex:(int)n;
@end

@implementation GPUImageFilter

@dynamic inputTexture;

#pragma mark -
#pragma mark Basic setup and utility

+ (int) numberOfFilterPrograms
{
    return 1;
}

- (id) init
{
    if (self = [super init]) {
        filterPrograms = [NSMutableArray array];
        int nFilters = [[self class] numberOfFilterPrograms];
        GPUImageTexture *texture = nil;
        for (int i = 0; i < nFilters; i++) {
            GPUImageProgram *newProgram = [GPUImageProgram program];
            if (texture) {
                [newProgram setValue:texture forKey:@"inputTexture"];
            }
            [filterPrograms addObject:newProgram];
            texture = [GPUImageTexture texture];
            [outputTextures addObject:texture];
        }
        [[outputTextures lastObject] deriveFrom:self];
    }
    return self;
}

- (GPUImageProgram *)filterProgram {
    return [self filterProgramAtIndex:0];
}

- (GPUImageProgram *)filterProgramOne {
    return [self filterProgramAtIndex:0];
}

- (GPUImageProgram *)filterProgramTwo {
    return [self filterProgramAtIndex:1];
}

- (GPUImageProgram *)filterProgramThree {
    return [self filterProgramAtIndex:2];
}

- (GPUImageProgram *)filterProgramAtIndex:(int)n {
    return [filterPrograms objectAtIndex:n];
}

- (GPUImageTexture *)outputTexture {
    return [outputTextures lastObject];
}

- (void) setOutputTexture:(GPUImageTexture *)texture 
{
    GPUImageTexture *oldOutput = [outputTextures lastObject];
    [outputTextures removeLastObject];
    [oldOutput undoDerivationFrom:self];
    [outputTextures addObject:texture];
    [texture deriveFrom:self];
}

#pragma mark -
#pragma mark Rendering and drawing

- (BOOL) render
{
    // This is called via the update method in GPUImageGraphElement, and is
    // ultimately instigated by whoever downstream from us is pulling our
    // product textures. By this point, all of our parent objects have been
    // made current, so we just need to set up our rendering environment
    // and draw.
    
    for (int i = 0; i < [filterPrograms count]; i++) {
        GPUImageProgram *program = [filterPrograms objectAtIndex:i];
        GPUImageTexture *output = [outputTextures objectAtIndex:i];
        if (program.inputTexture) {
            [output takeUnknownParametersFrom:program.inputTexture];
        }
        if (![program use] || ![output bindAsFramebuffer]) {
            return NO;
        }
        [self draw];
    }
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
    
    // TODO: Work out attrib management
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, squareTextureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

#pragma mark -
#pragma mark Still image convenience methods

- (UIImage *) outputAsUIImage
{
    return [self.outputTexture textureAsUIImage];
}

- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToFilter];
    [self.inputTexture deriveFrom:stillImageSource.outputTexture];
    [self.outputTexture update];
    [self.inputTexture underiveFrom:stillImageSource.outputTexture];
    return [self.outputTexture textureAsUIImage];
}

#pragma mark -
#pragma mark Attribute and uniform processing

// TODO: Handle attribs and uniforms on behalf of program

@end
