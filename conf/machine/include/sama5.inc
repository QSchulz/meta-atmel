# Atmel SAMA5 defaults
require conf/machine/include/soc-family.inc
require conf/machine/include/tune-cortexa5.inc
require conf/machine/include/bootloaders.inc

SOC_FAMILY = "sama5"

PREFERRED_PROVIDER_virtual/kernel_sama5 ?= "linux-at91"
KERNEL_IMAGETYPES += "fitImage"
# Required by kernel-fitimage class
PREFERRED_PROVIDER_u-boot_sama5 ?= "u-boot-at91"
PREFERRED_PROVIDER_virtual/bootloader_sama5 ?= "u-boot-at91"

PREFERRED_PROVIDER_jpeg ?= "jpeg"
PREFERRED_PROVIDER_jpeg-native ?= "jpeg-native"

DTB_LOAD ?= "0x21000000"
DTBO_LOAD ?= "0x20f00000"

# used by sysvinit_2
SERIAL_CONSOLE ?= "115200 ttyS0"
