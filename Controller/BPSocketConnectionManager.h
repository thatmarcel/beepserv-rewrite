#import <Foundation/Foundation.h>
#import "SRWebSocket.h"
#import "../Shared/BPState.h"

@interface BPSocketConnectionManager: NSObject <SRWebSocketDelegate>
    @property (retain) SRWebSocket* socket;
    @property (retain) BPState* currentState;
    // Stores the id sent by the relay when it requested validation data,
    // so we can send it to the relay once we have the data
    @property (retain) NSNumber* validationDataRequestIdentifier;
    // The timestamp of the last time we sent identifiers to the relay,
    // used to make sure we don't spam notifications if identifiers
    // are requested multiple times in a row
    @property double lastIdentifiersSendTimestamp;
    // Stores whether we were connected before so we don't
    // send a new notification if we just reconnected
    @property bool wasConnectedBefore;
    // This is stored to make sure we don't spam the log file when
    // e.g. the device isn't connected to the internet
    @property int failedConnectionAttemptCountInARow;
    
    + (instancetype) sharedInstance;
    
    - (void) startConnection;
    - (void) handleConnectionError:(NSError*)error;
    - (void) handleReceivedMessageWithContents:(NSDictionary*)jsonContents;
    - (void) handleSuccessfulRelayRegistrationWithCode:(NSString*)code secret:(NSString*)secret;
    
    - (void) sendDictionary:(NSDictionary*)dictionary;
    - (void) sendMessageWithCommand:(NSString*)command;
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data;
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data id:(NSNumber*)requestIdentifier;
    
    - (void) sendBeginMessage;
    - (void) sendPongMessage;
    - (void) sendIdentifiersMessageForId:(NSNumber*)requestIdentifier;
    - (void) sendValidationData:(NSData*)validationData error:(NSError*)error;
@end