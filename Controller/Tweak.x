#import "BPSocketConnectionManager.h"
#import "./Logging.h"
#import <rootless.h>

%hook SpringBoard
    - (void) applicationDidFinishLaunching:(id)arg1 {
        %orig;
        
        LOG(@"SpringBoard launched");
        
        [NSTimer
            scheduledTimerWithTimeInterval: 5
            repeats: false
            block: ^(NSTimer* timer) {
                [BPSocketConnectionManager.sharedInstance startConnection];
            }
        ];
    }
%end