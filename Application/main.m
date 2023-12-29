#import <Foundation/Foundation.h>
#import "BPAppDelegate.h"
#import "./Logging.h"

int main(int argc, char* argv[]) {
    @autoreleasepool {
        LOG(@"Started");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(BPAppDelegate.class));
    }
}
