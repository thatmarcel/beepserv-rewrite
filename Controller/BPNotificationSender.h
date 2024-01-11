#import <Foundation/Foundation.h>

@interface BPNotificationSender: NSObject
    // Sends a notification (bulletin) that's shown to the user
    + (void) sendNotificationWithMessage:(NSString*)message;
@end