# Add this line at the very top:
GO_EASY_ON_ME = 1

TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MilesTMC
MilesTMC_FILES = Tweak.xm
MilesTMC_FRAMEWORKS = UIKit WebKit
# Add this line too to ignore the "deprecated" warnings:
MilesTMC_CFLAGS = -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
