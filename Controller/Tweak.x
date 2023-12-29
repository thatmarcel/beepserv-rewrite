#import "BPSocketConnectionManager.h"
#import "./Logging.h"
#import <rootless.h>

%hook SpringBoard
    - (void) applicationDidFinishLaunching:(id)arg1 {
        %orig;
        
        LOG(@"SpringBoard launched");
        
        // We wait a bit to make sure SpringBoard has fully initialized
        // before trying to connect to the registration relay
        [NSTimer
            scheduledTimerWithTimeInterval: 5
            repeats: false
            block: ^(NSTimer* timer) {
                [BPSocketConnectionManager.sharedInstance startConnection];
            }
        ];
    }
%end