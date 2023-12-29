#import "./Logging.h"
#import "../Shared/NSDistributedNotificationCenter.h"
#import "Headers/IDSDAccount.h"
#import "Headers/IDSDAccountController.h"

// Logging events that could be useful for debugging
%hook IDSRegistrationController
    - (void) _notifyRegistrationStarting:(id)arg1 {
        LOG(@"IDSRegistrationController _notifyRegistrationStarting: %@", arg1);
        %orig;
    }
    
    - (void) _notifyRegistrationUpdated:(id)arg1 {
        LOG(@"IDSRegistrationController _notifyRegistrationUpdated: %@", arg1);
        %orig;
    }
    
    - (void) _notifyRegistrationSuccess:(id)arg1 {
        LOG(@"IDSRegistrationController _notifyRegistrationSuccess: %@", arg1);
        %orig;
    }
    
    - (void) _notifyRegistrationFailure:(id)arg1 error:(long long)arg2 info:(id)arg3 {
        LOG(@"IDSRegistrationController _notifyRegistrationFailure: %@", arg1);
        %orig;
    }
    
    - (bool) registerInfo:(id)arg1 requireSilentAuth:(bool)arg2 {
        LOG(@"IDSRegistrationController registerInfo: %@, requireSilentAuth: %@", arg1, arg2 ? @"true" : @"false");
        return %orig;
    }
    
    - (bool) registerInfo:(id)arg1 {
        LOG(@"IDSRegistrationController registerInfo: %@", arg1);
        return %orig;
    }
%end

%hook IDSRegistrationMessage
    - (void) setValidationData:(NSData*)data {
        LOG(@"Got validation data: %@", data);
        
        double validationDataExpiryTimestamp = [NSDate.date timeIntervalSince1970] + 10 * 60;
        
        // Send validation data to the Controller
        // which then sends it to the relay
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationValidationDataResponse
            object: nil
            userInfo: @{
                kValidationData: data,
                kValidationDataExpiryTimestamp: [NSNumber numberWithDouble: validationDataExpiryTimestamp]
            }
        ];

        %orig;
    }
%end

void generateValidationData() {
    LOG(@"Trying to generate validation data");
    
    IDSDAccountController* controller = [%c(IDSDAccountController) sharedInstance];
    NSArray<IDSDAccount*>* accounts = controller.accounts;
    
    for (IDSDAccount* account in accounts) {
        LOG(@"Account: %@, registration: %@", account, account.registration);
        
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
        [account reregister];
        
        return;
    }
    
    [NSDistributedNotificationCenter.defaultCenter
        postNotificationName: kNotificationValidationDataResponse
        object: nil
        userInfo: @{
            kError: @"No account found"
        }
    ];
}

%ctor {
    LOG(@"Started");
    
    // Listen for validation data requests from
    // the Controller (which listens for requests from the relay)
    [NSDistributedNotificationCenter.defaultCenter
        addObserverForName: kNotificationRequestValidationData
        object: nil
        queue: NSOperationQueue.mainQueue
        usingBlock: ^(NSNotification* notification)
    {
        generateValidationData();
    }];
}