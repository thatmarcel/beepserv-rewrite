#import <Foundation/Foundation.h>
#import "../libroot/src/libroot.h"

static NSString* kSuiteName = @"com.beeper.beepserv";

#define LOG_FILE_PATH JBROOT_PATH_NSSTRING(@"/var/mobile/beepserv.log")

static NSString* kModuleNameApplication = @"Application";
static NSString* kModuleNameController = @"Controller";
static NSString* kModuleNameIdentityServices = @"IdentityServices";
static NSString* kModuleNameNotificationHelper = @"NotificationHelper";

static const NSString* kDefaultRelayURL = @"https://registration-relay.beeper.com/api/v1/provider";

static NSString* kCommandRegister = @"register";
static NSString* kCommandPing = @"ping";
static NSString* kCommandPong = @"pong";
static NSString* kCommandResponse = @"response";
static NSString* kCommandGetValidationData = @"get-validation-data";
static NSString* kCommandGetVersionInfo = @"get-version-info";

static const NSString* kData = @"data";
static const NSString* kId = @"id";
static const NSString* kCommand = @"command";

static const NSString* kVersions = @"versions";

static const NSString* kCode = @"code";
static const NSString* kSecret = @"secret";
static const NSString* kConnected = @"connected";

static const NSString* kError = @"error";

static const NSString* kValidationData = @"validationData";
static const NSString* kValidationDataExpiryTimestamp = @"validationDataExpiryTimestamp";

static const NSString* kMessageText = @"messageText";

static const NSString* kNotificationRequestValidationData = @"com.beeper.beepserv/requestValidationData";
static const NSString* kNotificationRequestValidationDataAcknowledgement = @"com.beeper.beepserv/requestValidationDataAcknowledgement";
static const NSString* kNotificationValidationDataResponse = @"com.beeper.beepserv/validationDataResponse";
static const NSString* kNotificationRequestStateUpdate = @"com.beeper.beepserv/requestStateUpdate";
static const NSString* kNotificationUpdateState = @"com.beeper.beepserv/updateState";
static const NSString* kNotificationRequestNewRegistrationCode = @"com.beeper.beepserv/requestNewRegistrationCode";
static const NSString* kNotificationSendNotificationBulletin = @"com.beeper.beepserv/sendNotificationBulletin";
static const NSString* kNotificationSpringBoardRestarted = @"com.beeper.beepserv/springBoardRestarted";
static const NSString* kNotificationLogEntryFromIdentityServices = @"com.beeper.beepserv/logEntryFromIdentityServices";

#define PREFS_FILE_PATH JBROOT_PATH_NSSTRING(@"/var/mobile/.beepserv_prefs")

static const NSString* kPrefsKeyShouldShowNotifications = @"shouldShowNotifications";