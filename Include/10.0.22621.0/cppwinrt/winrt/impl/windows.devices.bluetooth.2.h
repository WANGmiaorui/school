// C++/WinRT v2.0.220110.5

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#pragma once
#ifndef WINRT_Windows_Devices_Bluetooth_2_H
#define WINRT_Windows_Devices_Bluetooth_2_H
#include "winrt/impl/Windows.Foundation.1.h"
#include "winrt/impl/Windows.Networking.1.h"
#include "winrt/impl/Windows.Devices.Bluetooth.1.h"
WINRT_EXPORT namespace winrt::Windows::Devices::Bluetooth
{
    struct __declspec(empty_bases) BluetoothAdapter : winrt::Windows::Devices::Bluetooth::IBluetoothAdapter,
        impl::require<BluetoothAdapter, winrt::Windows::Devices::Bluetooth::IBluetoothAdapter2, winrt::Windows::Devices::Bluetooth::IBluetoothAdapter3>
    {
        BluetoothAdapter(std::nullptr_t) noexcept {}
        BluetoothAdapter(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothAdapter(ptr, take_ownership_from_abi) {}
        static auto GetDeviceSelector();
        static auto FromIdAsync(param::hstring const& deviceId);
        static auto GetDefaultAsync();
    };
    struct __declspec(empty_bases) BluetoothClassOfDevice : winrt::Windows::Devices::Bluetooth::IBluetoothClassOfDevice
    {
        BluetoothClassOfDevice(std::nullptr_t) noexcept {}
        BluetoothClassOfDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothClassOfDevice(ptr, take_ownership_from_abi) {}
        static auto FromRawValue(uint32_t rawValue);
        static auto FromParts(winrt::Windows::Devices::Bluetooth::BluetoothMajorClass const& majorClass, winrt::Windows::Devices::Bluetooth::BluetoothMinorClass const& minorClass, winrt::Windows::Devices::Bluetooth::BluetoothServiceCapabilities const& serviceCapabilities);
    };
    struct __declspec(empty_bases) BluetoothDevice : winrt::Windows::Devices::Bluetooth::IBluetoothDevice,
        impl::require<BluetoothDevice, winrt::Windows::Devices::Bluetooth::IBluetoothDevice2, winrt::Windows::Devices::Bluetooth::IBluetoothDevice3, winrt::Windows::Devices::Bluetooth::IBluetoothDevice4, winrt::Windows::Devices::Bluetooth::IBluetoothDevice5, winrt::Windows::Foundation::IClosable>
    {
        BluetoothDevice(std::nullptr_t) noexcept {}
        BluetoothDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothDevice(ptr, take_ownership_from_abi) {}
        static auto FromIdAsync(param::hstring const& deviceId);
        static auto FromHostNameAsync(winrt::Windows::Networking::HostName const& hostName);
        static auto FromBluetoothAddressAsync(uint64_t address);
        static auto GetDeviceSelector();
        static auto GetDeviceSelectorFromPairingState(bool pairingState);
        static auto GetDeviceSelectorFromConnectionStatus(winrt::Windows::Devices::Bluetooth::BluetoothConnectionStatus const& connectionStatus);
        static auto GetDeviceSelectorFromDeviceName(param::hstring const& deviceName);
        static auto GetDeviceSelectorFromBluetoothAddress(uint64_t bluetoothAddress);
        static auto GetDeviceSelectorFromClassOfDevice(winrt::Windows::Devices::Bluetooth::BluetoothClassOfDevice const& classOfDevice);
    };
    struct __declspec(empty_bases) BluetoothDeviceId : winrt::Windows::Devices::Bluetooth::IBluetoothDeviceId
    {
        BluetoothDeviceId(std::nullptr_t) noexcept {}
        BluetoothDeviceId(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothDeviceId(ptr, take_ownership_from_abi) {}
        static auto FromId(param::hstring const& deviceId);
    };
    struct __declspec(empty_bases) BluetoothLEAppearance : winrt::Windows::Devices::Bluetooth::IBluetoothLEAppearance
    {
        BluetoothLEAppearance(std::nullptr_t) noexcept {}
        BluetoothLEAppearance(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEAppearance(ptr, take_ownership_from_abi) {}
        static auto FromRawValue(uint16_t rawValue);
        static auto FromParts(uint16_t appearanceCategory, uint16_t appearanceSubCategory);
    };
    struct BluetoothLEAppearanceCategories
    {
        BluetoothLEAppearanceCategories() = delete;
        [[nodiscard]] static auto Uncategorized();
        [[nodiscard]] static auto Phone();
        [[nodiscard]] static auto Computer();
        [[nodiscard]] static auto Watch();
        [[nodiscard]] static auto Clock();
        [[nodiscard]] static auto Display();
        [[nodiscard]] static auto RemoteControl();
        [[nodiscard]] static auto EyeGlasses();
        [[nodiscard]] static auto Tag();
        [[nodiscard]] static auto Keyring();
        [[nodiscard]] static auto MediaPlayer();
        [[nodiscard]] static auto BarcodeScanner();
        [[nodiscard]] static auto Thermometer();
        [[nodiscard]] static auto HeartRate();
        [[nodiscard]] static auto BloodPressure();
        [[nodiscard]] static auto HumanInterfaceDevice();
        [[nodiscard]] static auto GlucoseMeter();
        [[nodiscard]] static auto RunningWalking();
        [[nodiscard]] static auto Cycling();
        [[nodiscard]] static auto PulseOximeter();
        [[nodiscard]] static auto WeightScale();
        [[nodiscard]] static auto OutdoorSportActivity();
    };
    struct BluetoothLEAppearanceSubcategories
    {
        BluetoothLEAppearanceSubcategories() = delete;
        [[nodiscard]] static auto Generic();
        [[nodiscard]] static auto SportsWatch();
        [[nodiscard]] static auto ThermometerEar();
        [[nodiscard]] static auto HeartRateBelt();
        [[nodiscard]] static auto BloodPressureArm();
        [[nodiscard]] static auto BloodPressureWrist();
        [[nodiscard]] static auto Keyboard();
        [[nodiscard]] static auto Mouse();
        [[nodiscard]] static auto Joystick();
        [[nodiscard]] static auto Gamepad();
        [[nodiscard]] static auto DigitizerTablet();
        [[nodiscard]] static auto CardReader();
        [[nodiscard]] static auto DigitalPen();
        [[nodiscard]] static auto BarcodeScanner();
        [[nodiscard]] static auto RunningWalkingInShoe();
        [[nodiscard]] static auto RunningWalkingOnShoe();
        [[nodiscard]] static auto RunningWalkingOnHip();
        [[nodiscard]] static auto CyclingComputer();
        [[nodiscard]] static auto CyclingSpeedSensor();
        [[nodiscard]] static auto CyclingCadenceSensor();
        [[nodiscard]] static auto CyclingPowerSensor();
        [[nodiscard]] static auto CyclingSpeedCadenceSensor();
        [[nodiscard]] static auto OximeterFingertip();
        [[nodiscard]] static auto OximeterWristWorn();
        [[nodiscard]] static auto LocationDisplay();
        [[nodiscard]] static auto LocationNavigationDisplay();
        [[nodiscard]] static auto LocationPod();
        [[nodiscard]] static auto LocationNavigationPod();
    };
    struct __declspec(empty_bases) BluetoothLEConnectionParameters : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionParameters
    {
        BluetoothLEConnectionParameters(std::nullptr_t) noexcept {}
        BluetoothLEConnectionParameters(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionParameters(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) BluetoothLEConnectionPhy : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionPhy
    {
        BluetoothLEConnectionPhy(std::nullptr_t) noexcept {}
        BluetoothLEConnectionPhy(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionPhy(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) BluetoothLEConnectionPhyInfo : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionPhyInfo
    {
        BluetoothLEConnectionPhyInfo(std::nullptr_t) noexcept {}
        BluetoothLEConnectionPhyInfo(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEConnectionPhyInfo(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) BluetoothLEDevice : winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice,
        impl::require<BluetoothLEDevice, winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice2, winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice3, winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice4, winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice5, winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice6, winrt::Windows::Foundation::IClosable>
    {
        BluetoothLEDevice(std::nullptr_t) noexcept {}
        BluetoothLEDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEDevice(ptr, take_ownership_from_abi) {}
        static auto FromIdAsync(param::hstring const& deviceId);
        static auto FromBluetoothAddressAsync(uint64_t bluetoothAddress);
        static auto GetDeviceSelector();
        static auto GetDeviceSelectorFromPairingState(bool pairingState);
        static auto GetDeviceSelectorFromConnectionStatus(winrt::Windows::Devices::Bluetooth::BluetoothConnectionStatus const& connectionStatus);
        static auto GetDeviceSelectorFromDeviceName(param::hstring const& deviceName);
        static auto GetDeviceSelectorFromBluetoothAddress(uint64_t bluetoothAddress);
        static auto GetDeviceSelectorFromBluetoothAddress(uint64_t bluetoothAddress, winrt::Windows::Devices::Bluetooth::BluetoothAddressType const& bluetoothAddressType);
        static auto GetDeviceSelectorFromAppearance(winrt::Windows::Devices::Bluetooth::BluetoothLEAppearance const& appearance);
        static auto FromBluetoothAddressAsync(uint64_t bluetoothAddress, winrt::Windows::Devices::Bluetooth::BluetoothAddressType const& bluetoothAddressType);
    };
    struct __declspec(empty_bases) BluetoothLEPreferredConnectionParameters : winrt::Windows::Devices::Bluetooth::IBluetoothLEPreferredConnectionParameters
    {
        BluetoothLEPreferredConnectionParameters(std::nullptr_t) noexcept {}
        BluetoothLEPreferredConnectionParameters(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEPreferredConnectionParameters(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto Balanced();
        [[nodiscard]] static auto ThroughputOptimized();
        [[nodiscard]] static auto PowerOptimized();
    };
    struct __declspec(empty_bases) BluetoothLEPreferredConnectionParametersRequest : winrt::Windows::Devices::Bluetooth::IBluetoothLEPreferredConnectionParametersRequest,
        impl::require<BluetoothLEPreferredConnectionParametersRequest, winrt::Windows::Foundation::IClosable>
    {
        BluetoothLEPreferredConnectionParametersRequest(std::nullptr_t) noexcept {}
        BluetoothLEPreferredConnectionParametersRequest(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothLEPreferredConnectionParametersRequest(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) BluetoothSignalStrengthFilter : winrt::Windows::Devices::Bluetooth::IBluetoothSignalStrengthFilter
    {
        BluetoothSignalStrengthFilter(std::nullptr_t) noexcept {}
        BluetoothSignalStrengthFilter(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Bluetooth::IBluetoothSignalStrengthFilter(ptr, take_ownership_from_abi) {}
        BluetoothSignalStrengthFilter();
    };
    struct BluetoothUuidHelper
    {
        BluetoothUuidHelper() = delete;
        static auto FromShortId(uint32_t shortId);
        static auto TryGetShortId(winrt::guid const& uuid);
    };
}
#endif
