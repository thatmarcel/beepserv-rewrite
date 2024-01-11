#import <Foundation/Foundation.h>
#import "SRWebSocket.h"
#import "../Shared/BPState.h"
#import "Headers/PCSimpleTimer.h"

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
    // The timer responsible for retrying the connection after a delay
    @property (retain) PCSimpleTimer* retryTimer;
    // The timer responsible for periodically sending ping messages
    @property (retain) PCSimpleTimer* pingTimer;
    
    + (instancetype) sharedInstance;
    
    // Creates a new socket and tries to connect
    - (void) startConnection;
    
    // When a connection error is received, we log it and try again after a delay
    - (void) handleConnectionError:(NSError*)error;
    
    // Depending on the command in the message, we call one of the other handler functions
    - (void) handleReceivedMessageWithContents:(NSDictionary*)jsonContents;
    
    // When we receive a registration code and secret, we update the state with it
    // and notify the user (via a bulletin) if the code is new
    - (void) handleSuccessfulRelayRegistrationWithCode:(NSString*)code secret:(NSString*)secret;
    
    - (void) sendDictionary:(NSDictionary*)dictionary;
    - (void) sendMessageWithCommand:(NSString*)command;
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data;
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data id:(NSNumber*)requestIdentifier;
    
    - (void) sendBeginMessage;
    - (void) sendPongMessage;
    - (void) sendPingMessage;
    - (void) sendIdentifiersMessageForId:(NSNumber*)requestIdentifier;
    - (void) sendValidationData:(NSData*)validationData error:(NSError*)error;
    
    - (void) showConnectedNotificationWithCode:(NSString*)code;
    
    - (void) handlePingTimerFired;
    - (void) startPingMessageTimer;
@end