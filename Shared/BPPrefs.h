#import <Foundation/Foundation.h>

@interface BPPrefs: NSObject
    // Reads the prefs file and return whether to show notifications, or true by default
    + (BOOL) shouldShowNotifications;
    // Stores whether to show notifications in the prefs file
    + (void) setShouldShowNotifications:(BOOL)shouldShowNotificationsFromNowOn;
@end