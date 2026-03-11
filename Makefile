include $(THEOS)/makefiles/common.mk

TWEAK_NAME = dylibsvcam
dylibsvcam_FILES = Tweak.x
dylibsvcam_FRAMEWORKS = UIKit AVFoundation CoreVideo CoreMedia Foundation AudioToolbox
dylibsvcam_LDFLAGS = -lobjc -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
    install.exec "killall -9 SpringBoard"