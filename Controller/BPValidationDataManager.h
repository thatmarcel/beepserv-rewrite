@interface BPValidationDataManager: NSObject
    @property (retain) NSData* cachedValidationData;
    @property double cachedValidationDataExpiryTimestamp;
    
    + (instancetype) sharedInstance;
    
    - (void) handleResponseWithValidationData:(NSData*)validationData validationDataExpiryTimestamp:(double)validationDataExpiryTimestamp error:(NSError*)error;
    
    - (void) request;
    - (NSData*) getCachedIfPossible;
@end