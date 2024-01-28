#import "./BPTimer.h"
#import "./Constants.h"

// This class schedules an NSTimer, PCSimpleTimer
// and runs dispatch_after because
// NSTimer does not (reliably) fire during device sleep,
// PCSimpleTimer seems to have issues on some devices,
// and dispatch_after is here just for good measure
@implementation BPTimer
	@synthesize completionBlock;
	@synthesize hasFiredAlready;
	
	@synthesize pcSimpleTimer;
	@synthesize nsTimer;
	
	+ (BPTimer*) scheduleTimerWithTimeInterval:(double)timeInterval completion:(BPTimerCompletionBlock)completionBlock {
		return [[BPTimer alloc] initWithTimeInterval: timeInterval completion: completionBlock];
	}
	
	- (instancetype) initWithTimeInterval:(double)timeInterval completion:(BPTimerCompletionBlock)completion {
		self = [super init];
		
		self.completionBlock = completion;
		
		pcSimpleTimer = [[NSClassFromString(@"PCSimpleTimer") alloc]
			initWithTimeInterval: timeInterval
			serviceIdentifier: kSuiteName
			target: self
			selector: @selector(handleTimerFired)
			userInfo: nil
		];
		
		[pcSimpleTimer scheduleInRunLoop: [NSRunLoop mainRunLoop]];
		
		nsTimer = [NSTimer
			scheduledTimerWithTimeInterval: (timeInterval + 0.1)
			repeats: false
			block: ^(NSTimer* timer) {
				[self handleTimerFired];
			}
		];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (timeInterval + 0.2) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self handleTimerFired];
		});
		
		return self;
	}
	
	- (void) handleTimerFired {
		if (self.hasFiredAlready) {
			return;
		}
		
		self.hasFiredAlready = true;
		
		if (self.completionBlock) {
			self.completionBlock();
		}
		
		if (self.pcSimpleTimer) {
			[self.pcSimpleTimer invalidate];
			self.pcSimpleTimer = nil;
		}
		
		if (self.nsTimer) {
			[self.nsTimer invalidate];
			self.nsTimer = nil;
		}
	}
	
	- (void) invalidate {
		self.hasFiredAlready = true;
		
		if (self.pcSimpleTimer) {
			[self.pcSimpleTimer invalidate];
			self.pcSimpleTimer = nil;
		}
		
		if (self.nsTimer) {
			[self.nsTimer invalidate];
			self.nsTimer = nil;
		}
	}
@end