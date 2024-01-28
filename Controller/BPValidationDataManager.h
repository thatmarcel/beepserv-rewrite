#import <Foundation/Foundation.h>
#import "../Shared/BPTimer.h"

@interface BPValidationDataManager: NSObject
    @property (retain) NSData* cachedValidationData;
    @property double cachedValidationDataExpiryTimestamp;
    // Timer that fires if we have sent a request for validation data
    // and not received an acknowledgement in a specific amount of time.
    // This lets us know if something is wrong with the
    // identityservicesd tweak
    @property (retain) BPTimer* validationDataRequestAcknowledgementTimer;
    // Timer that fires if we have sent a request for validation data
    // and not received a response in a specific amount of time.
    // This lets us know if something went wrong
    @property (retain) BPTimer* validationDataResponseTimer;
    
    + (instancetype) sharedInstance;
    
    // Called when we receive a response from IdentityServices
    - (void) handleResponseWithValidationData:(NSData*)validationData validationDataExpiryTimestamp:(double)validationDataExpiryTimestamp error:(NSError*)error;
    
    // Sends a request for validation data to IdentityService
    - (void) request;
    
    // Returns the cached validation data if it exists and it is still valid
    - (NSData*) getCachedIfPossible;
    
    - (void) handleValidationDataRequestAcknowledgement;
    - (void) handleValidationDataRequestDidNotReceiveAcknowledgement;
    
    - (void) handleValidationDataRequestDidNotReceiveResponse;
@end