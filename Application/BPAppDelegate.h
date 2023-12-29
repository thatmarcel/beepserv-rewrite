#import <UIKit/UIKit.h>

@interface BPAppDelegate: UIResponder <UIApplicationDelegate>{
    UITabBarController* _tabBarViewController;
    UINavigationController* _overviewNavigationViewController;
    UINavigationController* _logsNavigationViewController;
}
    @property (nonatomic, strong) UIWindow *window;
@end
