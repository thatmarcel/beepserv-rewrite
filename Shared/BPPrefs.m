#import "./BPPrefs.h"
#import "./Constants.h"

// Because this file is shared between modules, we cannot use the
// module-specific logging files
#import "./Constants.h"
#define LOG(...) bp_log_impl(@"Prefs", [NSString stringWithFormat: __VA_ARGS__])
void bp_log_impl(NSString* moduleName, NSString* logString);

@implementation BPPrefs
    + (BOOL) shouldShowNotifications {
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", kPrefsFilePath]];
        NSDictionary* serializedState = [NSDictionary dictionaryWithContentsOfURL: url error: nil];
        
        return (serializedState && serializedState[kPrefsKeyShouldShowNotifications])
            ? [(NSNumber*) serializedState[kPrefsKeyShouldShowNotifications] boolValue]
            : true;
    }
    
    + (void) setShouldShowNotifications:(BOOL)shouldShowNotificationsFromNowOn {
        NSError *writingError;
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", kPrefsFilePath]];
        [@{
            kPrefsKeyShouldShowNotifications: [NSNumber numberWithBool: shouldShowNotificationsFromNowOn]
        } writeToURL: url error: &writingError];
        
        if (writingError) {
            LOG(@"Writing whether notifications should be shown to disk failed with error: %@", writingError);
        }
    }
@end