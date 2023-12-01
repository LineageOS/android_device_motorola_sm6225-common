#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system_ext/etc/permissions/moto-telephony.xml)
            sed -i "s#/system/#/system_ext/#" "${2}"
            ;;
        vendor/lib64/camera/components/com.qti.node.gpu.so)
            sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
            ;;
        vendor/lib64/com.qti.feature2.gs.so)
            sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
            ;;
        vendor/lib64/com.qti.feature2.rt.so)
            sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
            ;;
        vendor/lib64/hw/camera.qcom.so)
            sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
            ;;
        vendor/lib64/hw/com.qti.chi.override.so)
            sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
            hexdump -ve '1/1 "%.2X"' "${2}" | sed "s/130A0094/1F2003D5/g" | xxd -r -p > "${EXTRACT_TMP_DIR}/${1##*/}"
            mv "${EXTRACT_TMP_DIR}/${1##*/}" "${2}"
            ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../../${VENDOR}/${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

    if [ -s "$EXTRACT_TMP_DIR/super_dump/product.img" ]; then
        bash "${MY_DIR}/../../${VENDOR}/${DEVICE}/regen-carriersettings.sh" "$EXTRACT_TMP_DIR/super_dump/product.img" "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files-carriersettings.txt"
    fi

    extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files-carriersettings.txt" "${SRC}" "${KANG}" --section "${SECTION}"

    extract_carriersettings
fi

"${MY_DIR}/setup-makefiles.sh"
