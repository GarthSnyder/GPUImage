//
//  Created by Garth Snyder on 3/15/12.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

@interface GPUImageShaderSymbol : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) GLint index;
@property (nonatomic) GLenum type;
@property (nonatomic) GLint count;
@property (nonatomic) GLenum textureUnit;

@end
