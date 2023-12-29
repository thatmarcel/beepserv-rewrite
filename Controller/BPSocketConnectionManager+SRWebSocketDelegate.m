#import "BPSocketConnectionManager.h"
#import "../Shared/Constants.h"
#import "./Logging.h"

@implementation BPSocketConnectionManager (SRWebSocketDelegate)
    - (void) webSocketDidOpen:(SRWebSocket*)webSocket {
        [self sendBeginMessage];
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error {
        [self handleConnectionError: error];
    }
    
    - (void) webSocket:(SRWebSocket*)webSocket didReceiveMessageWithString:(NSString*)message {
        LOG(@"Received string message: %@", message);
        
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
        NSDictionary* userInfo = @{
            @"Error Reason": [NSString stringWithFormat: @"webSocket closed with reason: %@", reason]
        };
        [self handleConnectionError: [NSError errorWithDomain: kSuiteName code: code userInfo: userInfo]];
    }
@end