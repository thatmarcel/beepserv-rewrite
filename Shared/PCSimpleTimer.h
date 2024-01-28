#import <Foundation/Foundation.h>

@interface PCSimpleTimer: NSObject
	- (instancetype) initWithTimeInterval:(double)timeInterval serviceIdentifier:(NSString*)serviceIdentifier target:(id)target selector:(SEL)selector userInfo:(id)userInfo;
	- (void) scheduleInRunLoop:(NSRunLoop*)runLoop;
	- (void) invalidate;
@end