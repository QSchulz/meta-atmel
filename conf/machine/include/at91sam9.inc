# Atmel AT91SAM9 defaults
require conf/machine/include/soc-family.inc
require conf/machine/include/tune-arm926ejs.inc
require conf/machine/include/bootloaders.inc

SOC_FAMILY = "at91sam9"

PREFERRED_PROVIDER_virtual/kernel_at91sam9 ?= "linux-at91"
PREFERRED_PROVIDER_virtual/bootloader_at91sam9 ?= "u-boot-at91"

DTB_LOAD ?= "0x21000000"
DTBO_LOAD ?= "0x20f00000"

# used by sysvinit_2
SERIAL_CONSOLE ?= "115200 ttyS0"
