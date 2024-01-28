#import "BPValidationDataManager.h"
#import "BPSocketConnectionManager.h"
#import "BPNotificationSender.h"
#import "../Shared/NSDistributedNotificationCenter.h"
#import "./Logging.h"

BPValidationDataManager* _sharedInstance;

@implementation BPValidationDataManager
    @synthesize cachedValidationData;
    @synthesize cachedValidationDataExpiryTimestamp;
    @synthesize validationDataRequestAcknowledgementTimer;
    @synthesize validationDataResponseTimer;
    
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
        
        // Listen for acknowledgements from IdentityServices
        // of validation data requests
        [NSDistributedNotificationCenter.defaultCenter
            addObserverForName: kNotificationRequestValidationDataAcknowledgement
            object: nil
            queue: NSOperationQueue.mainQueue
            usingBlock: ^(NSNotification* notification)
        {
            [self handleValidationDataRequestAcknowledgement];
        }];
        
        return self;
    }
    
    - (void) handleResponseWithValidationData:(NSData*)validationData validationDataExpiryTimestamp:(double)validationDataExpiryTimestamp error:(NSError*)error {
        if (self.validationDataResponseTimer) {
            [self.validationDataResponseTimer invalidate];
            self.validationDataResponseTimer = nil;
        }
        
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
        
        // Notify the user that identityservicesd does not respond
        // if it doesn't acknowledge the request in the next 3 seconds
        self.validationDataRequestAcknowledgementTimer = [BPTimer
            scheduleTimerWithTimeInterval: 3
            completion: ^{
                [self handleValidationDataRequestDidNotReceiveAcknowledgement];
            }
        ];
        
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
    
    - (void) handleValidationDataRequestAcknowledgement {
        if (self.validationDataRequestAcknowledgementTimer) {
            [self.validationDataRequestAcknowledgementTimer invalidate];
            self.validationDataRequestAcknowledgementTimer = nil;
        }
        
        self.validationDataResponseTimer = [BPTimer
            scheduleTimerWithTimeInterval: 20
            completion: ^{
                [self handleValidationDataRequestDidNotReceiveResponse];
            }
        ];
    }
    
    - (void) handleValidationDataRequestDidNotReceiveAcknowledgement {
        NSString* messageText = @"Retrieving validation data failed because identityservicesd did not respond. Try reinstalling the tweak or restarting your device. If that fails, report this problem and try using an older version for now.";
        
        LOG(@"%@", messageText);
        [BPNotificationSender sendNotificationWithMessage: messageText];
    }
    
    - (void) handleValidationDataRequestDidNotReceiveResponse {
        NSString* messageText = @"Retrieving validation data failed because identityservicesd did not respond with validation data. Try again, do a userspace reboot, or try reinstalling the tweak. If none of those help, report this problem and try using an older version for now.";
        
        LOG(@"%@", messageText);
        [BPNotificationSender sendNotificationWithMessage: messageText];
    }
@end