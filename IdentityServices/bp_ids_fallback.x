#import "./bp_ids_fallback.h"
#import "./Tweak.h"
#import "./Logging.h"
#import "../Shared/NSDistributedNotificationCenter.h"
#import "Headers/IDSDAccount.h"
#import "Headers/IDSDAccountController.h"

%hook IDSRegistrationMessage
    - (void) setValidationData:(NSData*)data {
        LOG(@"IDSRegistrationMessage setValidationData was called with data: %@", data);
        
        if (bp_is_using_fallback_method) {
            bp_handle_validation_data(data, true);
        }

        %orig;
    }
%end

NSError* bp_start_fallback_validation_data_request() {
    LOG(@"Trying to generate validation data via fallback method");
    
    IDSDAccountController* controller = [%c(IDSDAccountController) sharedInstance];
    NSArray<IDSDAccount*>* accounts = controller.accounts;
    
    for (IDSDAccount* account in accounts) {
        // LOG(@"Account: %@, registration: %@", account, account.registration);
        
        // Make sure this is an iMessage account
        // (not completely sure whether this is necessary)
        if (![account.service.identifier isEqual: @"com.apple.madrid"]) {
            continue;
        }
        
        if (!account.registration) {
            LOG(@"Account has no registration, activating registration");
            [account activateRegistration];
        } else {
            LOG(@"Account has registration");
        }
        
        LOG(@"Re-registering account");
        
        // This leads to -[IDSRegistrationMessage setValidationData:] being called
        [account reregister];
        
        return nil;
    }
    
    return [NSError errorWithDomain: kSuiteName code: 0 userInfo: @{
        @"Error Reason": @"No account found"
    }];
}