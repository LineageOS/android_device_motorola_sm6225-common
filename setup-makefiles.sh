#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."
export TARGET_ENABLE_CHECKELF="true"

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

function vendor_imports() {
    cat << EOF >> "$1"
		"device/motorola/sm6225-common",
		"hardware/qcom-caf/sm8250",
		"hardware/qcom-caf/wlan",
		"vendor/qcom/opensource/dataservices",
		"vendor/qcom/opensource/display",
EOF
}

function lib_to_package_fixup_vendor_variants() {
    if [ "$2" != "vendor" ]; then
        return 1
    fi

    case "$1" in
        com.qualcomm.qti.dpm.api@1.0 | \
        vendor.qti.hardware.fm@1.0)
            echo "$1-vendor"
            ;;
        *)
            return 1
    esac
}

function lib_to_package_fixup() {
    lib_to_package_fixup_proto_3_9_1 "$1" || \
    lib_to_package_fixup_vendor_variants "$@"
}

# Initialize the helper for common
setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true

# Warning headers and guards
write_headers "borneo capri caprip cebu guam guamna guamp devon hawao rhode"

# The standard common blobs
write_makefiles "${MY_DIR}/proprietary-files.txt" true

# Finish
write_footers

if [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/setup-makefiles.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false

    # Warning headers and guards
    write_headers

    # The standard device blobs
    write_makefiles "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" true

    if [ -f "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files-carriersettings.txt" ]; then
        write_rro_package "CarrierConfigOverlay" "com.android.carrierconfig" product
        write_single_product_packages "CarrierConfigOverlay"
    fi

    if [ -f "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt" ]; then
        append_firmware_calls_to_makefiles "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt"
    fi

    # Finish
    write_footers
fi
