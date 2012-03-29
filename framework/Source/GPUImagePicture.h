#import <UIKit/UIKit.h>
#import "GPUImageBase.h"

@interface GPUImagePicture : GPUImageBase <GPUImageSource>

- (id) initWithImage:(UIImage *)img;

// May be changed at any time
@property (nonatomic, retain) UIImage *image;

@end
