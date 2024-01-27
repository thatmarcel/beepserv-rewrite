#import "BPNotificationHelper.h"
#import "./Logging.h"
#import "../Shared/NSDistributedNotificationCenter.h"

#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBBulletin.h>
#import <BulletinBoard/BBServer.h>

@interface BBServer (beepserv)
    - (void) publishBulletin:(BBBulletin*)bulletin destinations:(unsigned long long)destinations;
    
    - (void) publishBulletin:(BBBulletin*)bulletin destinations:(unsigned long long)destinations alwaysToLockScreen:(bool)alwaysToLockScreen;
    
    - (id) _sectionInfoForSectionID:(NSString*)sectionID effective:(BOOL)effective;
@end

@interface BBBulletin (beepserv)
    // Not sure if we need to set this for everything to behave normally but why not
    @property (nonatomic) bool clearable;
@end

// This gets set from the BBServer init hook and allows us to send notifications
static BBServer* notificationServer = nil;

// Notifications must be dispatched from this queue or the process will crash
static NSObject<OS_dispatch_queue>* notificationServerQueue = nil;

%hook BBServer
    - (instancetype) initWithQueue:(id)queue {
        notificationServer = %orig;
        notificationServerQueue = queue;
        
        return notificationServer;
    }
    
    - (id) initWithQueue:(id)queue dataProviderManager:(id)dataProviderManager syncService:(id)syncService dismissalSyncCache:(id)dismissalSyncCache observerListener:(id)observerListener utilitiesListener:(id)utilitiesListener conduitListener:(id)conduitListener systemStateListener:(id)systemStateListener settingsListener:(id)settingsListener {
        notificationServer = %orig;
        notificationServerQueue = queue;
        
        return notificationServer;
    }
    
    - (void) dealloc {
        if (notificationServer == self) {
            notificationServer = nil;
        }
        
        %orig;
    }
    
    // As the app does not request notification permission, this
    // would usually return nil for our app, but we make it return the
    // section info for Settings which makes the notification display
    - (id) _sectionInfoForSectionID:(NSString*)sectionID effective:(bool)effective {
        if ([sectionID isEqual: @"com.beeper.beepserv.app"]) {
            return [self _sectionInfoForSectionID: @"com.apple.Preferences" effective: effective];
        }
        
        return %orig;
    }
%end

@implementation BPNotificationHelper
    + (void) sendNotificationWithMessage:(NSString*)message {
        if (!notificationServer) {
            LOG(@"Not sending notification because BBServer is not set");
            return;
        }
        
        bool shouldUseOtherPublishMethod = false;
        
        if (![notificationServer respondsToSelector: @selector(publishBulletin:destinations:)]) {
            if ([notificationServer respondsToSelector: @selector(publishBulletin:destinations:alwaysToLockScreen:)]) {
                shouldUseOtherPublishMethod = true;
            } else {
                LOG(@"Not sending notification because BBServer does not respond to selector");
                return;
            }
        }
        
        BBBulletin* bulletin = [[%c(BBBulletin) alloc] init];
        
        bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.date = [NSDate date];
        bulletin.lastInterruptDate = [NSDate date];
        bulletin.turnsOnDisplay = false;
        
        bulletin.title = @"beepserv";
        bulletin.message = message;
        bulletin.sectionID = @"com.beeper.beepserv.app";
        
        // Open the beepserv app when the notification is tapped
        bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID: @"com.beeper.beepserv.app" callblock: nil];
        
        if ([bulletin respondsToSelector: @selector(setClearable:)]) {
            [bulletin setClearable: true];
        }
        
        // LOG(@"Dispatching in notification server queue");
        dispatch_sync(notificationServerQueue, ^{
            // LOG(@"Publishing notification");
            
            if (shouldUseOtherPublishMethod) {
                [notificationServer publishBulletin: bulletin destinations: 14 alwaysToLockScreen: false];
            } else {
                [notificationServer publishBulletin: bulletin destinations: 14];
            }
        });
    }
@end

%hook SpringBoard
    - (void) applicationDidFinishLaunching:(id)arg1 {
        %orig;
        
        LOG(@"SpringBoard launched");
        
        // Wait a bit to make sure SpringBoard has fully initialized
        [NSTimer
            scheduledTimerWithTimeInterval: 5
            repeats: false
            block: ^(NSTimer* timer) {
                // Wait for command to send a notification bulletin (from the Controller)
                [NSDistributedNotificationCenter.defaultCenter
                    addObserverForName: kNotificationSendNotificationBulletin
                    object: nil
                    queue: NSOperationQueue.mainQueue
                    usingBlock: ^(NSNotification* notification)
                {
                    NSDictionary* userInfo = notification.userInfo;
                    NSString* messageText = userInfo[kMessageText];
                    
                    [BPNotificationHelper sendNotificationWithMessage: messageText];
                }];
                
                // Tell the Controller that SpringBoard was restarted so it can re-send
                // the connection notification
                [NSDistributedNotificationCenter.defaultCenter
                    postNotificationName: kNotificationSpringBoardRestarted
                    object: nil
                    userInfo: nil
                ];
            }
        ];
    }
%end