#import <Foundation/Foundation.h>
#import "Headers/PCSimpleTimer.h"

@interface BPTimerHelper: NSObject
	+ (PCSimpleTimer*) createTimerWithTimeInterval:(double)timeInterval serviceIdentifier:(NSString*)serviceIdentifier target:(id)target selector:(SEL)selector userInfo:(id)userInfo;
@end