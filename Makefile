include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FakeCamera
FakeCamera_FILES = Tweak.x
FakeCamera_FRAMEWORKS = AVFoundation UIKit Foundation
FakeCamera_CFLAGS = -fobjc-arc
FakeCamera_LDFLAGS = -Wl,-segalign,4000  # Optional cho alignment nếu cần

# Nếu là rootless (Dopamine/RootHide), uncomment dòng dưới
# THEOS_PACKAGE_SCHEME = rootless

include $(THEOS_MAKE_PATH)/tweak.mk