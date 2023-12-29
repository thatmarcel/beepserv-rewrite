#import "BPDeviceIdentifiers.h"
#import <sys/utsname.h>
#import <sys/sysctl.h>

CFPropertyListRef MGCopyAnswer(CFStringRef property);

static NSDictionary* cachedIdentifiers;

@implementation BPDeviceIdentifiers
    + (NSDictionary*) get {
        if (!cachedIdentifiers) {
            [self cache];
        }
        
        return cachedIdentifiers;
    }
    
    + (void) cache {
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString *model = [NSString stringWithCString: systemInfo.machine encoding: NSUTF8StringEncoding];
        
        size_t malloc_size = 10;
        char *buildNumberBuf = malloc(malloc_size);
        sysctlbyname("kern.osversion\0", (void *)buildNumberBuf, &malloc_size, NULL, 0);
        
        // we don't need to free `buildNumberBuf` if we pass it into this method
        NSString *buildNumber = [NSString stringWithCString: buildNumberBuf encoding: NSUTF8StringEncoding];
        
        cachedIdentifiers = @{
            @"hardware_version": model,
            @"software_name": @"iPhone OS",
            @"software_version": UIDevice.currentDevice.systemVersion,
            @"software_build_id": buildNumber,
            @"unique_device_id": (__bridge NSString *) MGCopyAnswer(CFSTR("UniqueDeviceID")),
            @"serial_number": (__bridge NSString *) MGCopyAnswer(CFSTR("SerialNumber"))
        };
    }
@end