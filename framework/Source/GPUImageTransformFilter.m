#import "GPUImageTransformFilter.h"

NSString *const kGPUImageTransformVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    uniform mat4 transformMatrix;

    varying vec2 textureCoordinate;

    void main()
    {
        gl_Position = transformMatrix * vec4(position.xyz, 1.0);
        textureCoordinate = inputTextureCoordinate.xy;
    }
);

@implementation GPUImageTransformFilter

@synthesize transform3D = _transform3D;

- (id) init
{
    if (self = [super init]) {
        self.program.vertexShader = kGPUImageTransformVertexShaderString;
        self.transform3D = CATransform3DIdentity;
    }
    return self;
}

- (BOOL) render
{
    [self clearFramebuffer];
    return [super render];
}

#pragma mark -
#pragma mark Conversion from matrix formats

- (void) convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
{
	//	struct CATransform3D
	//	{
	//		CGFloat m11, m12, m13, m14;
	//		CGFloat m21, m22, m23, m24;
	//		CGFloat m31, m32, m33, m34;
	//		CGFloat m41, m42, m43, m44;
	//	};
	
	matrix[0] = (GLfloat)transform3D->m11;
	matrix[1] = (GLfloat)transform3D->m12;
	matrix[2] = (GLfloat)transform3D->m13;
	matrix[3] = (GLfloat)transform3D->m14;
	matrix[4] = (GLfloat)transform3D->m21;
	matrix[5] = (GLfloat)transform3D->m22;
	matrix[6] = (GLfloat)transform3D->m23;
	matrix[7] = (GLfloat)transform3D->m24;
	matrix[8] = (GLfloat)transform3D->m31;
	matrix[9] = (GLfloat)transform3D->m32;
	matrix[10] = (GLfloat)transform3D->m33;
	matrix[11] = (GLfloat)transform3D->m34;
	matrix[12] = (GLfloat)transform3D->m41;
	matrix[13] = (GLfloat)transform3D->m42;
	matrix[14] = (GLfloat)transform3D->m43;
	matrix[15] = (GLfloat)transform3D->m44;
}

#pragma mark -
#pragma mark Accessors

- (void) setAffineTransform:(CGAffineTransform)newValue
{
    self.transform3D = CATransform3DMakeAffineTransform(newValue);
}

- (CGAffineTransform) affineTransform;
{
    return CATransform3DGetAffineTransform(self.transform3D);
}

- (void) setTransform3D:(CATransform3D)newValue
{
    _transform3D = newValue;

    GLfloat temporaryMatrix[16];
    
    [self convert3DTransform:&_transform3D toMatrix:temporaryMatrix];
    NSValue *obj = UNIFORM(temporaryMatrix);
    [program setValue:obj forKey:@"transformMatrix"];
}

@end
