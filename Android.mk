#
# Copyright (C) 2022-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifneq ($(filter borneo capri caprip cebu guam guamna guamp devon hawao rhode, $(TARGET_DEVICE)),)
include $(call all-makefiles-under, $(LOCAL_PATH))

include $(CLEAR_VARS)

FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware_mnt
$(FIRMWARE_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $(FIRMWARE_MOUNT_POINT)"
	@mkdir -p $(TARGET_OUT_VENDOR)/firmware_mnt

BT_FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/bt_firmware
$(BT_FIRMWARE_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $(BT_FIRMWARE_MOUNT_POINT)"
	@mkdir -p $(TARGET_OUT_VENDOR)/bt_firmware

DSP_MOUNT_POINT := $(TARGET_OUT_VENDOR)/dsp
$(DSP_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $(DSP_MOUNT_POINT)"
	@mkdir -p $(TARGET_OUT_VENDOR)/dsp

FSG_MOUNT_POINT := $(TARGET_OUT_VENDOR)/fsg
$(FSG_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $(FSG_MOUNT_POINT)"
	@mkdir -p $(TARGET_OUT_VENDOR)/fsg

ALL_DEFAULT_INSTALLED_MODULES += $(FIRMWARE_MOUNT_POINT) $(BT_FIRMWARE_MOUNT_POINT) $(DSP_MOUNT_POINT) $(FSG_MOUNT_POINT)

IMS_LIBS := libimscamera_jni.so libimsmedia_jni.so
IMS_SYMLINKS := $(addprefix $(TARGET_OUT_SYSTEM_EXT_APPS_PRIVILEGED)/ims/lib/arm64/,$(notdir $(IMS_LIBS)))
$(IMS_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "IMS lib link: $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /system_ext/lib64/$(notdir $@) $@

ALL_DEFAULT_INSTALLED_MODULES += $(IMS_SYMLINKS)

WIFI_FIRMWARE_SYMLINKS := $(TARGET_OUT_VENDOR)/firmware/wlan/qca_cld
$(WIFI_FIRMWARE_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating wifi firmware symlinks: $@"
	@mkdir -p $@
	$(hide) ln -sf /vendor/etc/wifi/WCNSS_qcom_cfg.ini $@/WCNSS_qcom_cfg.ini
	$(hide) ln -sf /mnt/vendor/persist/wlan_mac.bin $@/wlan_mac.bin

ALL_DEFAULT_INSTALLED_MODULES += $(WIFI_FIRMWARE_SYMLINKS)

CNE_SYMLINKS := $(TARGET_OUT_VENDOR_APPS)/CneApp/lib/arm64/libvndfwk_detect_jni.qti.so
$(CNE_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "CneApp lib link: $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /vendor/lib64/$(notdir $@) $@

ALL_DEFAULT_INSTALLED_MODULES += $(CNE_SYMLINKS)

EXPAT_SYMLINKS := $(TARGET_OUT_VENDOR_EXECUTABLES)/expat
$(EXPAT_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Expat bin link: $@"
	@rm -rf $@
	@mkdir -p $(dir $@)
	$(hide) ln -sf motobox $@

ALL_DEFAULT_INSTALLED_MODULES += $(EXPAT_SYMLINKS)

AW882XX_CAL_SYMLINKS := $(TARGET_OUT_VENDOR)/firmware/aw_cali.bin
$(AW882XX_CAL_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating aw882xx firmware symlinks: $@"
	@rm -rf $@
	@mkdir -p $(dir $@)
	$(hide) ln -sf /mnt/vendor/persist/factory/audio/aw_cali.bin $@

ALL_DEFAULT_INSTALLED_MODULES += $(AW882XX_CAL_SYMLINKS)

endif
