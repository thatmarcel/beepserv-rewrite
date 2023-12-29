#import "BPNotificationHelper.h"
#import "./Logging.h"
#import "../Shared/BPPrefs.h"

#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBBulletin.h>
#import <BulletinBoard/BBServer.h>

@interface BBServer (beepserv)
    - (void) publishBulletin:(BBBulletin*)bulletin destinations:(unsigned long long)destinations;
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
        if (![BPPrefs shouldShowNotifications]) {
            return;
        }
        
        if (!notificationServer) {
            LOG(@"Not sending notification because BBServer is not set");
            return;
        }
        
        if (![notificationServer respondsToSelector: @selector(publishBulletin:destinations:)]) {
            LOG(@"Not sending notification because BBServer does not respond to selector");
            return;
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
        
        LOG(@"Dispatching in notification server queue");
        dispatch_sync(notificationServerQueue, ^{
            LOG(@"Publishing notification");
            [notificationServer publishBulletin: bulletin destinations: 14];
        });
    }
@end