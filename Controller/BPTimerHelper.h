#import <Foundation/Foundation.h>
#import "Headers/PCSimpleTimer.h"

typedef void (^BPTimerHelperCompletionBlock)(void);

@interface BPTimerHelper: NSObject
	+ (BPTimerHelper*) scheduleTimerWithTimeInterval:(double)timeInterval completion:(BPTimerHelperCompletionBlock)completion;
	
	@property (copy) BPTimerHelperCompletionBlock completionBlock;
	@property bool hasFiredAlready;
	
	@property (retain) PCSimpleTimer* pcSimpleTimer;
	@property (retain) NSTimer* nsTimer;
	
	- (instancetype) initWithTimeInterval:(double)timeInterval completion:(BPTimerHelperCompletionBlock)completion;
	
	- (void) invalidate;
@end