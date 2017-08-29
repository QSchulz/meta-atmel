# Override fitimage_assemble to add support for DT overlays in fitImage

inherit kernel-fitimage

#
# Emit the fitImage ITS DTB section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to DTB image
# $4 ... Load address
fitimage_emit_section_dtb() {

	dtb_csum="sha1"

	cat << EOF >> ${1}
                fdt@${2} {
                        description = "Flattened Device Tree blob";
                        data = /incbin/("${3}");
                        type = "flat_dt";
                        arch = "${UBOOT_ARCH}";
                        compression = "none";
                        load = <${4}>;
                        hash@1 {
                                algo = "${dtb_csum}";
                        };
                };
EOF
}

#
# Emit the fitImage ITS configuration section for DT overlay
#
# $1 ... .its filename
# $2 ... DTBO image ID
# $3 ... DTBO name
fitimage_emit_section_config_overlay() {

	conf_csum="sha1"
	if [ -n "${UBOOT_SIGN_ENABLE}" ] ; then
		conf_sign_keyname="${UBOOT_SIGN_KEYNAME}"
	fi

	fdt_line=""

	if [ -n "${2}" ]; then
		conf_desc="${conf_desc}, FDT blob"
		fdt_line="fdt = \"fdt@${2}\";"
	fi

	cat << EOF >> ${1}
                ${3} {
			${fdt_line}
                        hash@1 {
                                algo = "${conf_csum}";
                        };
EOF

	if [ ! -z "${conf_sign_keyname}" ] ; then

		if [ -n "${2}" ]; then
			sign_line="${sign_line}, \"fdt\""
		fi

		sign_line="${sign_line};"

		cat << EOF >> ${1}
                        signature@1 {
                                algo = "${conf_csum},rsa2048";
                                key-name-hint = "${conf_sign_keyname}";
				${sign_line}
                        };
EOF
	fi

	cat << EOF >> ${1}
                };
EOF
}


#
# Assemble fitImage
#
# $1 ... .its filename
# $2 ... fitImage name
# $3 ... include ramdisk
fitimage_assemble() {
	kernelcount=1
	dtbcount=""
	ramdiskcount=${3}
	setupcount=""
	rm -f ${1} arch/${ARCH}/boot/${2}

	fitimage_emit_fit_header ${1}

	#
	# Step 1: Prepare a kernel image section.
	#
	fitimage_emit_section_maint ${1} imagestart

	uboot_prep_kimage
	fitimage_emit_section_kernel ${1} "${kernelcount}" linux.bin "${linux_comp}"

	#
	# Step 2: Prepare a DTB image section
	#
	if test -n "${KERNEL_DEVICETREE}"; then
		dtbcount=1
		for DTB in ${KERNEL_DEVICETREE}; do
			if echo ${DTB} | grep -q '/dts/'; then
				bbwarn "${DTB} contains the full path to the the dts file, but only the dtb name should be used."
				DTB=`basename ${DTB} | sed 's,\.dts$,.dtb,g'`
			fi
			DTB_PATH="arch/${ARCH}/boot/dts/${DTB}"
			if [ ! -e "${DTB_PATH}" ]; then
				DTB_PATH="arch/${ARCH}/boot/${DTB}"
			fi

			fitimage_emit_section_dtb ${1} ${dtbcount} ${DTB_PATH} ${DTB_LOAD}
			dtbcount=`expr ${dtbcount} + 1`
		done

		if test -n "${KERNEL_DEVICETREE_OVERLAYS}"; then
			dtbocount=0
			for DTB in ${KERNEL_DEVICETREE_OVERLAYS}; do
				if echo ${DTB} | grep -q '/dts/'; then
					bbwarn "${DTB} contains the full path to the the dts file, but only the dtb name should be used."
					DTB=`basename ${DTB} | sed 's,\.dts$,.dtbo,g'`
				fi
				DTB_PATH="${DEPLOY_DIR_IMAGE}/${DTB}"
				if [ ! -e "${DTB_PATH}" ]; then
					bberror "${DTB_PATH} does not exist. Make sure the DTBOs have been deployed."
				fi

				fitimage_emit_section_dtb ${1} `expr ${dtbcount} + ${dtbocount}` ${DTB_PATH} ${DTBO_LOAD}
				dtbocount=`expr ${dtbocount} + 1`
			done
		fi
	fi

	#
	# Step 3: Prepare a setup section. (For x86)
	#
	if test -e arch/${ARCH}/boot/setup.bin ; then
		setupcount=1
		fitimage_emit_section_setup ${1} "${setupcount}" arch/${ARCH}/boot/setup.bin
	fi

	#
	# Step 4: Prepare a ramdisk section.
	#
	if [ "x${ramdiskcount}" = "x1" ] ; then
		copy_initramfs
		fitimage_emit_section_ramdisk ${1} "${ramdiskcount}" usr/${INITRAMFS_IMAGE}-${MACHINE}.cpio
	fi

	fitimage_emit_section_maint ${1} sectend

	# Force the first Kernel and DTB in the default config
	kernelcount=1
	dtbo_offset=${dtbcount}
	if test -n "${dtbcount}"; then
		dtbcount=1
	fi

	#
	# Step 5: Prepare a configurations section
	#
	fitimage_emit_section_maint ${1} confstart

	fitimage_emit_section_config ${1} "${kernelcount}" "${dtbcount}" "${ramdiskcount}" "${setupcount}"

	if test -n "${KERNEL_DEVICETREE_OVERLAYS}"; then
		for dtbo in `seq 1 ${dtbocount}`; do
			dtbo_name=`echo '${KERNEL_DEVICETREE_OVERLAYS}' | cut -d' ' -f ${dtbo}`
			count=`expr ${dtbo_offset} + ${dtbo} - 1`
			fitimage_emit_section_config_overlay ${1} "${count}" "${dtbo_name}"
		done
	fi

	fitimage_emit_section_maint ${1} sectend

	fitimage_emit_section_maint ${1} fitend

	#
	# Step 6: Assemble the image
	#
	uboot-mkimage \
		${@'-D "${UBOOT_MKIMAGE_DTCOPTS}"' if len('${UBOOT_MKIMAGE_DTCOPTS}') else ''} \
		-f ${1} \
		arch/${ARCH}/boot/${2}

	#
	# Step 7: Sign the image and add public key to U-Boot dtb
	#
	if [ "x${UBOOT_SIGN_ENABLE}" = "x1" ] ; then
		uboot-mkimage \
			${@'-D "${UBOOT_MKIMAGE_DTCOPTS}"' if len('${UBOOT_MKIMAGE_DTCOPTS}') else ''} \
			-F -k "${UBOOT_SIGN_KEYDIR}" \
			-K "${DEPLOY_DIR_IMAGE}/${UBOOT_DTB_BINARY}" \
			-r arch/${ARCH}/boot/${2}
	fi
}
