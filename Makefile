include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FakeCamera
FakeCamera_FILES = Tweak.x
FakeCamera_FRAMEWORKS = AVFoundation UIKit Foundation CoreVideo
FakeCamera_LIBRARIES = objc
FakeCamera_CFLAGS = -fobjc-arc
FakeCamera_LDFLAGS = -Wl,-segalign,4000

# Nếu rootless, uncomment
# THEOS_PACKAGE_SCHEME = rootless

include $(THEOS_MAKE_PATH)/tweak.mk