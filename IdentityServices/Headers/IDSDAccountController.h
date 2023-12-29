#import "IDSDAccount.h"

@interface IDSDAccountController: NSObject
    + (instancetype) sharedInstance;
    
    - (NSArray<IDSDAccount*>*) accounts;
@end