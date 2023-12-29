#import "BPSocketConnectionManager.h"
#import "BPDeviceIdentifiers.h"
#import "BPValidationDataManager.h"
#import "BPNotificationHelper.h"
#import "../Shared/Constants.h"
#import "../Shared/NSDistributedNotificationCenter.h"
#import "./Logging.h"
#import <rootless.h>

static BPSocketConnectionManager* _sharedInstance;

@implementation BPSocketConnectionManager
    @synthesize socket;
    @synthesize currentState;
    @synthesize validationDataRequestIdentifier;
    @synthesize lastIdentifiersSendTimestamp;
    @synthesize wasConnectedBefore;
    @synthesize failedConnectionAttemptCountInARow;
    
    + (instancetype) sharedInstance {
        if (!_sharedInstance) {
            _sharedInstance = [[BPSocketConnectionManager alloc] init];
        }
        
        return _sharedInstance;
    }
    
    - (instancetype) init {
        self = [super init];
        
        self.currentState = [BPState restoreOrCreate];
        
        // When the app is opened, it sends a message
        // letting us know that we should broadcast the current state
        [NSDistributedNotificationCenter.defaultCenter
            addObserverForName: kNotificationRequestStateUpdate
            object: nil
            queue: NSOperationQueue.mainQueue
            usingBlock: ^(NSNotification* notification)
        {
            [self.currentState broadcast];
        }];
        
        self.failedConnectionAttemptCountInARow = 0;
        
        return self;
    }
    
    - (void) startConnection {
        if (failedConnectionAttemptCountInARow < 3) {
            LOG(@"Starting connection");
        }
        
        @try {
            NSString* filePath = ROOT_PATH_NS(@"/.beepserv_wsurl");
            NSString* relayURL = [NSString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: nil];
            relayURL = relayURL ?: kDefaultRelayURL;
            relayURL = [relayURL stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString: relayURL]];
            
            socket = [[SRWebSocket alloc] initWithURLRequest: request];
            socket.delegate = self;
            
            [self.socket open];
        } @catch (NSException* exception) {
            NSError* error = [NSError errorWithDomain: exception.name code: 0 userInfo:@{
                NSUnderlyingErrorKey: exception,
                NSDebugDescriptionErrorKey: exception.userInfo ?: @{ },
                NSLocalizedFailureReasonErrorKey: (exception.reason ?: @"Unknown reason")
            }];
            
            [self handleConnectionError: error];
        }
    }
    
    - (void) handleConnectionError:(NSError*)error {
        failedConnectionAttemptCountInARow += 1;
        
        if (failedConnectionAttemptCountInARow <= 3) {
            LOG(@"Socket connection error: %@", error);
            LOG(@"Waiting before trying to re-connect");
            
            if (failedConnectionAttemptCountInARow == 3) {
                LOG(@"Not logging more failed connection attempts until one succeeds");
            }
        }
        
        [currentState updateConnected: false];
        
        // Retry after a delay
        [NSTimer
            scheduledTimerWithTimeInterval: 5
            repeats: false
            block: ^(NSTimer* timer) {
                [self startConnection];
            }
        ];
    }
    
    - (void) handleReceivedMessageWithContents:(NSDictionary*)jsonContents {
        NSString* command = jsonContents[kCommand];
        
        // If there are no switch cases in Objective-C,
        // we just have to make our own
        ((void (^)()) @{
            kCommandPing: ^{
                [self sendPongMessage];
            },
            kCommandGetVersionInfo: ^{
                NSNumber* requestIdentifier = jsonContents[kId];
                
                if (!requestIdentifier) {
                    LOG(@"Version info request missing identifier");
                    return;
                }
                
                [self sendIdentifiersMessageForId: requestIdentifier];
            },
            kCommandGetValidationData: ^{
                NSNumber* requestIdentifier = jsonContents[kId];
                
                if (!requestIdentifier) {
                    LOG(@"Validation data request missing identifier");
                    return;
                }
                
                validationDataRequestIdentifier = requestIdentifier;
                
                NSData* validationData = [BPValidationDataManager.sharedInstance getCachedIfPossible];
                
                if (validationData) {
                    [self sendValidationData: validationData error: nil];
                } else {
                    [BPValidationDataManager.sharedInstance request];
                }
            },
            kCommandResponse: ^{
                NSDictionary* data = jsonContents[kData];
                
                if (!data) {
                    LOG(@"Response missing data");
                    return;
                }
                
                NSString* code = data[kCode];
                NSString* secret = data[kSecret];
                
                if (!code || !secret) {
                    LOG(@"Response missing code or secret");
                    return;
                }
                
                [self handleSuccessfulRelayRegistrationWithCode: code secret: secret];
            }
        }[command] ?: ^{
            LOG(@"Unknown command: %@", command);
        })();
    }
    
    - (void) handleSuccessfulRelayRegistrationWithCode:(NSString*)code secret:(NSString*)secret {
        if (!wasConnectedBefore || ![code isEqual: currentState.code]) {
            [BPNotificationHelper sendNotificationWithMessage: [
                NSString stringWithFormat: @"Connected to relay with code: %@", code
            ]];
        }
        
        wasConnectedBefore = true;
        failedConnectionAttemptCountInARow = 0;
        
        [currentState updateCode: code secret: secret connected: true];
    }
    
    - (void) sendDictionary:(NSDictionary*)dictionary {
        if (!socket) {
            LOG(@"Tried to send dictionary without socket");
            return;
        }
        
        NSError* jsonEncodingError;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject: dictionary options: 0 error: &jsonEncodingError];
        
        if (jsonEncodingError) {
            LOG(@"Serializing dictionary (%@) failed with error: %@", dictionary, jsonEncodingError);
        }
        
        // so. for some incomprehensible reason, the precompiler for theos chokes when you include `{.*}`
        // in a string literal, so we have to cheat and escape them by inserting their unicode codes as
        // characters in format arguments
        NSString* stringToBeSent = (jsonEncodingError != nil)
            ? [NSString stringWithFormat: @"%C \"error\": \"Couldn't serialize to JSON: %@\" %C", 0x007b, jsonEncodingError, 0x007b]
            : [NSString.alloc initWithData: jsonData encoding: NSUTF8StringEncoding];
            
        LOG(@"Sending dictionary string: %@", stringToBeSent);
        
        NSError* sendingError;
        [socket sendString: stringToBeSent error: &sendingError];
        
        if (sendingError) {
            LOG(@"Sending dictionary string failed with error: %@", sendingError);
        }
    }
    
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data id:(NSNumber*)requestIdentifier {
        NSMutableDictionary* messageContents = [NSMutableDictionary new];
        
        messageContents[kCommand] = command;
        
        if (data) {
            messageContents[kData] = data;
        }
        
        if (requestIdentifier) {
            messageContents[kId] = requestIdentifier;
        }
        
        [self sendDictionary: messageContents];
    }
    
    - (void) sendMessageWithCommand:(NSString*)command data:(NSDictionary*)data {
        [self sendMessageWithCommand: command data: data id: nil];
    }
    
    - (void) sendMessageWithCommand:(NSString*)command {
        [self sendMessageWithCommand: command data: nil id: nil];
    }
    
    - (void) sendBeginMessage {
        NSMutableDictionary* data = [NSMutableDictionary new];
        
        if (currentState.code && currentState.secret) {
            data[kCode] = currentState.code;
            data[kSecret] = currentState.secret;
        }
        
        [self sendMessageWithCommand: kCommandRegister data: data];
    }
    
    - (void) sendPongMessage {
        [self sendMessageWithCommand: kCommandPong];
    }
    
    - (void) sendIdentifiersMessageForId:(NSNumber*)requestIdentifier {
        NSDictionary* identifiers = [BPDeviceIdentifiers get];
        
        // Make sure we don't send multiple notifications
        // if the version info is requested multiple
        // times in a row
        double currentTimestamp = [NSDate.date timeIntervalSince1970];
        
        if (!lastIdentifiersSendTimestamp || (lastIdentifiersSendTimestamp + 10) < currentTimestamp) {
            [BPNotificationHelper sendNotificationWithMessage: @"Starting registration flow"];
        }
        
        lastIdentifiersSendTimestamp = currentTimestamp;
        
        [self
            sendMessageWithCommand: kCommandResponse
            data: @{
                kVersions: identifiers
            }
            id: requestIdentifier
        ];
    }
    
    - (void) sendValidationData:(NSData*)validationData error:(NSError*)error {
        if (!validationDataRequestIdentifier) {
            LOG(@"Not sending validation data because it was not generated due to a request");
            return;
        }
        
        NSMutableDictionary* data = [NSMutableDictionary new];
        
        if (error) {
            data[kError] = [NSString stringWithFormat:@"Couldn't retrieve validation data: %@", error];
        }
        
        if (validationData) {
            data[kData] = [validationData base64EncodedStringWithOptions:0];
        }
        
        [self sendMessageWithCommand: kCommandResponse data: data id: validationDataRequestIdentifier];
        
        validationDataRequestIdentifier = nil;
    }
@end