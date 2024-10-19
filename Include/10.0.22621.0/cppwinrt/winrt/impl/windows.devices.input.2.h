// C++/WinRT v2.0.220110.5

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#pragma once
#ifndef WINRT_Windows_Devices_Input_2_H
#define WINRT_Windows_Devices_Input_2_H
#include "winrt/impl/Windows.Devices.Input.1.h"
WINRT_EXPORT namespace winrt::Windows::Devices::Input
{
    struct MouseDelta
    {
        int32_t X;
        int32_t Y;
    };
    inline bool operator==(MouseDelta const& left, MouseDelta const& right) noexcept
    {
        return left.X == right.X && left.Y == right.Y;
    }
    inline bool operator!=(MouseDelta const& left, MouseDelta const& right) noexcept
    {
        return !(left == right);
    }
    struct PointerDeviceUsage
    {
        uint32_t UsagePage;
        uint32_t Usage;
        int32_t MinLogical;
        int32_t MaxLogical;
        int32_t MinPhysical;
        int32_t MaxPhysical;
        uint32_t Unit;
        float PhysicalMultiplier;
    };
    inline bool operator==(PointerDeviceUsage const& left, PointerDeviceUsage const& right) noexcept
    {
        return left.UsagePage == right.UsagePage && left.Usage == right.Usage && left.MinLogical == right.MinLogical && left.MaxLogical == right.MaxLogical && left.MinPhysical == right.MinPhysical && left.MaxPhysical == right.MaxPhysical && left.Unit == right.Unit && left.PhysicalMultiplier == right.PhysicalMultiplier;
    }
    inline bool operator!=(PointerDeviceUsage const& left, PointerDeviceUsage const& right) noexcept
    {
        return !(left == right);
    }
    struct __declspec(empty_bases) KeyboardCapabilities : winrt::Windows::Devices::Input::IKeyboardCapabilities
    {
        KeyboardCapabilities(std::nullptr_t) noexcept {}
        KeyboardCapabilities(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IKeyboardCapabilities(ptr, take_ownership_from_abi) {}
        KeyboardCapabilities();
    };
    struct __declspec(empty_bases) MouseCapabilities : winrt::Windows::Devices::Input::IMouseCapabilities
    {
        MouseCapabilities(std::nullptr_t) noexcept {}
        MouseCapabilities(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IMouseCapabilities(ptr, take_ownership_from_abi) {}
        MouseCapabilities();
    };
    struct __declspec(empty_bases) MouseDevice : winrt::Windows::Devices::Input::IMouseDevice
    {
        MouseDevice(std::nullptr_t) noexcept {}
        MouseDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IMouseDevice(ptr, take_ownership_from_abi) {}
        static auto GetForCurrentView();
    };
    struct __declspec(empty_bases) MouseEventArgs : winrt::Windows::Devices::Input::IMouseEventArgs
    {
        MouseEventArgs(std::nullptr_t) noexcept {}
        MouseEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IMouseEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PenButtonListener : winrt::Windows::Devices::Input::IPenButtonListener
    {
        PenButtonListener(std::nullptr_t) noexcept {}
        PenButtonListener(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenButtonListener(ptr, take_ownership_from_abi) {}
        static auto GetDefault();
    };
    struct __declspec(empty_bases) PenDevice : winrt::Windows::Devices::Input::IPenDevice,
        impl::require<PenDevice, winrt::Windows::Devices::Input::IPenDevice2>
    {
        PenDevice(std::nullptr_t) noexcept {}
        PenDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenDevice(ptr, take_ownership_from_abi) {}
        static auto GetFromPointerId(uint32_t pointerId);
    };
    struct __declspec(empty_bases) PenDockListener : winrt::Windows::Devices::Input::IPenDockListener
    {
        PenDockListener(std::nullptr_t) noexcept {}
        PenDockListener(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenDockListener(ptr, take_ownership_from_abi) {}
        static auto GetDefault();
    };
    struct __declspec(empty_bases) PenDockedEventArgs : winrt::Windows::Devices::Input::IPenDockedEventArgs
    {
        PenDockedEventArgs(std::nullptr_t) noexcept {}
        PenDockedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenDockedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PenTailButtonClickedEventArgs : winrt::Windows::Devices::Input::IPenTailButtonClickedEventArgs
    {
        PenTailButtonClickedEventArgs(std::nullptr_t) noexcept {}
        PenTailButtonClickedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenTailButtonClickedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PenTailButtonDoubleClickedEventArgs : winrt::Windows::Devices::Input::IPenTailButtonDoubleClickedEventArgs
    {
        PenTailButtonDoubleClickedEventArgs(std::nullptr_t) noexcept {}
        PenTailButtonDoubleClickedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenTailButtonDoubleClickedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PenTailButtonLongPressedEventArgs : winrt::Windows::Devices::Input::IPenTailButtonLongPressedEventArgs
    {
        PenTailButtonLongPressedEventArgs(std::nullptr_t) noexcept {}
        PenTailButtonLongPressedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenTailButtonLongPressedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PenUndockedEventArgs : winrt::Windows::Devices::Input::IPenUndockedEventArgs
    {
        PenUndockedEventArgs(std::nullptr_t) noexcept {}
        PenUndockedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPenUndockedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PointerDevice : winrt::Windows::Devices::Input::IPointerDevice,
        impl::require<PointerDevice, winrt::Windows::Devices::Input::IPointerDevice2>
    {
        PointerDevice(std::nullptr_t) noexcept {}
        PointerDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::IPointerDevice(ptr, take_ownership_from_abi) {}
        static auto GetPointerDevice(uint32_t pointerId);
        static auto GetPointerDevices();
    };
    struct __declspec(empty_bases) TouchCapabilities : winrt::Windows::Devices::Input::ITouchCapabilities
    {
        TouchCapabilities(std::nullptr_t) noexcept {}
        TouchCapabilities(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Devices::Input::ITouchCapabilities(ptr, take_ownership_from_abi) {}
        TouchCapabilities();
    };
}
#endif
