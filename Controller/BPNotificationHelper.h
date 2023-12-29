#import <Foundation/Foundation.h>

@interface BPNotificationHelper: NSObject
    // Sends a notification (bulletin) that's shown to the user
    + (void) sendNotificationWithMessage:(NSString*)message;
@end