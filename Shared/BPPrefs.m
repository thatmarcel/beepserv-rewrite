#import "./BPPrefs.h"
#import "./Constants.h"

// Because this file is shared between modules, we cannot use the
// module-specific logging files
#import "./Constants.h"
#define LOG(...) bp_log_impl(@"Shared", [NSString stringWithFormat: __VA_ARGS__])
void bp_log_impl(NSString* moduleName, NSString* logString);

@implementation BPPrefs
    + (BOOL) shouldShowNotifications {
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", PREFS_FILE_PATH]];
        
        NSDictionary* prefsDict;
        
        if (@available(iOS 11, *)) {
            prefsDict = [NSDictionary dictionaryWithContentsOfURL: url error: nil];
        } else {
            prefsDict = [NSDictionary dictionaryWithContentsOfURL: url];
        }
        
        return (prefsDict && prefsDict[kPrefsKeyShouldShowNotifications])
            ? [(NSNumber*) prefsDict[kPrefsKeyShouldShowNotifications] boolValue]
            : true;
    }
    
    + (void) setShouldShowNotifications:(BOOL)shouldShowNotificationsFromNowOn {
        NSError* writingError;
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", PREFS_FILE_PATH]];
        NSDictionary* prefsDict = @{
            kPrefsKeyShouldShowNotifications: [NSNumber numberWithBool: shouldShowNotificationsFromNowOn]
        };
        
        if (@available(iOS 11, *)) {
            [prefsDict writeToURL: url error: &writingError];
        } else {
            if (![prefsDict writeToURL: url atomically: true]) {
                writingError = [NSError errorWithDomain: kSuiteName code: 0 userInfo: @{
                    @"Error Reason": @"Unknown"
                }];
            }
        }
        
        if (writingError) {
            LOG(@"Writing whether notifications should be shown to disk failed with error: %@", writingError);
        }
    }
@end