// Garth Snyder - 3/14/2012

#import "GPUImageProtocols.h"

static GPUImageTimestamp currentTimestamp = 0;

// TODO: Evaluate need for thread-safety.

GPUImageTimestamp GPUImageGetCurrentTimestamp()
{
    return currentTimestamp++;
}
