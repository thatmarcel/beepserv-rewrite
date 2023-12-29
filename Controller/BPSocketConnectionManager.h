#import "SRWebSocket.h"
#import "../Shared/BPState.h"

@interface BPSocketConnectionManager: NSObject <SRWebSocketDelegate>
	@property (retain) SRWebSocket* socket;
	@property (retain) BPState* currentState;
	@property (retain) NSNumber* validationDataRequestIdentifier;
	@property double lastIdentifiersSendTimestamp;
	@property bool wasConnectedBefore;
	
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