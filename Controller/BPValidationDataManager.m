#import "BPValidationDataManager.h"
#import "BPSocketConnectionManager.h"
#import "BPNotificationSender.h"
#import "../Shared/NSDistributedNotificationCenter.h"
#import "./Logging.h"

BPValidationDataManager* _sharedInstance;

@implementation BPValidationDataManager
    @synthesize cachedValidationData;
    @synthesize cachedValidationDataExpiryTimestamp;
    
    + (instancetype) sharedInstance {
        if (!_sharedInstance) {
            _sharedInstance = [[BPValidationDataManager alloc] init];
        }
        
        return _sharedInstance;
    }
    
    - (instancetype) init {
        self = [super init];
        
        // Listen for validation data responses from IdentityServices
        [NSDistributedNotificationCenter.defaultCenter
            addObserverForName: kNotificationValidationDataResponse
            object: nil
            queue: NSOperationQueue.mainQueue
            usingBlock: ^(NSNotification* notification)
        {
            NSDictionary* userInfo = notification.userInfo;
            LOG(@"Received broadcasted validation data response: %@", userInfo);
            
            NSData* validationData = userInfo[kValidationData];
            NSNumber* validationDataExpiryTimestamp = userInfo[kValidationDataExpiryTimestamp];
            NSError* error = userInfo[kError];
            
            [self
                handleResponseWithValidationData: validationData
                validationDataExpiryTimestamp: validationDataExpiryTimestamp ? [validationDataExpiryTimestamp doubleValue] : -1
                error: error
            ];
        }];
        
        return self;
    }
    
    - (void) handleResponseWithValidationData:(NSData*)validationData validationDataExpiryTimestamp:(double)validationDataExpiryTimestamp error:(NSError*)error {
        if (error) {
            [BPNotificationSender sendNotificationWithMessage: [NSString stringWithFormat: @"Retrieving validation data failed with error: %@", error]];
            
            LOG(@"Retrieving validation data failed with error: %@", error);
        } else {
            cachedValidationData = validationData;
            cachedValidationDataExpiryTimestamp = validationDataExpiryTimestamp;
            
            [BPNotificationSender sendNotificationWithMessage: @"Successfully retrieved validation data"];
            
            LOG(@"Successfully retrieved validation data");
        }
        
        [BPSocketConnectionManager.sharedInstance sendValidationData: validationData error: error];
    }
    
    - (void) request {
        LOG(@"Requesting new validation data");
        
        [BPNotificationSender sendNotificationWithMessage: @"Requesting new validation data"];
        
        // Send a validation data request to IdentityServices
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationRequestValidationData
            object: nil
            userInfo: nil
        ];
    }
    
    - (NSData*) getCachedIfPossible {
        if (cachedValidationData == nil || cachedValidationDataExpiryTimestamp <= [NSDate.date timeIntervalSince1970]) {
            LOG(@"No valid cached validation data exists");
            
            return nil;
        }
        
        LOG(@"Using cached validation data");
        
        [BPNotificationSender sendNotificationWithMessage: @"Using cached validation data"];
        
        return cachedValidationData;
    }
@end