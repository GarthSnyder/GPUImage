#import "GPUImageTypes.h"

static GPUImageTimestamp currentTimestamp = 0;

GPUImageTimestamp GPUImageGetCurrentTimestamp()
{
    return currentTimestamp++;
}
