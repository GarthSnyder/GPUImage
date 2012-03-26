#import <UIKit/UIKit.h>
#import "GPUImageBase.h"

@interface GPUImagePicture : GPUImageBase <GPUImageUpdating>

- (id) initWithImage:(UIImage *)img;

// May be changed at any time
@property (nonatomic) UIImage *image;

@end
