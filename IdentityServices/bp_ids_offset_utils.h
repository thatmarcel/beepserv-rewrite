#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

extern intptr_t bp_nac_init_func_offset;
extern intptr_t bp_nac_key_establishment_func_offset;
extern intptr_t bp_nac_sign_func_offset;

bool bp_find_offsets();

intptr_t bp_get_ref_addr();