#import "Tweak.h"
#import <substrate.h>
#import "./bp_ids_offset_utils.h"
#import "./bp_ids_hooking_utils.h"
#import "./bp_ids_fallback.h"
#import "./Logging.h"
#import "../Shared/NSDistributedNotificationCenter.h"

bool bp_has_found_offsets = false;
bool bp_is_using_fallback_method = false;

void bp_handle_validation_data(NSData* validationData, bool isFallbackMethod) {
    double validationDataExpiryTimestamp;
    
    if (isFallbackMethod) {
        // Validation data should expire after 10 minutes
        validationDataExpiryTimestamp = [NSDate.date timeIntervalSince1970] + (10 * 60);
    } else {
        // Let's get fresh data after 30 seconds because why not
        validationDataExpiryTimestamp = [NSDate.date timeIntervalSince1970] + 30;
    }
    
    // Send validation data to the Controller
    // which then sends it to the relay
    [NSDistributedNotificationCenter.defaultCenter
        postNotificationName: kNotificationValidationDataResponse
        object: nil
        userInfo: @{
            kValidationData: validationData,
            kValidationDataExpiryTimestamp: [NSNumber numberWithDouble: validationDataExpiryTimestamp]
        }
    ];
}

@interface IDSValidationQueue: NSObject
    - (void) _sendAbsintheValidationCertRequestIfNeededForSubsystem:(long long)arg1;
@end

@interface IDSRegistrationCenter: NSObject
    + (instancetype) sharedInstance;
    
    // not in iOS 15+ (afaik)
    - (void) _sendAbsintheValidationCertRequestIfNeeded;
    
    // only in iOS 15+ (afaik)
    - (IDSValidationQueue*) validationQueue;
@end

// This should eventually lead to nac_key_establishment being called
bool bp_send_cert_request_if_needed() {
    IDSRegistrationCenter* registrationCenter = [%c(IDSRegistrationCenter) sharedInstance];
    
    if ([registrationCenter respondsToSelector: @selector(_sendAbsintheValidationCertRequestIfNeeded)]) {
        [[%c(IDSRegistrationCenter) sharedInstance]
            _sendAbsintheValidationCertRequestIfNeeded
        ];
        
    } else if ([registrationCenter respondsToSelector: @selector(validationQueue)]) {
        IDSValidationQueue* validationQueue = [registrationCenter validationQueue];
        
        if ([validationQueue respondsToSelector: @selector(_sendAbsintheValidationCertRequestIfNeededForSubsystem:)]) {
            [validationQueue _sendAbsintheValidationCertRequestIfNeededForSubsystem: 1];
        } else {
            return false;
        }
    } else {
        return false;
    }
    
    return true;
}

void bp_start_validation_data_request() {
    if (bp_has_found_offsets) {
        bool was_sending_cert_request_successful = bp_send_cert_request_if_needed();
        
        if (was_sending_cert_request_successful) {
            return;
        }
    }
    
    bp_is_using_fallback_method = true;
    
    NSError* fallback_error = bp_start_fallback_validation_data_request();
    
    if (fallback_error) {
        // Notify the Controller about the error
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationValidationDataResponse
            object: nil
            userInfo: @{
                kError: [NSError errorWithDomain: kSuiteName code: 0 userInfo: @{
                    @"Error Reason": @"No account found"
                }]
            }
        ];
    }
}

%ctor {
    LOG(@"Started");
    
    // Listen for validation data requests from
    // the Controller (which listens for requests from the relay)
    [NSDistributedNotificationCenter.defaultCenter
        addObserverForName: (NSString*) kNotificationRequestValidationData
        object: nil
        queue: NSOperationQueue.mainQueue
        usingBlock: ^(NSNotification* notification)
    {
        LOG(@"Received request for validation data");
        
        // Notify the Controller that we have received the request
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationRequestValidationDataAcknowledgement
            object: nil
            userInfo: nil
        ];
        
        bp_start_validation_data_request();
    }];
    
    LOG(@"Finding offsets");
    
    bp_has_found_offsets = bp_find_offsets();
    
    if (!bp_has_found_offsets) {
        LOG(@"Finding offsets failed");
        
        bp_is_using_fallback_method = true;
    } else {
        LOG(@"Found offsets");
        
        %init();
        
        bp_setup_hooks();
    }
}