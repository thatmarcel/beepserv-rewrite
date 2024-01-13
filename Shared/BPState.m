#import "./BPState.h"
#import "./Constants.h"
#import "./NSDistributedNotificationCenter.h"

#import <rootless.h>

// Because this file is shared between modules, we cannot use the
// module-specific logging files
#import "./Constants.h"
#define LOG(...) bp_log_impl(@"Shared", [NSString stringWithFormat: __VA_ARGS__])
void bp_log_impl(NSString* moduleName, NSString* logString);

static NSString* stateFilePath = ROOT_PATH_NS(@"/var/mobile/.beepserv_state");
static NSString* alternativeStateFilePath = ROOT_PATH_NS(@"/var/mobile/Library/.beepserv_state");

static const NSString* kSerializationKeyCode = @"com.beepserv.code";
static const NSString* kSerializationKeySecret = @"com.beepserv.secret";
static const NSString* kSerializationKeyConnected = @"com.beepserv.connected";

@implementation BPState
    @synthesize code;
    @synthesize secret;
    @synthesize isConnected;
    
    + (instancetype) restoreOrCreate {
        LOG(@"Trying to restore state");
        
        // As SpringBoard should have r/w permissions for the normal file path on all setups,
        // the alternative file is not needed anymore, so we'll delete it
        if ([NSFileManager.defaultManager fileExistsAtPath: alternativeStateFilePath isDirectory: nil]) {
            LOG(@"Found alternative state file");
            
            NSError* fileReadingError;
            NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", alternativeStateFilePath]];
            
            NSDictionary* serializedState;
            
            if (@available(iOS 11, *)) {
                serializedState = [NSDictionary dictionaryWithContentsOfURL: url error: &fileReadingError];
            } else {
                serializedState = [NSDictionary dictionaryWithContentsOfURL: url];
            }
            
            if (fileReadingError || !serializedState) {
                LOG(@"Reading alternative state file failed with error: %@", fileReadingError);
            } else {
                NSError* fileDeletionError;
                [NSFileManager.defaultManager removeItemAtPath: alternativeStateFilePath error: &fileDeletionError];
                
                if (fileDeletionError) {
                    LOG(@"Deleting alternative state file failed with error: %@", fileReadingError);
                }
                
                return [BPState createFromDictionary: serializedState];
            }
        }
        
        if ([NSFileManager.defaultManager fileExistsAtPath: stateFilePath isDirectory: nil]) {
            LOG(@"Found state file");
            
            NSError* fileReadingError;
            NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", stateFilePath]];
            
            NSDictionary* serializedState;
            
            if (@available(iOS 11, *)) {
                serializedState = [NSDictionary dictionaryWithContentsOfURL: url error: &fileReadingError];
            } else {
                serializedState = [NSDictionary dictionaryWithContentsOfURL: url];
            }
            
            if (fileReadingError || !serializedState) {
                LOG(@"Reading state file failed with error: %@", fileReadingError);
            } else {
                return [BPState createFromDictionary: serializedState];
            }
        }
        
        LOG(@"No stored state found, starting with a new state");
        return [[BPState alloc] init];
    }
    
    + (instancetype) createFromDictionary:(NSDictionary*)dictionary {
        BPState* state = [[BPState alloc] init];
        
        state.code = dictionary[kSerializationKeyCode];
        state.secret = dictionary[kSerializationKeySecret];
        state.isConnected = [(NSNumber*) dictionary[kSerializationKeyConnected] boolValue];
        
        return state;
    }
    
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret connected:(BOOL)isConnectedNow {
        self.code = newCode;
        self.secret = newSecret;
        self.isConnected = isConnectedNow;
        
        [self writeToDisk];
        [self broadcast];
    }
    
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret {
        [self updateCode: code secret: secret connected: self.isConnected];
    }
    
    - (void) updateConnected:(BOOL)isConnectedNow {
        self.isConnected = isConnectedNow;
        
        [self writeToDisk];
        [self broadcast];
    }
    
    - (void) writeToDisk {
        NSDictionary* serializedState = [self serializeToDictionary];
        
        NSError* writingError;
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", stateFilePath]];
        
        if (@available(iOS 11, *)) {
            [serializedState writeToURL: url error: &writingError];
        } else {
            if (![serializedState writeToURL: url atomically: true]) {
                writingError = [NSError errorWithDomain: kSuiteName code: 0 userInfo: @{
                    @"Error Reason": @"Unknown"
                }];
            }
        }
        
        if (writingError) {
            LOG(@"Writing state to disk failed with error: %@", writingError);
        }
    }
    
    - (void) broadcast {
        NSDictionary* serializedState = [self serializeToDictionary];
        
        // Broadcasts the new state so the app can update its UI
        [[NSDistributedNotificationCenter defaultCenter]
            postNotificationName: kNotificationUpdateState
            object: nil
            userInfo: serializedState
        ];
    }
    
    - (NSDictionary*) serializeToDictionary {
        NSMutableDictionary* serializedState = [NSMutableDictionary new];
        
        serializedState[kSerializationKeyConnected] = [NSNumber numberWithBool: isConnected];
        
        if (self.code) {
            serializedState[kSerializationKeyCode] = self.code;
        }
        
        if (self.secret) {
            serializedState[kSerializationKeySecret] = self.secret;
        }
            
        return serializedState;
    }
    
    - (void) reset {
        [self updateCode: nil secret: nil connected: false];
    }
@end