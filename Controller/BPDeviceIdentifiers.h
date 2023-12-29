#import <UIKit/UIKit.h>

@interface BPDeviceIdentifiers: NSObject
    // Caches the identifiers if needed and then returns the cached identifiers
    + (NSDictionary*) get;
    // Generates the dictionary with the identifiers and caches it for later use
    + (void) cache;
@end