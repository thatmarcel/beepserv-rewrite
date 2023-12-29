#import "BPNotificationHelper.h"
#import "./Logging.h"
#import "../Shared/BPPrefs.h"

#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBBulletin.h>
#import <BulletinBoard/BBServer.h>

@interface BBBulletinUpdate: NSObject
@end

@interface BBBulletinModifyUpdate: BBBulletinUpdate
    + (id) updateWithBulletin:(id)arg1 feeds:(unsigned long long)feeds;
@end

@interface BBBulletinAddUpdate: BBBulletinUpdate
    + (id) updateWithBulletin:(id)arg1 feeds:(unsigned long long)feeds shouldPlayLightsAndSirens:(bool)shouldPlayLightsAndSirens;
@end

@interface BBBulletinRemoveUpdate: BBBulletinUpdate
    + (id) updateWithBulletin:(id)arg1 feeds:(unsigned long long)feeds shouldSync:(bool)shouldSync;
@end

@interface BBServer (beepserv)
    - (void) publishBulletin:(BBBulletin*)bulletin destinations:(unsigned long long)destinations;
    - (void) _sendBulletinUpdate:(id)arg1;
@end

@interface BBBulletin (beepserv)
    @property (nonatomic) bool clearable;
    
    - (void)setWantsFullscreenPresentation:(BOOL)loading;
@end

static BBServer* notificationServer = nil;
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
            LOG(@"Not sending notification because BBServer does not respond to selectors");
            return;
        }
        
        // We normally cannot send a notification as com.beeper.beepserv.app
        // because we don't have notifications permission but
        // the following hack works:
        // 1. Send the notification as coming from the Settings app
        // 2. Send an update notification with the updated section identifier
        // 3. Send an update that deletes the original notification
        // Note that this only changes the notification that is displayed on the
        // lock screen because idk how to make the original notification not pop up
        // and also if the updated notification is set to pop up it doesn't
        // automatically hide itself after a few seconds
        // => this is not ideal
        
        BBBulletin* bulletin = [[%c(BBBulletin) alloc] init];
        
        // The bulletin id has to stay the same in the original
        // and updated notification
        bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
        bulletin.date = [NSDate date];
        bulletin.lastInterruptDate = [NSDate date];
        bulletin.turnsOnDisplay = false;
        
        bulletin.title = @"beepserv";
        bulletin.message = message;
        bulletin.sectionID = @"com.apple.Preferences";
        
        // We don't add an action to the notification because
        // the notification does not get automatically get deleted on tap
        // bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID: @"com.beeper.beepserv.app" callblock: nil];
        
        if ([bulletin respondsToSelector: @selector(setClearable:)]) {
            [bulletin setClearable: true];
        }
        
        LOG(@"Dispatching in notification server queue");
        dispatch_sync(notificationServerQueue, ^{
            LOG(@"Publishing notification");
            [notificationServer publishBulletin: bulletin destinations: 14];
            
            if (![notificationServer respondsToSelector: @selector(_sendBulletinUpdate:)]) {
                LOG(@"Not updating notification because BBServer does not respond to selector");
                return;
            }
            
            BBBulletin* modifiedBulletin = [bulletin copy];
            modifiedBulletin.sectionID = @"com.beeper.beepserv.app";
            modifiedBulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
            modifiedBulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
            
            [notificationServer _sendBulletinUpdate: [%c(BBBulletinAddUpdate) updateWithBulletin: modifiedBulletin feeds: 14 shouldPlayLightsAndSirens: false]];
            
            [notificationServer _sendBulletinUpdate: [%c(BBBulletinRemoveUpdate) updateWithBulletin: bulletin feeds: 14 shouldSync: true]];
        });
    }
@end