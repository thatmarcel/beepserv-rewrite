#import "BPNotificationSender.h"
#import "./Logging.h"
#import "../Shared/BPPrefs.h"
#import "../Shared/NSDistributedNotificationCenter.h"

@implementation BPNotificationSender
    + (void) sendNotificationWithMessage:(NSString*)message {
        if (![BPPrefs shouldShowNotifications]) {
            return;
        }
        
        LOG(@"Telling the NotificationHelper to send a notification bulletin");
        
        // Tell the NotificationHelper to send a notification bulletin
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationSendNotificationBulletin
            object: nil
            userInfo: @{ kMessageText: message }
        ];
    }
@end