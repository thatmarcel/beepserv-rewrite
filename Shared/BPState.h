#import <Foundation/Foundation.h>

@interface BPState: NSObject
    @property (retain) NSString* code;
    @property (retain) NSString* secret;
    @property bool isConnected;
    // We currently don't store the error because it is visible
    // via the logs in the app, or, depending on the error, might be shown via notification (bulletin)
    
    // Restores the state from the state file or creates a new, empty state
    + (instancetype) restoreOrCreate;
    // Restores the state from a serialized dictionary
    + (instancetype) createFromDictionary:(NSDictionary*)dictionary;
    
    // Calling one of these update methods also broadcasts and writes the updated state to disk
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret connected:(BOOL)isConnectedNow;
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret;
    - (void) updateConnected:(BOOL)isConnectedNow;
    
    // Serializes the state to a dictionary to be broadcasted or written to disk
    - (NSDictionary*) serializeToDictionary;
    - (void) writeToDisk;
    - (void) broadcast;
@end