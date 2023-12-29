#import "BPValidationDataManager.h"
#import "BPSocketConnectionManager.h"
#import "BPNotificationHelper.h"
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
        
        [NSDistributedNotificationCenter.defaultCenter
            addObserverForName: kNotificationValidationDataResponse
            object: nil
            queue: NSOperationQueue.mainQueue
            usingBlock: ^(NSNotification *notification)
        {
            NSDictionary *userInfo = notification.userInfo;
            LOG(@"Received broadcasted validation data response: %@", userInfo);
            
            NSData* validationData = userInfo[kValidationData];
            NSNumber* validationDataExpiryTimestamp = userInfo[kValidationDataExpiryTimestamp];
            NSError *error = userInfo[kError];
            
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
            [BPNotificationHelper sendNotificationWithMessage: [NSString stringWithFormat: @"Retrieving validation data failed with error: %@", error]];
            
            LOG(@"Retrieving validation data failed with error: %@", error);
        } else {
            cachedValidationData = validationData;
            cachedValidationDataExpiryTimestamp = validationDataExpiryTimestamp;
            
            [BPNotificationHelper sendNotificationWithMessage: @"Successfully retrieved validation data"];
            
            LOG(@"Successfully retrieved validation data");
        }
        
        [BPSocketConnectionManager.sharedInstance sendValidationData: validationData error: error];
    }
    
    - (void) request {
        LOG(@"Requesting new validation data");
        
        [BPNotificationHelper sendNotificationWithMessage: @"Requesting new validation data"];
        
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
        
        [BPNotificationHelper sendNotificationWithMessage: @"Using cached validation data"];
        
        return cachedValidationData;
    }
@end