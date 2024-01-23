#import <Foundation/Foundation.h>

extern bool bp_is_using_fallback_method;

void bp_handle_validation_data(NSData* validationData, bool isFallbackMethod);