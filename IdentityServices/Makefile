ARCHS = arm64 arm64e

ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
	TARGET := iphone:clang:latest:15.0
else
	TARGET_OS_DEPLOYMENT_VERSION = 10.0
	OLDER_XCODE_PATH=/Applications/Xcode_11.7.app
	PREFIX=$(OLDER_XCODE_PATH)/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/
	SYSROOT=$(OLDER_XCODE_PATH)/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
	SDKVERSION = 13.7
	INCLUDE_SDKVERSION = 13.7
endif

include $(THEOS)/makefiles/common.mk

INSTALL_TARGET_PROCESSES = identityservicesd

TWEAK_NAME = BeepservIdentityServices

$(TWEAK_NAME)_FILES = $(wildcard *.x) ../Shared/BPTimer.m ../Shared/Logging.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk