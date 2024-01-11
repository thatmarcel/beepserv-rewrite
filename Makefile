ARCHS = arm64 arm64e

ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
	TARGET := iphone:clang:latest:15.0
else
	OLDER_XCODE_PATH=/Applications/Xcode_11.7.app
	PREFIX=$(OLDER_XCODE_PATH)/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/
	SYSROOT=$(OLDER_XCODE_PATH)/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
	SDKVERSION = 13.7
endif

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += IdentityServices
SUBPROJECTS += Controller
SUBPROJECTS += NotificationHelper
SUBPROJECTS += Application

include $(THEOS_MAKE_PATH)/aggregate.mk

# try to apply the patch that will make it work. If it exits with non-zero, that just means
# the patch is already applied, so we can safely ignore it with `|| :`
before-all::
	cd SocketRocket && git apply -q ../SocketRocket.patch || :

after-install::
		install.exec "uicache -a"
		install.exec "sbreload"
		
after-stage::
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	$(ECHO_NOTHING) rm $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd-rootful.plist $(ECHO_END)
	$(ECHO_NOTHING) mv $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd-rootless.plist $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd.plist $(ECHO_END)
else
	$(ECHO_NOTHING) rm $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd-rootless.plist $(ECHO_END)
	$(ECHO_NOTHING) mv $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd-rootful.plist $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd.plist $(ECHO_END)
endif
	$(ECHO_NOTHING) mv $(THEOS_STAGING_DIR)/usr/libexec/BeepservController $(THEOS_STAGING_DIR)/usr/libexec/beepservd $(ECHO_END)
	$(ECHO_NOTHING) $(FAKEROOT) chown root:wheel $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.beeper.beepservd.plist $(ECHO_END)