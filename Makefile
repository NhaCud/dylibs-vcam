export TARGET = iphone:latest:12.0
export ARCHS = arm64 arm64e
export THEOS_DEVICE_IP = 127.0.0.1
export DEBUG = 0
export FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = dylibsvcam
dylibsvcam_FILES = Tweak.x
dylibsvcam_CFLAGS = -fobjc-arc
dylibsvcam_FRAMEWORKS = UIKit AVFoundation CoreVideo CoreMedia Foundation AudioToolbox
dylibsvcam_LIBRARIES = activator
dylibsvcam_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
    @echo "✅ Build thành công! File .deb nằm trong thư mục packages"