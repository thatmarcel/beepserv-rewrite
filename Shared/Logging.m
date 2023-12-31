#import "./Constants.h"

// This method is called by the module-specific Logging.h LOG macros with the name of the module
// so we can easily see which module is logging without having to duplicate this code

void bp_log_impl(NSString* moduleName, NSString* logString) {
    NSLog(@"[Beepserv] %@: %@", moduleName, logString);
    
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    if (![fileManager fileExistsAtPath: kLogFilePath]) {
        [fileManager createFileAtPath: kLogFilePath contents: nil attributes: nil];
    }
    
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath: kLogFilePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData: [[NSString stringWithFormat: @"[%@] %@\n", moduleName, [logString stringByReplacingOccurrencesOfString: @"\n" withString: @" "]] dataUsingEncoding: NSUTF8StringEncoding]];
    [fileHandle closeFile];
}