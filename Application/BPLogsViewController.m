#import "BPLogsViewController.h"
#import "../Shared/Constants.h"
#import "./Logging.h"

@interface BPLogsViewController ()
    // We store the last log file content so we only need to
    // parse it again and scroll to the bottom if it has changed 
    @property (retain) NSString* lastLogFileContent;
    @property (retain) NSArray<NSString*>* logLines;
@end

@implementation BPLogsViewController
    @synthesize lastLogFileContent;
    @synthesize logLines;
    
    - (void) viewDidLoad {
        [super viewDidLoad];
        
        if (@available(iOS 13, *)) {
            self.view.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
        
        UIBarButtonItem* clearLogsButtonItem = [[UIBarButtonItem alloc] 
            initWithTitle: @"Clear logs"                                            
            style: UIBarButtonItemStylePlain 
            target: self 
            action: @selector(handleClearLogsButtonPressed)
        ];
        self.navigationItem.rightBarButtonItem = clearLogsButtonItem;
        
        UIBarButtonItem* shareButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem: UIBarButtonSystemItemAction
            target: self
            action: @selector(handleShareButtonPressed)
        ];  
        self.navigationItem.leftBarButtonItem = shareButtonItem;  
        
        [self readLogsWithCompletion: nil];
    }
    
    // We scroll to the bottom in viewWillAppear and viewDidAppear
    // because in viewWillAppear it sometimes doesn't quite manage to scroll
    // to the bottom but scrolling from the top to the bottom
    // while the user is watching could be a long distance and be ugly
    
    - (void) viewWillAppear:(BOOL)animated {
        [super viewWillAppear: animated];
        
        [self scrollToBottomAnimated: false];
    }
    
    - (void) viewDidAppear:(BOOL)animated {
        [super viewDidAppear: animated];
        
        [self scrollToBottomAnimated: true];
        
        [NSTimer
            scheduledTimerWithTimeInterval: 2
            repeats: true
            block: ^(NSTimer* timer) {
                [self readLogsWithCompletion: ^(BOOL hasNewLogs) {
                    if (hasNewLogs) {
                        [self scrollToBottomAnimated: true];
                    }
                }];
            }
        ];
    }
    
    // Completion callback passes whether there are new logs so the table view
    // only scrolls to the bottom if there are
    - (void) readLogsWithCompletion:(void (^)(BOOL))completion {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString* logFileContent = [[NSString
                stringWithContentsOfFile: kLogFilePath encoding: NSUTF8StringEncoding error: nil] 
                stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]
            ];
            
            if ([logFileContent isEqual: lastLogFileContent]) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (completion) {
                        completion(false);
                    }
                });
                return;
            }
            
            lastLogFileContent = logFileContent;
            
            logLines = [logFileContent componentsSeparatedByString: @"\n"];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.tableView reloadData];
                
                if (completion) {
                    completion(true);
                }
            });
        });
    }
    
    - (void) scrollToBottomAnimated:(BOOL)animated {
        int rowCount = [self.tableView numberOfRowsInSection: 0];
        
        if (rowCount > 0) {
            [self.tableView
                scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: rowCount - 1 inSection: 0]
                atScrollPosition: UITableViewScrollPositionBottom
                animated: animated
            ];
        }
    }
    
    - (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
        return logLines.count;
    }
    
    - (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
        return 1;
    }
    
    - (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"BPLogLineCell"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"BPLogLineCell"];
        }
        
        // Allow the label to wrap to multiple lines
        cell.textLabel.numberOfLines = 0;
        
        cell.textLabel.font = [UIFont systemFontOfSize: 14];
        
        cell.textLabel.text = logLines[indexPath.row];
        
        return cell;
    }
    
    // Tapping a row copies its content to the clipboard
    - (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
        [tableView deselectRowAtIndexPath: indexPath animated: true];
        
        UIPasteboard.generalPasteboard.string = logLines[indexPath.row];
    }
    
    - (void) handleClearLogsButtonPressed {
        NSError* fileDeletionError;
        [NSFileManager.defaultManager removeItemAtPath: kLogFilePath error: &fileDeletionError];
        
        if (fileDeletionError) {
            LOG(@"Deleting log file failed");
        } else {
            LOG(@"Logs cleared");
        }
    }
    
    - (void) handleShareButtonPressed {
        UIActivityViewController* activityViewController = [[UIActivityViewController alloc]
            initWithActivityItems: @[[NSURL fileURLWithPath: kLogFilePath]]
            applicationActivities: nil
        ];
        
        activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
        
        // This currently crashes on an iPad on 14.5 jailbroken with unc0ver. Setting sourceView and sourceRect
        // fixes this crash but the share sheet is not visible, no matter what the sourceRect is.
        // It seems to work on other devices though, so until the cause of the crash has been determined, this is fine.
        
        [self presentViewController: activityViewController animated: true completion: nil];
    }
@end