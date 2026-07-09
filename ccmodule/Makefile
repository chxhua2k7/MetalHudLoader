TARGET := iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MetalHudModule
MetalHudModule_BUNDLE_EXTENSION = bundle
MetalHudModule_FILES = MetalHudModule.m
MetalHudModule_CFLAGS = -fobjc-arc
MetalHudModule_FRAMEWORKS = UIKit
MetalHudModule_PRIVATE_FRAMEWORKS = ControlCenterUIKit
MetalHudModule_INSTALL_PATH = /Library/ControlCenter/Bundles

include $(THEOS_MAKE_PATH)/bundle.mk
