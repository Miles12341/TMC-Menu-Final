GO_EASY_ON_ME = 1
DEBUG = 0
FINALPACKAGE = 1

# This is the important part for arm64/arm64e
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MilesTMC
MilesTMC_FILES = Tweak.xm
MilesTMC_FRAMEWORKS = UIKit WebKit

# This line fixes the "Undefined symbols" error
MilesTMC_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
