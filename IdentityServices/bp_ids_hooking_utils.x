#import "bp_ids_hooking_utils.h"
#import "./Logging.h"
#import "./Tweak.h"

// Just calling nac_sign did not work reliably, so we hook
// it and call the original function we get from MSHookFunction

typedef int bp_nac_sign_type(void *, void *, int, void **, int *);

bp_nac_sign_type* bp_old_nac_sign;

int bp_new_nac_sign(void* arg1, void* arg2, int arg3, void** arg4, int* arg5) {
    return bp_old_nac_sign(arg1, arg2, arg3, arg4, arg5);
}

typedef int bp_nac_key_establishment_type(void *, void *, int);

bp_nac_key_establishment_type* bp_old_nac_key_establishment;

int bp_new_nac_key_establishment(void* arg1, void* arg2, int arg3) {
    LOG(@"nac_key_establishment was called");
    
    int result = bp_old_nac_key_establishment(arg1, arg2, arg3);
    
    LOG(@"Called the original nac_key_establishment");
    
    LOG(@"Calling old_nac_sign");
    
    void* validationDataBytes;
    int validationDataLength;
    
    bp_old_nac_sign(arg1, nil, 0, &validationDataBytes, &validationDataLength);
    
    LOG(@"Call to nac_sign is done");
    
    NSData* validationData = [NSData dataWithBytes: validationDataBytes length: validationDataLength];
    
    LOG(@"nac_sign returned validation data: %@", validationData);
    
    bp_handle_validation_data(validationData, false);
    
    return result;
}

void bp_setup_hooks() {
    LOG(@"Hooking");
    
    intptr_t ref_addr = bp_get_ref_addr();
    
    bp_nac_key_establishment_type* nac_key_establishment_func = (bp_nac_key_establishment_type*) (ref_addr + bp_nac_key_establishment_func_offset);
    
    bp_nac_sign_type* nac_sign_func = (bp_nac_sign_type*) (ref_addr + bp_nac_sign_func_offset);
    
    MSHookFunction(nac_key_establishment_func, &bp_new_nac_key_establishment, (void**) &bp_old_nac_key_establishment);
    MSHookFunction(nac_sign_func, &bp_new_nac_sign, (void**) &bp_old_nac_sign);
    
    LOG(@"Done hooking");
}