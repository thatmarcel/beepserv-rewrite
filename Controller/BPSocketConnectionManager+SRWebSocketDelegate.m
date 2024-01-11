#import "BPSocketConnectionManager.h"
#import "../Shared/Constants.h"
#import "./Logging.h"

// We put the methods for the SRWebSocketDelegate in a separate file for better organization

@implementation BPSocketConnectionManager (SRWebSocketDelegate)
    - (void) webSocketDidOpen:(SRWebSocket*)webSocket {
        [self sendBeginMessage];
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error {
        [self handleConnectionError: error];
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didReceiveMessageWithString:(NSString*)message {
        if (!message) {
            return;
        }
        
        // Don't log ping response (pong) messages
        if (![message containsString: @"\"pong\""]) {
            LOG(@"Received string message: %@", message);
        }
        
        NSData* messageData = [message dataUsingEncoding: NSUTF8StringEncoding];
        
        NSError* jsonDecodingError;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData: messageData options: 0 error: &jsonDecodingError];
        
        if (jsonDecodingError) {
            LOG(@"Couldn't parse text message as JSON: %@", jsonDecodingError);
            return;
        }
        
        [self handleReceivedMessageWithContents: jsonContents];
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didReceiveMessageWithData:(NSData*)data {
        LOG(@"Ignoring received data message");
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didCloseWithCode:(NSInteger)code reason:(NSString*)reason wasClean:(BOOL)wasClean {
        // Ignore intended disconnects (e.g. when requesting a new registration code)
        if (wasClean) {
            return;
        }
        
        [self handleConnectionError: [NSError errorWithDomain: kSuiteName code: code userInfo: @{
            @"Error Reason": [NSString stringWithFormat: @"Socket closed with reason: %@", reason]
        }]];
    }
@end