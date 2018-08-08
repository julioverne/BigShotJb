include $(THEOS)/makefiles/common.mk



TWEAK_NAME = BigShotJb
BigShotJb_FILES = /mnt/d/codes/BigShotJb/Listener.xm /mnt/d/codes/BigShotJb/UIWindow+Bigshot.m /mnt/d/codes/BigShotJb/UIView+Toast.m
BigShotJb_FRAMEWORKS = UIKit CoreGraphics QuartzCore CydiaSubstrate
BigShotJb_LIBRARIES = rocketbootstrap
BigShotJb_PRIVATE_FRAMEWORKS = AppSupport
#SHARED_CFLAGS = -fobjc-arc

export ARCHS = armv7 arm64
BigShotJb_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk

