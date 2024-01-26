#import <Foundation/Foundation.h>
#import <stdio.h>
#import "./Logging.h"
#import "BPSocketConnectionManager.h"
#import "../Shared/NSDistributedNotificationCenter.h"

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		// When IdentityServices tries to log something
		// on a device with a rootful jailbreak,
		// we have to do it because it does not always have
		// permission to write to the file
		if (![@"/var/jb" isEqualToString: @THEOS_PACKAGE_INSTALL_PREFIX]) {
			[NSDistributedNotificationCenter.defaultCenter
				addObserverForName: kNotificationLogEntryFromIdentityServices
				object: nil
				queue: NSOperationQueue.mainQueue
				usingBlock: ^(NSNotification* notification)
			{
				NSDictionary* userInfo = notification.userInfo;
				NSString* logString = userInfo[kMessageText];
				bp_log_impl_internal(kModuleNameIdentityServices, logString, false);
			}];
		}
		
		[BPSocketConnectionManager.sharedInstance startConnection];
		
		// Keeps the process running
		[[NSRunLoop currentRunLoop] run];
		
		return 0;
	}
}
