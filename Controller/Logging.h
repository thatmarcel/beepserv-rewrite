#import "../Shared/Constants.h"

#define LOG(...) bp_log_impl(kModuleNameController, [NSString stringWithFormat: __VA_ARGS__])

void bp_log_impl(NSString* moduleName, NSString* logString);