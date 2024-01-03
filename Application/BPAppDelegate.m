#import "BPAppDelegate.h"
#import "BPOverviewViewController.h"
#import "BPLogsViewController.h"

@implementation BPAppDelegate
    - (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
        _window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
        
        BPOverviewViewController* overviewViewController = [BPOverviewViewController new];
        BPLogsViewController* logsViewController = [BPLogsViewController new];
        
        // The titles will be shown in the navigation bar and tab bar,
        // the images will be shown in the tab bar
        
        overviewViewController.title = @"Overview";
        logsViewController.title = @"Logs";
        
        overviewViewController.tabBarItem = [[UITabBarItem alloc]
            initWithTitle: @"Overview"
            image: [UIImage imageNamed: @"icon-overview-1"]
            tag: 0
        ];
        
        logsViewController.tabBarItem = [[UITabBarItem alloc]
            initWithTitle: @"Logs"
            image: [UIImage imageNamed: @"icon-logs-1"]
            tag: 1
        ];
        
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
