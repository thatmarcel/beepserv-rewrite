#import "./Constants.h"

void bp_log_impl(NSString* moduleName, NSString* logString) {
    NSLog(@"[Beepserv] %@: %@", moduleName, logString);
    
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    if (![fileManager fileExistsAtPath: kLogFilePath]) {
        [fileManager createFileAtPath: kLogFilePath contents: nil attributes: nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath: kLogFilePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData: [[NSString stringWithFormat: @"[%@] %@\n", moduleName, [logString stringByReplacingOccurrencesOfString: @"\n" withString: @" "]] dataUsingEncoding: NSUTF8StringEncoding]];
    [fileHandle closeFile];
}