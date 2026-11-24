TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCCalcRedirect

CCCalcRedirect_FILES = Tweak.x
CCCalcRedirect_CFLAGS = -fobjc-arc
CCCalcRedirect_FRAMEWORKS = Foundation UIKit CoreFoundation
CCCalcRedirect_PRIVATE_FRAMEWORKS = ControlCenterUIKit
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
CCCalcRedirect_LIBRARIES = roothide
endif

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp prefs/entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CCCalcRedirect.plist$(ECHO_END)
