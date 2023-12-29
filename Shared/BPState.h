#import <Foundation/Foundation.h>

@interface BPState: NSObject
    @property (retain) NSString* code;
    @property (retain) NSString* secret;
    @property bool isConnected;
    
    + (instancetype) restoreOrCreate;
    + (instancetype) createFromDictionary:(NSDictionary*)dictionary;
    
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret connected:(BOOL)isConnectedNow;
    - (void) updateCode:(NSString*)newCode secret:(NSString*)newSecret;
    - (void) updateConnected:(BOOL)isConnectedNow;
    
    - (NSDictionary*) serializeToDictionary;
    - (void) writeToDisk;
    - (void) broadcast;
@end