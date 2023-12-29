#import <Foundation/Foundation.h>

@interface BPPrefs: NSObject
    + (BOOL) shouldShowNotifications;
    + (void) setShouldShowNotifications:(BOOL)shouldShowNotificationsFromNowOn;
@end