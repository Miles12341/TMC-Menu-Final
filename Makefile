# --- MILES TMC MENU MAKEFILE ---
DEBUG = 0
FINALPACKAGE = 1
GO_EASY_ON_ME = 1

# Targets modern iPhones (13, 14, 15, 16) using the A15-A18 chips
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MilesTMC
MilesTMC_FILES = Tweak.xm
MilesTMC_FRAMEWORKS = UIKit WebKit

# This line is CRITICAL: It tells the phone to ignore missing symbols until the game is open
MilesTMC_LDFLAGS = -undefined dynamic_lookup

# This line ignores the 'deprecated' errors that caused the Red X earlier
MilesTMC_CFLAGS = -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk

