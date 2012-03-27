#import "GPUImageFilterPipeline.h"

@interface GPUImageFilterPipeline ()
{
    NSUInteger arrayHash;
}
- (BOOL) parseConfiguration:(NSDictionary *)configuration;
- (void) setupFilters;
@end

@interface nsArray (QuickContentsHash)
- (NSUInteger) quickContentsHash;
@end

@implementation GPUImageFilterPipeline

@synthesize filters = _filters;

#pragma mark Config file init

- (id) init
{
    if (self = [super init]) {
        self.filters = [NSMutableArray array];
    }
    return self;
}

- (id) initWithConfiguration:(NSDictionary*) configuration 
{
    if (self = [super init]) {
        if (![self _parseConfiguration:configuration]) {
            NSLog(@"Sorry, a parsing error occurred.");
            abort();
        }
    }
    return self;
}

- (id) initWithConfigurationFile:(NSURL *)configuration {
    return [self initWithConfiguration:[NSDictionary dictionaryWithContentsOfURL:configuration]];
}

- (BOOL) parseConfiguration:(NSDictionary *)configuration
{
    NSArray *filters = [configuration objectForKey:@"Filters"];
    if (!filters) return NO;
    
    NSError *regexError = nil;
    NSRegularExpression *parsingRegex = [NSRegularExpression regularExpressionWithPattern:@"(float|CGPoint)\\((.*?)(?:,\\s*(.*?))*\\)"
                                                                                  options:0
                                                                                    error:&regexError];
    
    // It's faster to put them into an array and then pass it to the filters property than it is to call [self addFilter:] every time
    NSMutableArray *orderedFilters = [NSMutableArray arrayWithCapacity:[filters count]];
    for (NSDictionary *filter in filters) {
        NSString *filterName = [filter objectForKey:@"FilterName"];
        Class theClass = NSClassFromString(filterName);
        GPUImageFilter *genericFilter = [[theClass alloc] init];
        // Set up the properties
        NSDictionary *filterAttributes;
        if ((filterAttributes = [filter objectForKey:@"Attributes"])) {
            for (NSString *propertyKey in filterAttributes) {
                // Set up the selector
                SEL theSelector = NSSelectorFromString(propertyKey);
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[theClass instanceMethodSignatureForSelector:theSelector]];
                [inv setSelector:theSelector];
                [inv setTarget:genericFilter];
                
                // Parse the argument
                
                NSString *string = [filterAttributes objectForKey:propertyKey];
                NSTextCheckingResult *parse = [parsingRegex firstMatchInString:string
                                                                       options:0
                                                                         range:NSMakeRange(0, [string length])];
                NSLog(@"Ranges: %d", parse.numberOfRanges);
                NSString *modifier = [string substringWithRange:[parse rangeAtIndex:1]];
                if ([modifier isEqualToString:@"float"]) {
                    // Float modifier, one argument
                    CGFloat value = [[string substringWithRange:[parse rangeAtIndex:2]] floatValue];
                    [inv setArgument:&value atIndex:2];
                } else if ([modifier isEqualToString:@"CGPoint"]) {
                    // CGPoint modifier, two float arguments
                    CGFloat x = [[string substringWithRange:[parse rangeAtIndex:2]] floatValue];
                    CGFloat y = [[string substringWithRange:[parse rangeAtIndex:3]] floatValue];
                    CGPoint value = CGPointMake(x, y);
                    [inv setArgument:&value atIndex:2];
                } else {
                    return NO;
                }
                
                [inv invoke];
            }
        }
        [orderedFilters addObject:genericFilter];
    }
    self.filters = orderedFilters;    
    return YES;
}

#pragma mark Regular init

- (id) initWithOrderedFilters:(NSArray *) filters 
{
    if (self = [super init]) {
        self.filters = [NSMutableArray arrayWithArray:filters];
    }
    return self;
}

#pragma mark -
#pragma mark GPUImageConsumer protocol

- (void) deriveFrom:(id <GPUImageSource>)newParent;
{
    if (parent != newParent) {
        parent = newParent
        timeLastChanged = 0;
    }
}

#pragma mark -
#pragma mark GPUImageSource protocol

// The filters in the pipeline are in fact an independent GPUImageUpdating
// object subgraph. The GPUImageFilterPipeline patches this subgraph into
// its parent graph by acting as both the head (when specifying an external
// source as input to the pipeline through [pipeline deriveFrom:]) and the tail
// (when absorbing the output of the pipeline and forwarding it downstream).
//
// To implement this dual role, all we have to do is make sure our pipeline
// is properly wired up and then temporarily tack ourselves on as the tail 
// of the pipeline during -update.

- (BOOL) update
{
    if (!parent || ![parent update]) {
        return NO;
    }
    [self setupFilters];
    id <GPUImageSource> trueParent = parent;
    parent = [self.filters lastObject];
    BOOL result = [super update];
    parent = trueParent;
    return result;
}

- (void) setupFilters
{
    // Make a quick determination as to whether the array has changed
    NSUInteger newHash = [self.filters quickContentsHash];
    if (arrayHash && (newHash == arrayHash)) {
        return;
    }
    arrayHash = newHash;
    id <GPUImageSource> previous = parent;
    for (id <GPUImageConsumer> filter in self.filters) {
        [filter deriveFrom:previous];
        previous = filter;
    }
}

@end

@implementation NSArray (QuickContentsHash)

- (NSUInteger) quickContentsHash
{
    NSUInteger hashValue = 0;
    for (id object in self) {
        hashValue ^= (NSUInteger)object;
    }
    return hashValue;
}

@end
