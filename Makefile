include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FakeCamera
FakeCamera_FILES = Tweak.x
FakeCamera_FRAMEWORKS = AVFoundation UIKit Foundation CoreVideo
FakeCamera_LIBRARIES = objc
FakeCamera_CFLAGS = -fobjc-arc
FakeCamera_LDFLAGS = -Wl,-segalign,4000
FakeCamera_ARCHS = arm64 arm64e
FakeCamera_SDKVERSION = 14.0  # Fix arm64e deployment error

# Nếu rootless (Dopamine, v.v.), uncomment dòng dưới
# THEOS_PACKAGE_SCHEME = rootless

include $(THEOS_MAKE_PATH)/tweak.mk