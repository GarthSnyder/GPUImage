#import <UIKit/UIKit.h>
#import "GPUImageProtocols.h"
#import "GPUImage.h"

@interface GPUImageView : UIView

@property (nonatomic, retain) id <GPUImageSource> inputImage;

@end
