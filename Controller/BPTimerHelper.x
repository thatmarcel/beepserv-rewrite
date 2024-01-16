#import "BPTimerHelper.h"
#import "../Shared/Constants.h"

// This class creates a PCSimpleTimer so we don't have to
// let Logos pre-process the whole BPSocketConnectionManager.m
@implementation BPTimerHelper
	+ (PCSimpleTimer*) createTimerWithTimeInterval:(double)timeInterval serviceIdentifier:(NSString*)serviceIdentifier target:(id)target selector:(SEL)selector userInfo:(id)userInfo {
		return [[%c(PCSimpleTimer) alloc]
			initWithTimeInterval: timeInterval
			serviceIdentifier: serviceIdentifier
			target: target
			selector: selector
			userInfo: userInfo
		];
	}
@end