#import "./Constants.h"
#import "../Shared/NSDistributedNotificationCenter.h"

NSRegularExpression *bp_relay_secret_replacement_regex;
NSRegularExpression *bp_relay_code_replacement_regex;
NSRegularExpression *bp_udid_replacement_regex;
NSRegularExpression *bp_serial_number_replacement_regex;
NSRegularExpression *bp_validation_data_replacement_regex;

bool bp_has_initialized_log_replacement_regexes = false;

void bp_initialize_log_replacement_regexes() {
    bp_relay_secret_replacement_regex = [NSRegularExpression
        regularExpressionWithPattern: @"\"secret\":\"([^\"]*)\""
        options: 0
        error: nil
    ];
    
    bp_relay_code_replacement_regex = [NSRegularExpression
        regularExpressionWithPattern: @"\"code\":\"([^\"]*)-([^\"]*)-([^\"]*)-([^\"]*)\""
        options: 0
        error: nil
    ];
    
    bp_udid_replacement_regex = [NSRegularExpression
        regularExpressionWithPattern: @"\"unique_device_id\":\"([^\"]*)\""
        options: 0
        error: nil
    ];
    
    bp_serial_number_replacement_regex = [NSRegularExpression
        regularExpressionWithPattern: @"\"serial_number\":\"([^\"]*)\""
        options: 0
        error: nil
    ];
    
    bp_validation_data_replacement_regex = [NSRegularExpression
        regularExpressionWithPattern: @"(\"command\":\"response\")(.*)(\"data\":\")(.{10})([^\"]*)\""
        options: 0
        error: nil
    ];
    
    bp_has_initialized_log_replacement_regexes = true;
}

NSString* bp_replace_secrets_in_log_string(NSString* logString) {
    NSString* resultString = [logString copy];
    
    if (!bp_has_initialized_log_replacement_regexes) {
        bp_initialize_log_replacement_regexes();
    }
    
    if (bp_relay_secret_replacement_regex) {
        resultString = [bp_relay_secret_replacement_regex
            stringByReplacingMatchesInString: resultString
            options: 0
            range: NSMakeRange(0, [resultString length])
            withTemplate: @"\"secret\":\"(redacted)\""
        ];
    }
    
    if (bp_relay_code_replacement_regex) {
        resultString = [bp_relay_code_replacement_regex
            stringByReplacingMatchesInString: resultString
            options: 0
            range: NSMakeRange(0, [resultString length])
            withTemplate: @"\"code\":\"$1-(redacted)\""
        ];
    }
    
    if (bp_udid_replacement_regex) {
        resultString = [bp_udid_replacement_regex
            stringByReplacingMatchesInString: resultString
            options: 0
            range: NSMakeRange(0, [resultString length])
            withTemplate: @"\"unique_device_id\":\"(redacted)\""
        ];
    }
    
    if (bp_serial_number_replacement_regex) {
        resultString = [bp_serial_number_replacement_regex
            stringByReplacingMatchesInString: resultString
            options: 0
            range: NSMakeRange(0, [resultString length])
            withTemplate: @"\"serial_number\":\"(redacted)\""
        ];
    }
    
    if (bp_validation_data_replacement_regex) {
        resultString = [bp_validation_data_replacement_regex
            stringByReplacingMatchesInString: resultString
            options: 0
            range: NSMakeRange(0, [resultString length])
            withTemplate: @"$1$2$3$4... (redacted)\""
        ];
    }
    
    return resultString;
}

// This method is called by the module-specific Logging.h LOG macros with the name of the module
// so we can easily see which module is logging without having to duplicate this code

// On rootful devices, identityservicesd seems to not be allowed
// to write to the log file so we send the log entry to the
// Controller which then writes it to the log file
//
// shouldSendLogsFromIdentityServicesIfNeeded is false if it has been called by
// the Controller when relaying a message from IdentityServices
void bp_log_impl_internal(NSString* moduleName, NSString* logString, bool shouldSendLogsFromIdentityServicesIfNeeded) {
    if (shouldSendLogsFromIdentityServicesIfNeeded) {
        NSLog(@"[Beepserv] %@: %@", moduleName, logString);
    }
    
    if (![@"/var/jb" isEqualToString: @THEOS_PACKAGE_INSTALL_PREFIX] && shouldSendLogsFromIdentityServicesIfNeeded && [moduleName isEqualToString: kModuleNameIdentityServices]) {
        [NSDistributedNotificationCenter.defaultCenter
            postNotificationName: kNotificationLogEntryFromIdentityServices
            object: nil
            userInfo: @{ kMessageText: logString }
        ];
        return;
    }
    
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    if (![fileManager fileExistsAtPath: LOG_FILE_PATH]) {
        [fileManager createFileAtPath: LOG_FILE_PATH contents: nil attributes: nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate: [NSDate date]];
    
    logString = bp_replace_secrets_in_log_string(logString);
    
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath: LOG_FILE_PATH];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData: [[NSString stringWithFormat: @"%@: [%@] %@\n", dateString, moduleName, [logString stringByReplacingOccurrencesOfString: @"\n" withString: @" "]] dataUsingEncoding: NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

void bp_log_impl(NSString* moduleName, NSString* logString) {
    bp_log_impl_internal(moduleName, logString, true);
}