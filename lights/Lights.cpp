/*
 * Copyright (C) 2019 The Android Open Source Project
 * Copyright (C) 2023 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "Lights.h"
#include <android-base/file.h>
#include <android-base/logging.h>
#include <thread>

/* clang-format off */
#define PPCAT_NX(A, B) A/B
#define PPCAT(A, B) PPCAT_NX(A, B)
#define STRINGIFY_INNER(x) #x
#define STRINGIFY(x) STRINGIFY_INNER(x)

#define CHARGING_ATTR(x) STRINGIFY(PPCAT(/sys/class/leds/charging, x))
/* clang-format on */

namespace aidl {
namespace android {
namespace hardware {
namespace light {

namespace {

using ::android::base::WriteStringToFile;

// Write value to path and close file.
template <typename T>
inline bool WriteToFile(const std::string& path, T content) {
    return WriteStringToFile(std::to_string(content), path);
}

uint32_t RgbaToBrightness(uint32_t color) {
    // Extract brightness from AARRGGBB.
    uint32_t alpha = (color >> 24) & 0xFF;

    // Retrieve each of the RGB colors
    uint32_t red = (color >> 16) & 0xFF;
    uint32_t green = (color >> 8) & 0xFF;
    uint32_t blue = color & 0xFF;

    // Scale RGB colors if a brightness has been applied by the user
    if (alpha != 0xFF && alpha != 0) {
        red = red * alpha / 0xFF;
        green = green * alpha / 0xFF;
        blue = blue * alpha / 0xFF;
    }

    return (77 * red + 150 * green + 29 * blue) >> 8;
}

inline bool IsLit(uint32_t color) {
    return color & 0x00ffffff;
}

void ApplyNotificationState(const HwLightState& state) {
    bool ok = false;
    uint32_t brightness = RgbaToBrightness(state.color);

    switch (state.flashMode) {
        case FlashMode::HARDWARE:
        case FlashMode::TIMED:
            ok = WriteStringToFile("timer", CHARGING_ATTR(trigger));
            if (ok) {
                using namespace std::chrono_literals;
                auto retries = 20;
                while (retries--) {
                    std::this_thread::sleep_for(2ms);

                    ok = WriteToFile(CHARGING_ATTR(delay_off), state.flashOffMs);
                    if (!ok) continue;

                    ok = WriteToFile(CHARGING_ATTR(delay_on), state.flashOnMs);
                    if (ok) break;
                }
                LOG(DEBUG) << __func__
                    << ": number of tries to write delay: " << (20 - retries);
            }
            if (ok) break;
            // fallback to constant on if timed blinking is not supported
            LOG(INFO) << __func__
                << ": fallthrough FlashMode::TIMED to FlashMode::NONE.";
            FALLTHROUGH_INTENDED;
        case FlashMode::NONE:
        default:
            ok = WriteToFile(CHARGING_ATTR(brightness), brightness);
            break;
    }

    LOG(DEBUG) << __func__
               << ": mode=" << toString(state.flashMode) << ", colorRGB=" << std::hex
               << state.color << std::dec << ", onMS=" << state.flashOnMs
               << ", offMS=" << state.flashOffMs << ", ok=" << ok
               << ", brightnessMode=" << toString(state.brightnessMode);
}

}  // anonymous namespace

ndk::ScopedAStatus Lights::setLightState(int id, const HwLightState& state) {
    static_assert(kAvailableLights.size() == std::tuple_size_v<decltype(notif_states_)>);

    if (id == static_cast<int32_t>(LightType::BACKLIGHT)) {
        // Stub backlight handling
        return ndk::ScopedAStatus::ok();
    }

    // Update saved state first
    bool found = false;
    for (size_t i = 0; i < notif_states_.size(); ++i) {
        if (kAvailableLights[i].id == id) {
            notif_states_[i] = state;
            found = true;
            break;
        }
    }
    if (!found) {
        LOG(ERROR) << " Light not supported";
        return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }

    // Lit up in order or fallback to battery light if others are dim
    for (size_t i = 0; i < notif_states_.size(); ++i) {
        auto&& cur_state = notif_states_[i];
        auto&& cur_light = kAvailableLights[i];
        if (IsLit(cur_state.color) || cur_light.type == LightType::BATTERY) {
            ApplyNotificationState(cur_state);
            break;
        }
    }

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Lights::getLights(std::vector<HwLight>* lights) {
    lights->insert(lights->end(), kAvailableLights.begin(), kAvailableLights.end());
    // We don't handle backlight but still need to report as supported.
    lights->push_back({static_cast<int32_t>(LightType::BACKLIGHT), 2, LightType::BACKLIGHT});
    return ndk::ScopedAStatus::ok();
}

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
