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

TOOL_NAME = BeepservController

LINK_DIRS := $(shell sh -c "find ../SocketRocket/SocketRocket -type d | xargs -I % echo -I%")
M_FILES := $(shell find ../SocketRocket/SocketRocket -type f -name '*.m')

$(TOOL_NAME)_FILES = $(wildcard *.x) $(wildcard *.m) ../Shared/Logging.m ../Shared/BPState.m ../Shared/BPPrefs.m ../Shared/BPTimer.m $(M_FILES) ../libroot/src/dyn.c
$(TOOL_NAME)_CFLAGS = -fobjc-arc -I../SocketRocket -Wno-deprecated $(LINK_DIRS)
$(TOOL_NAME)_LIBRARIES = MobileGestalt
$(TOOL_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
$(TOOL_NAME)_INSTALL_PATH = /usr/libexec

include $(THEOS_MAKE_PATH)/tool.mk