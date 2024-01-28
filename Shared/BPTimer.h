#import <Foundation/Foundation.h>
#import "./PCSimpleTimer.h"

typedef void (^BPTimerCompletionBlock)(void);

@interface BPTimer: NSObject
	+ (instancetype) scheduleTimerWithTimeInterval:(double)timeInterval completion:(BPTimerCompletionBlock)completion;
	
	@property (copy) BPTimerCompletionBlock completionBlock;
	@property bool hasFiredAlready;
	
	@property (retain) PCSimpleTimer* pcSimpleTimer;
	@property (retain) NSTimer* nsTimer;
	
	- (instancetype) initWithTimeInterval:(double)timeInterval completion:(BPTimerCompletionBlock)completion;
	
	- (void) invalidate;
@end