TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCCalcRedirectPrefs

FW_REF_DIR := $(CURDIR)/.fw_ref/$(if $(THEOS_PACKAGE_SCHEME),$(THEOS_PACKAGE_SCHEME),rootless)
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
ALTLIST_SRC := ../vendor/AltList_Roothide.framework
else
ALTLIST_SRC := ../vendor/AltList.framework
endif
_PREP := $(shell mkdir -p "$(FW_REF_DIR)" && rm -rf "$(FW_REF_DIR)/AltList.framework" && cp -R "$(ALTLIST_SRC)" "$(FW_REF_DIR)/AltList.framework")

CCCalcRedirectPrefs_FILES = CCCalcRedirectRootListController.m
CCCalcRedirectPrefs_FRAMEWORKS = Foundation UIKit CoreFoundation
CCCalcRedirectPrefs_PRIVATE_FRAMEWORKS = Preferences
CCCalcRedirectPrefs_EXTRA_FRAMEWORKS = AltList
CCCalcRedirectPrefs_INSTALL_PATH = /Library/PreferenceBundles

CCCalcRedirectPrefs_CFLAGS = -fobjc-arc -I$(CURDIR)/../vendor/AltList.framework/Headers -F$(FW_REF_DIR)
CCCalcRedirectPrefs_LDFLAGS = -F$(FW_REF_DIR)
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
CCCalcRedirectPrefs_LIBRARIES += roothide
else ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
CCCalcRedirectPrefs_LDFLAGS += -Wl,-rpath,/var/jb/Library/Frameworks
else
CCCalcRedirectPrefs_LDFLAGS += -Wl,-rpath,/Library/Frameworks
endif

include $(THEOS_MAKE_PATH)/bundle.mk
