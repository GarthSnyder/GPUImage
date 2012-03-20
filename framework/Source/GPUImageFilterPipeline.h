#import <Foundation/Foundation.h>
#import "GPUImageFilter.h"

// A pipeline is a linear arrangement of one-in/one-out image filters.
// In effect, it is a filter wrapper that acts exactly like a filter.

@interface GPUImageFilterPipeline : GPUImage

@property (strong) NSMutableArray *filters;

- (id) initWithOrderedFilters:(NSArray *)filters;
- (id) initWithConfiguration:(NSDictionary *)configuration;
- (id) initWithConfigurationFile:(NSURL *)configuration;

// Filter array accessors are no longer needed because you can freely 
// add and remove filters directly in the filters array. But for
// convenience...

- (void) addFilter:(GPUImageFilter *)newFilter;

- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter;

@end
