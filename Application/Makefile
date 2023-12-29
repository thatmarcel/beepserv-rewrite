ARCHS = arm64 arm64e

ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
	TARGET := iphone:clang:latest:15.0
else
	OLDER_XCODE_PATH=/Applications/Xcode_11.7.app
	PREFIX=$(OLDER_XCODE_PATH)/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/
	SYSROOT=$(OLDER_XCODE_PATH)/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
	SDKVERSION = 13.7
endif

INSTALL_TARGET_PROCESSES = BeepservApplication

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = BeepservApplication

$(APPLICATION_NAME)_FILES = $(wildcard *.m) ../Shared/BPState.m ../Shared/Logging.m ../Shared/BPPrefs.m
$(APPLICATION_NAME)_FRAMEWORKS = UIKit CoreGraphics
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
