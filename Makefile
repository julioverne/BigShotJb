FINALPACKAGE=1
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BigShotJb
$(TWEAK_NAME)_FILES = Listener.xm UIWindow+Bigshot.m UIView+Toast.m
$(TWEAK_NAME)_FRAMEWORKS = UIKit CoreGraphics QuartzCore CydiaSubstrate
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport
#SHARED_CFLAGS = -fobjc-arc

export ARCHS = armv7 arm64 arm64e
$(TWEAK_NAME)_ARCHS = armv7 arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk

