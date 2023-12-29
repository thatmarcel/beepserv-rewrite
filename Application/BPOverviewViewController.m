#import "BPOverviewViewController.h"
#import "../Shared/BPState.h"
#import "../Shared/BPPrefs.h"
#import "../Shared/Constants.h"
#import "../Shared/NSDistributedNotificationCenter.h"

@interface BPOverviewViewController ()
    @property (retain) UIView* connectionDetailsContainer;
    @property (retain) UILabel* codeLabel;
    @property (retain) UILabel* aboveCodeLabel;
    @property (retain) UILabel* belowCodeLabel;
    @property (retain) UILabel* noConnectionLabel;
    @property (retain) UIActivityIndicatorView* activityIndicatorView;
    @property (retain) UIView* notificationPrefsContainer;
    @property (retain) UILabel* notificationsSwitchLabel;
    @property (retain) UISwitch* notificationsSwitch;
@end

@implementation BPOverviewViewController
    @synthesize connectionDetailsContainer;
    @synthesize codeLabel;
    @synthesize aboveCodeLabel;
    @synthesize belowCodeLabel;
    @synthesize noConnectionLabel;
    @synthesize activityIndicatorView;
    @synthesize notificationPrefsContainer;
    @synthesize notificationsSwitchLabel;
    @synthesize notificationsSwitch;
    
    - (void) viewDidLoad {
        [super viewDidLoad];
        
        if (@available(iOS 13, *)) {
            self.view.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
        
        [self addViews];
        [self addStateUpdateListener];
        [self requestStateUpdate];
    }
    
    - (void) addViews {
        [self addConnectionDetailsContainer];
        [self addNoConnectionLabel];
        [self addActivityIndicatorView];
        [self addNotificationPrefsContainer];
    }
    
    - (void) addConnectionDetailsContainer {
        connectionDetailsContainer = [[UIView alloc] init];
        connectionDetailsContainer.translatesAutoresizingMaskIntoConstraints = false;
        
        [self.view addSubview: connectionDetailsContainer];
        
        if (@available(iOS 11, *)) {
            [connectionDetailsContainer.centerYAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.centerYAnchor].active = true;
            [connectionDetailsContainer.leftAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.leftAnchor constant: 32].active = true;
            [connectionDetailsContainer.rightAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.rightAnchor constant: -32].active = true;
        } else {
            [connectionDetailsContainer.centerYAnchor constraintEqualToAnchor: self.view.centerYAnchor].active = true;
            [connectionDetailsContainer.leftAnchor constraintEqualToAnchor: self.view.leftAnchor constant: 32].active = true;
            [connectionDetailsContainer.rightAnchor constraintEqualToAnchor: self.view.rightAnchor constant: -32].active = true;
        }
        
        aboveCodeLabel = [[UILabel alloc] init];
        aboveCodeLabel.translatesAutoresizingMaskIntoConstraints = false;
        aboveCodeLabel.textAlignment = NSTextAlignmentCenter;
        aboveCodeLabel.font = [UIFont systemFontOfSize: 17];
        aboveCodeLabel.text = @"Enter the registration code";
        
        [connectionDetailsContainer addSubview: aboveCodeLabel];
        
        [aboveCodeLabel.topAnchor constraintEqualToAnchor: connectionDetailsContainer.topAnchor].active = true;
        [aboveCodeLabel.leftAnchor constraintEqualToAnchor: connectionDetailsContainer.leftAnchor].active = true;
        [aboveCodeLabel.rightAnchor constraintEqualToAnchor: connectionDetailsContainer.rightAnchor].active = true;
        
        codeLabel = [[UILabel alloc] init];
        codeLabel.numberOfLines = 4;
        codeLabel.translatesAutoresizingMaskIntoConstraints = false;
        codeLabel.textAlignment = NSTextAlignmentCenter;
        codeLabel.font = [UIFont boldSystemFontOfSize: 38];
        codeLabel.text = @"AAAA\nBBBB\nCCCC\nDDDD";
        
        [connectionDetailsContainer addSubview: codeLabel];
        
        [codeLabel.topAnchor constraintEqualToAnchor: aboveCodeLabel.bottomAnchor constant: 10].active = true;
        [codeLabel.leftAnchor constraintEqualToAnchor: connectionDetailsContainer.leftAnchor].active = true;
        [codeLabel.rightAnchor constraintEqualToAnchor: connectionDetailsContainer.rightAnchor].active = true;
        
        belowCodeLabel = [[UILabel alloc] init];
        belowCodeLabel.translatesAutoresizingMaskIntoConstraints = false;
        belowCodeLabel.textAlignment = NSTextAlignmentCenter;
        belowCodeLabel.font = [UIFont systemFontOfSize: 17];
        belowCodeLabel.text = @"to use this device";
        
        [connectionDetailsContainer addSubview: belowCodeLabel];
        
        [belowCodeLabel.topAnchor constraintEqualToAnchor: codeLabel.bottomAnchor constant: 10].active = true;
        [belowCodeLabel.bottomAnchor constraintEqualToAnchor: connectionDetailsContainer.bottomAnchor].active = true;
        [belowCodeLabel.leftAnchor constraintEqualToAnchor: connectionDetailsContainer.leftAnchor].active = true;
        [belowCodeLabel.rightAnchor constraintEqualToAnchor: connectionDetailsContainer.rightAnchor].active = true;
        
        connectionDetailsContainer.hidden = true;
    }
    
    - (void) addNoConnectionLabel {
        noConnectionLabel = [[UILabel alloc] init];
        noConnectionLabel.numberOfLines = 2;
        noConnectionLabel.translatesAutoresizingMaskIntoConstraints = false;
        noConnectionLabel.textAlignment = NSTextAlignmentCenter;
        noConnectionLabel.font = [UIFont boldSystemFontOfSize: 24];
        noConnectionLabel.textColor = [UIColor redColor];
        noConnectionLabel.text = @"Not connected\nto registration relay";
        
        [self.view addSubview: noConnectionLabel];
        
        if (@available(iOS 11, *)) {
            [noConnectionLabel.centerYAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.centerYAnchor].active = true;
        } else {
            [noConnectionLabel.centerYAnchor constraintEqualToAnchor: self.view.centerYAnchor].active = true;
        }
        
        [noConnectionLabel.leftAnchor constraintEqualToAnchor: self.view.leftAnchor constant: 32].active = true;
        [noConnectionLabel.rightAnchor constraintEqualToAnchor: self.view.rightAnchor constant: -32].active = true;
        
        noConnectionLabel.hidden = true;
    }
    
    - (void) addActivityIndicatorView {
        activityIndicatorView = [[UIActivityIndicatorView alloc] init];
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false;
        activityIndicatorView.hidesWhenStopped = true;
        activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
        
        [self.view addSubview: activityIndicatorView];
        
        [activityIndicatorView.centerXAnchor constraintEqualToAnchor: self.view.centerXAnchor].active = true;
        [activityIndicatorView.centerYAnchor constraintEqualToAnchor: self.view.centerYAnchor].active = true;
        
        [activityIndicatorView startAnimating];
    }
    
    - (void) addNotificationPrefsContainer {
        notificationPrefsContainer = [[UIView alloc] init];
        notificationPrefsContainer.translatesAutoresizingMaskIntoConstraints = false;
        
        [self.view addSubview: notificationPrefsContainer];
        
        if (@available(iOS 11, *)) {
            [notificationPrefsContainer.bottomAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.bottomAnchor constant: -32].active = true;
            [notificationPrefsContainer.centerXAnchor constraintEqualToAnchor: self.view.safeAreaLayoutGuide.centerXAnchor].active = true;
        } else {
            [notificationPrefsContainer.bottomAnchor constraintEqualToAnchor: self.view.bottomAnchor constant: -32].active = true;
            [notificationPrefsContainer.centerXAnchor constraintEqualToAnchor: self.view.centerXAnchor].active = true;
        }
        
        notificationsSwitchLabel = [[UILabel alloc] init];
        notificationsSwitchLabel.translatesAutoresizingMaskIntoConstraints = false;
        notificationsSwitchLabel.textAlignment = NSTextAlignmentCenter;
        notificationsSwitchLabel.font = [UIFont systemFontOfSize: 17];
        notificationsSwitchLabel.text = @"Local state notifications";
        
        [notificationPrefsContainer addSubview: notificationsSwitchLabel];
        
        [notificationsSwitchLabel.leftAnchor constraintEqualToAnchor: notificationPrefsContainer.leftAnchor].active = true;
        [notificationsSwitchLabel.topAnchor constraintEqualToAnchor: notificationPrefsContainer.topAnchor].active = true;
        [notificationsSwitchLabel.bottomAnchor constraintEqualToAnchor: notificationPrefsContainer.bottomAnchor].active = true;
        
        notificationsSwitch = [[UISwitch alloc] init];
        notificationsSwitch.translatesAutoresizingMaskIntoConstraints = false;
        
        [notificationPrefsContainer addSubview: notificationsSwitch];
        
        [notificationsSwitch.leftAnchor constraintEqualToAnchor: notificationsSwitchLabel.rightAnchor constant: 16].active = true;
        [notificationsSwitch.rightAnchor constraintEqualToAnchor: notificationPrefsContainer.rightAnchor].active = true;
        [notificationsSwitch.topAnchor constraintEqualToAnchor: notificationPrefsContainer.topAnchor].active = true;
        [notificationsSwitch.bottomAnchor constraintEqualToAnchor: notificationPrefsContainer.bottomAnchor].active = true;
        
        notificationsSwitch.on = [BPPrefs shouldShowNotifications];
        
        [notificationsSwitch addTarget: self action: @selector(handleNotificationsSwitchToggled) forControlEvents: UIControlEventValueChanged];
    }
    
    - (void) handleNotificationsSwitchToggled {
        [BPPrefs setShouldShowNotifications: notificationsSwitch.on];
    }
    
    - (void) addStateUpdateListener {
        [NSDistributedNotificationCenter.defaultCenter
            addObserverForName: kNotificationUpdateState
            object: nil
            queue: NSOperationQueue.mainQueue
            usingBlock: ^(NSNotification *notification)
        {
            BPState* currentState = [BPState createFromDictionary: notification.userInfo];
            [self updateWithState: currentState];
        }];
    }
    
    - (void) requestStateUpdate {
        [[NSDistributedNotificationCenter defaultCenter]
            postNotificationName: kNotificationRequestStateUpdate
            object: nil
            userInfo: nil
        ];
    }
    
    - (void) updateWithState:(BPState*)state {
        [activityIndicatorView stopAnimating];
        
        if (state.isConnected) {
            codeLabel.text = [state.code stringByReplacingOccurrencesOfString: @"-" withString: @"\n"];
            
            noConnectionLabel.hidden = true;
            connectionDetailsContainer.hidden = false;
        } else {
            noConnectionLabel.hidden = false;
            connectionDetailsContainer.hidden = true;
        }
    }
@end
