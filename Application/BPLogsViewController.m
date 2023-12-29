#import "BPLogsViewController.h"
#import "../Shared/Constants.h"
#import "./Logging.h"

@interface BPLogsViewController ()
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
        
        UIBarButtonItem *clearLogsButtonItem = [[UIBarButtonItem alloc] 
            initWithTitle: @"Clear logs"                                            
            style: UIBarButtonItemStylePlain 
            target: self 
            action: @selector(handleClearLogsButtonPressed)
        ];
        self.navigationItem.rightBarButtonItem = clearLogsButtonItem;
        
        [self readLogsWithCompletion: nil];
    }
    
    // We scroll to the bottom in viewWillAppear and viewDidAppear
    // because in viewWillAppear it doesn't quite manage to scroll
    // to the bottom but scrolling from the top to the bottom
    // while the user is watching could be a long distance and be ugly
    
    - (void) viewWillAppear:(BOOL)animated {
        [super viewWillAppear: animated];
        
        if (logLines.count > 0) {
            [self.tableView
                scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: logLines.count - 1 inSection: 0]
                atScrollPosition: UITableViewScrollPositionBottom
                animated: false
            ];
        }
    }
    
    - (void) viewDidAppear:(BOOL)animated {
        [super viewDidAppear: animated];
        
        if (logLines.count > 0) {
            [self.tableView
                scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: logLines.count - 1 inSection: 0]
                atScrollPosition: UITableViewScrollPositionBottom
                animated: true
            ];
        }
        
        [NSTimer
            scheduledTimerWithTimeInterval: 2
            repeats: true
            block: ^(NSTimer *timer) {
                [self readLogsWithCompletion: ^(BOOL hasNewLogs) {
                    if (hasNewLogs && logLines.count > 0) {
                        [self.tableView
                            scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: logLines.count - 1 inSection: 0]
                            atScrollPosition: UITableViewScrollPositionBottom
                            animated: true
                        ];
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
    
    - (NSInteger) tableView:(UITableView*)tableView  numberOfRowsInSection:(NSInteger)section {
        return logLines.count;
    }
    
    - (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
        return 1;
    }
    
    - (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"BPLogLineCell"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"BPLogLineCell"];
        }
        
        // Allow the label to increase to multiple lines
        cell.textLabel.numberOfLines = 0;
        
        cell.textLabel.font = [UIFont systemFontOfSize: 14];
        cell.textLabel.text = logLines[indexPath.row];
        
        return cell;
    }
    
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
@end