#import "GPUImageTypes.h"

// Start at 100 just to distinguish from 0
static GPUImageTimestamp currentTimestamp = 100; 

GPUImageTimestamp GPUImageGetCurrentTimestamp()
{
    return currentTimestamp++;
}
