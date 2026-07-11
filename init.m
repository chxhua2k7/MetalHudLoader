#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <notify.h>
#import "shared.h"

static uint64_t currentState(void) {
    uint64_t state = MHLStateUnset;
    // The token is intentionally never cancelled: notifyd drops a name's
    // state once its last registration goes away, so every process keeps
    // one registration alive (SpringBoard anchors it across the session).
    static int token;
    if (notify_register_check(kMHLEnabledStateName, &token) == NOTIFY_STATUS_OK) {
        // SpringBoard launches before any app, so it restores the persisted
        // preference into notifyd where sandboxed processes can read it.
        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@kMHLPrefsPath];
            NSNumber *enabled = prefs[@kMHLEnabledKey];
            notify_set_state(token, MHLStateMake(enabled == nil || enabled.boolValue, MHLElementsMaskFromPrefs(prefs)));
        }
        notify_get_state(token, &state);
    }
    return state;
}

__attribute__((constructor)) static void init() {
    uint64_t state = currentState();
    if ((state & MHLEnabledFieldMask) == MHLStateDisabled) {
        return;
    }

    uint64_t elementsMask = state >> MHLElementsShift;
    if (elementsMask != 0) {
        NSMutableArray<NSString *> *names = [NSMutableArray new];
        for (uint64_t i = 0; i < MHLElementCount; i++) {
            if (elementsMask & (1ULL << i)) {
                [names addObject:@(MHLElementNames[i])];
            }
        }
        setenv("MTL_HUD_ELEMENTS", [names componentsJoinedByString:@","].UTF8String, 1);
    }

    setenv("MTL_HUD_ENABLED", "1", 1);

    const char *path;
    if (kCFCoreFoundationVersionNumber >= 2042.1020) {
        path = "/Symbols/usr/lib/libMTLHud.dylib";
    } else {
        path = "/usr/lib/libMTLHud.dylib";
    }

    dlopen(path, RTLD_NOW);
}
