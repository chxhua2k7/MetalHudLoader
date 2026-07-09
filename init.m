#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <notify.h>
#import "shared.h"

static BOOL isHudEnabled(void) {
    uint64_t state = MHLStateUnset;
    // The token is intentionally never cancelled: notifyd drops a name's
    // state once its last registration goes away, so every process keeps
    // one registration alive (SpringBoard anchors it across the session).
    static int token;
    if (notify_register_check(kMHLEnabledStateName, &token) == NOTIFY_STATUS_OK) {
        // SpringBoard launches before any app, so it restores the persisted
        // preference into notifyd where sandboxed processes can read it.
        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            NSNumber *enabled = [NSDictionary dictionaryWithContentsOfFile:@kMHLPrefsPath][@kMHLEnabledKey];
            notify_set_state(token, (enabled == nil || enabled.boolValue) ? MHLStateEnabled : MHLStateDisabled);
        }
        notify_get_state(token, &state);
    }
    return state != MHLStateDisabled;
}

__attribute__((constructor)) static void init() {
    if (!isHudEnabled()) {
        return;
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
