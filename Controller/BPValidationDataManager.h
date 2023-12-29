#import <Foundation/Foundation.h>

@interface BPValidationDataManager: NSObject
    @property (retain) NSData* cachedValidationData;
    @property double cachedValidationDataExpiryTimestamp;
    
    + (instancetype) sharedInstance;
    
    // Called when we receive a response from IdentityServices
    - (void) handleResponseWithValidationData:(NSData*)validationData validationDataExpiryTimestamp:(double)validationDataExpiryTimestamp error:(NSError*)error;
    
    // Sends a request for validation data to IdentityService
    - (void) request;
    
    // Returns the cached validation data if it exists and it is still valid
    - (NSData*) getCachedIfPossible;
@end