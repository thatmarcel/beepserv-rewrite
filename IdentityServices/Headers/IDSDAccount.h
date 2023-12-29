#import "IDSServiceProperties.h"

@interface IDSDAccount: NSObject
    @property(readonly, nonatomic) IDSServiceProperties* service;
    - (void) _refreshRegistration;
    - (void) _reregister;
    - (void) reregister;
    - (void) _reregisterAndReidentify:(bool)shouldReidentify;
    - (void) _reAuthenticate;
    - (bool) isRegistrationActive;
    - (void) registerAccount;
    - (void) _registerAccount;
    - (void) _setupAccount;
    - (void) activateRegistration;
    - (id) registration;
@end