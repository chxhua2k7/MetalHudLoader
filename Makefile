TARGET := iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = rootless
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MetalHudLoader
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -fobjc-weak
$(TWEAK_NAME)_FRAMEWORKS = Foundation
$(TWEAK_NAME)_FILES = init.m

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ccmodule
include $(THEOS_MAKE_PATH)/aggregate.mk
