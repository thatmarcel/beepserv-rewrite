#import "BPAppDelegate.h"
#import "BPOverviewViewController.h"
#import "BPLogsViewController.h"

@implementation BPAppDelegate
    - (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
        _window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
        
        BPOverviewViewController* overviewViewController = [BPOverviewViewController new];
        BPLogsViewController* logsViewController = [BPLogsViewController new];
        
        // These titles will be shown in the navigation bar and tab bar
        overviewViewController.title = @"Overview";
        logsViewController.title = @"Logs";
        
        _overviewNavigationViewController = [[UINavigationController alloc] initWithRootViewController:
            overviewViewController
        ];
        
        if (@available(iOS 11, *)) {
            _overviewNavigationViewController.navigationBar.prefersLargeTitles = true;
        }
        
        _logsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:
            logsViewController
        ];
        
        if (@available(iOS 11, *)) {
            _logsNavigationViewController.navigationBar.prefersLargeTitles = true;
        }
        
        _tabBarViewController = [UITabBarController new];
        _tabBarViewController.viewControllers = @[
            _overviewNavigationViewController,
            _logsNavigationViewController
        ];
        
        _window.rootViewController = _tabBarViewController;
        
        [_window makeKeyAndVisible];
        
        return true;
    }
    
@end
