#import <Foundation/Foundation.h>
#import <stdio.h>
#import "BPSocketConnectionManager.h"

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		[BPSocketConnectionManager.sharedInstance startConnection];
		
		// Keeps the process running
		[[NSRunLoop currentRunLoop] run];
		
		return 0;
	}
}
