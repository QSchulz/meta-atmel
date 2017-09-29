SECTION = "kernel"
DESCRIPTION = "Linux DT overlays for Atmel ARM SoCs (aka AT91)"
SUMMARY = "Linux DT overlays for Atmel ARM SoCs (aka AT91)"
LICENSE = "GPL-2.0 | MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=81fc48e2afd409019eebc15f6e8fc957"

SRCREV = "77c7d7475d730b036f8d6e8a4cfb408529ff1247"
SRC_URI = "git://github.com/QSchulz/dt-overlay-at91.git"

DEPENDS = "dtc-native"

S = "${WORKDIR}/git"

inherit deploy

KERNEL_IMAGEDEST = "boot"
FILES_${PN} = "/${KERNEL_IMAGEDEST}/*.dtbo /${KERNEL_IMAGEDEST}"

# We don't want to pollute /boot for builds using SD card as boot medium
# as wic will automount the first VFAT partition on /boot
FILES_${PN}_at91-sd = ""
ALLOW_EMPTY_${PN}_at91-sd = "1"
INSANE_SKIP_${PN}_at91-sd += "installed-vs-shipped"

do_compile() {
	make DTC=${STAGING_BINDIR_NATIVE}/dtc
}

do_install() {
	install -d ${D}/${KERNEL_IMAGEDEST}
	for DTBO in ${KERNEL_DEVICETREE_OVERLAYS}; do
		install -m 0644 overlays/${DTBO} ${D}/${KERNEL_IMAGEDEST}
	done
}

do_deploy() {
	install -d ${DEPLOYDIR}
	for DTBO in ${KERNEL_DEVICETREE_OVERLAYS}; do
		install -m 0644 overlays/${DTBO} ${DEPLOYDIR}
	done
}
addtask do_deploy after do_compile
