// C++/WinRT v2.0.220110.5

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#pragma once
#ifndef WINRT_Windows_Networking_Proximity_2_H
#define WINRT_Windows_Networking_Proximity_2_H
#include "winrt/impl/Windows.Foundation.1.h"
#include "winrt/impl/Windows.Storage.Streams.1.h"
#include "winrt/impl/Windows.Networking.Proximity.1.h"
WINRT_EXPORT namespace winrt::Windows::Networking::Proximity
{
    struct DeviceArrivedEventHandler : winrt::Windows::Foundation::IUnknown
    {
        DeviceArrivedEventHandler(std::nullptr_t = nullptr) noexcept {}
        DeviceArrivedEventHandler(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> DeviceArrivedEventHandler(L lambda);
        template <typename F> DeviceArrivedEventHandler(F* function);
        template <typename O, typename M> DeviceArrivedEventHandler(O* object, M method);
        template <typename O, typename M> DeviceArrivedEventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> DeviceArrivedEventHandler(weak_ref<O>&& object, M method);
        auto operator()(winrt::Windows::Networking::Proximity::ProximityDevice const& sender) const;
    };
    struct DeviceDepartedEventHandler : winrt::Windows::Foundation::IUnknown
    {
        DeviceDepartedEventHandler(std::nullptr_t = nullptr) noexcept {}
        DeviceDepartedEventHandler(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> DeviceDepartedEventHandler(L lambda);
        template <typename F> DeviceDepartedEventHandler(F* function);
        template <typename O, typename M> DeviceDepartedEventHandler(O* object, M method);
        template <typename O, typename M> DeviceDepartedEventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> DeviceDepartedEventHandler(weak_ref<O>&& object, M method);
        auto operator()(winrt::Windows::Networking::Proximity::ProximityDevice const& sender) const;
    };
    struct MessageReceivedHandler : winrt::Windows::Foundation::IUnknown
    {
        MessageReceivedHandler(std::nullptr_t = nullptr) noexcept {}
        MessageReceivedHandler(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> MessageReceivedHandler(L lambda);
        template <typename F> MessageReceivedHandler(F* function);
        template <typename O, typename M> MessageReceivedHandler(O* object, M method);
        template <typename O, typename M> MessageReceivedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> MessageReceivedHandler(weak_ref<O>&& object, M method);
        auto operator()(winrt::Windows::Networking::Proximity::ProximityDevice const& sender, winrt::Windows::Networking::Proximity::ProximityMessage const& message) const;
    };
    struct MessageTransmittedHandler : winrt::Windows::Foundation::IUnknown
    {
        MessageTransmittedHandler(std::nullptr_t = nullptr) noexcept {}
        MessageTransmittedHandler(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> MessageTransmittedHandler(L lambda);
        template <typename F> MessageTransmittedHandler(F* function);
        template <typename O, typename M> MessageTransmittedHandler(O* object, M method);
        template <typename O, typename M> MessageTransmittedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> MessageTransmittedHandler(weak_ref<O>&& object, M method);
        auto operator()(winrt::Windows::Networking::Proximity::ProximityDevice const& sender, int64_t messageId) const;
    };
    struct __declspec(empty_bases) ConnectionRequestedEventArgs : winrt::Windows::Networking::Proximity::IConnectionRequestedEventArgs
    {
        ConnectionRequestedEventArgs(std::nullptr_t) noexcept {}
        ConnectionRequestedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::IConnectionRequestedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct PeerFinder
    {
        PeerFinder() = delete;
        [[nodiscard]] static auto AllowBluetooth();
        static auto AllowBluetooth(bool value);
        [[nodiscard]] static auto AllowInfrastructure();
        static auto AllowInfrastructure(bool value);
        [[nodiscard]] static auto AllowWiFiDirect();
        static auto AllowWiFiDirect(bool value);
        [[nodiscard]] static auto DisplayName();
        static auto DisplayName(param::hstring const& value);
        [[nodiscard]] static auto SupportedDiscoveryTypes();
        [[nodiscard]] static auto AlternateIdentities();
        static auto Start();
        static auto Start(param::hstring const& peerMessage);
        static auto Stop();
        static auto TriggeredConnectionStateChanged(winrt::Windows::Foundation::TypedEventHandler<winrt::Windows::Foundation::IInspectable, winrt::Windows::Networking::Proximity::TriggeredConnectionStateChangedEventArgs> const& handler);
        using TriggeredConnectionStateChanged_revoker = impl::factory_event_revoker<winrt::Windows::Networking::Proximity::IPeerFinderStatics, &impl::abi_t<winrt::Windows::Networking::Proximity::IPeerFinderStatics>::remove_TriggeredConnectionStateChanged>;
        [[nodiscard]] static TriggeredConnectionStateChanged_revoker TriggeredConnectionStateChanged(auto_revoke_t, winrt::Windows::Foundation::TypedEventHandler<winrt::Windows::Foundation::IInspectable, winrt::Windows::Networking::Proximity::TriggeredConnectionStateChangedEventArgs> const& handler);
        static auto TriggeredConnectionStateChanged(winrt::event_token const& cookie);
        static auto ConnectionRequested(winrt::Windows::Foundation::TypedEventHandler<winrt::Windows::Foundation::IInspectable, winrt::Windows::Networking::Proximity::ConnectionRequestedEventArgs> const& handler);
        using ConnectionRequested_revoker = impl::factory_event_revoker<winrt::Windows::Networking::Proximity::IPeerFinderStatics, &impl::abi_t<winrt::Windows::Networking::Proximity::IPeerFinderStatics>::remove_ConnectionRequested>;
        [[nodiscard]] static ConnectionRequested_revoker ConnectionRequested(auto_revoke_t, winrt::Windows::Foundation::TypedEventHandler<winrt::Windows::Foundation::IInspectable, winrt::Windows::Networking::Proximity::ConnectionRequestedEventArgs> const& handler);
        static auto ConnectionRequested(winrt::event_token const& cookie);
        static auto FindAllPeersAsync();
        static auto ConnectAsync(winrt::Windows::Networking::Proximity::PeerInformation const& peerInformation);
        [[nodiscard]] static auto Role();
        static auto Role(winrt::Windows::Networking::Proximity::PeerRole const& value);
        [[nodiscard]] static auto DiscoveryData();
        static auto DiscoveryData(winrt::Windows::Storage::Streams::IBuffer const& value);
        static auto CreateWatcher();
    };
    struct __declspec(empty_bases) PeerInformation : winrt::Windows::Networking::Proximity::IPeerInformation,
        impl::require<PeerInformation, winrt::Windows::Networking::Proximity::IPeerInformation3, winrt::Windows::Networking::Proximity::IPeerInformationWithHostAndService>
    {
        PeerInformation(std::nullptr_t) noexcept {}
        PeerInformation(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::IPeerInformation(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PeerWatcher : winrt::Windows::Networking::Proximity::IPeerWatcher
    {
        PeerWatcher(std::nullptr_t) noexcept {}
        PeerWatcher(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::IPeerWatcher(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ProximityDevice : winrt::Windows::Networking::Proximity::IProximityDevice
    {
        ProximityDevice(std::nullptr_t) noexcept {}
        ProximityDevice(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::IProximityDevice(ptr, take_ownership_from_abi) {}
        static auto GetDeviceSelector();
        static auto GetDefault();
        static auto FromId(param::hstring const& deviceId);
    };
    struct __declspec(empty_bases) ProximityMessage : winrt::Windows::Networking::Proximity::IProximityMessage
    {
        ProximityMessage(std::nullptr_t) noexcept {}
        ProximityMessage(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::IProximityMessage(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) TriggeredConnectionStateChangedEventArgs : winrt::Windows::Networking::Proximity::ITriggeredConnectionStateChangedEventArgs
    {
        TriggeredConnectionStateChangedEventArgs(std::nullptr_t) noexcept {}
        TriggeredConnectionStateChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : winrt::Windows::Networking::Proximity::ITriggeredConnectionStateChangedEventArgs(ptr, take_ownership_from_abi) {}
    };
}
#endif
