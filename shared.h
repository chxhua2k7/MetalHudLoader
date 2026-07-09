#ifndef MetalHudLoader_shared_h
#define MetalHudLoader_shared_h

// Darwin notification state is used to share the toggle across sandboxed
// processes; the plist persists it across reboots (restored by SpringBoard).
#define kMHLEnabledStateName "com.pookjw.metalhudloader.enabled"
// Written directly (not via cfprefsd) from SpringBoard, next to the system's
// own ModuleConfiguration.plist which SpringBoard is always allowed to write.
#define kMHLPrefsPath "/var/mobile/Library/ControlCenter/MetalHudLoader.plist"
#define kMHLEnabledKey "Enabled"

enum {
    MHLStateUnset = 0,
    MHLStateDisabled = 1,
    MHLStateEnabled = 2,
};

#endif
