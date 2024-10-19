// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_ApplicationModel_Resources_H
#define WINRT_Windows_ApplicationModel_Resources_H
#include "winrt/base.h"
static_assert(winrt::check_version(CPPWINRT_VERSION, "2.0.190620.2"), "Mismatched C++/WinRT headers.");
#include "winrt/Windows.ApplicationModel.h"
#include "winrt/impl/Windows.Foundation.2.h"
#include "winrt/impl/Windows.UI.2.h"
#include "winrt/impl/Windows.ApplicationModel.Resources.2.h"
namespace winrt::impl
{
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoader<D>::GetString(param::hstring const& resource) const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoader)->GetString(*(void**)(&resource), &value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoader2<D>::GetStringForUri(Windows::Foundation::Uri const& uri) const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoader2)->GetStringForUri(*(void**)(&uri), &value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderFactory<D>::CreateResourceLoaderByName(param::hstring const& name) const
    {
        void* loader{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderFactory)->CreateResourceLoaderByName(*(void**)(&name), &loader));
        return Windows::ApplicationModel::Resources::ResourceLoader{ loader, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics<D>::GetStringForReference(Windows::Foundation::Uri const& uri) const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics)->GetStringForReference(*(void**)(&uri), &value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics2<D>::GetForCurrentView() const
    {
        void* loader{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics2)->GetForCurrentView(&loader));
        return Windows::ApplicationModel::Resources::ResourceLoader{ loader, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics2<D>::GetForCurrentView(param::hstring const& name) const
    {
        void* loader{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics2)->GetForCurrentViewWithName(*(void**)(&name), &loader));
        return Windows::ApplicationModel::Resources::ResourceLoader{ loader, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics2<D>::GetForViewIndependentUse() const
    {
        void* loader{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics2)->GetForViewIndependentUse(&loader));
        return Windows::ApplicationModel::Resources::ResourceLoader{ loader, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics2<D>::GetForViewIndependentUse(param::hstring const& name) const
    {
        void* loader{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics2)->GetForViewIndependentUseWithName(*(void**)(&name), &loader));
        return Windows::ApplicationModel::Resources::ResourceLoader{ loader, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_ApplicationModel_Resources_IResourceLoaderStatics3<D>::GetForUIContext(Windows::UI::UIContext const& context) const
    {
        void* result{};
        check_hresult(WINRT_IMPL_SHIM(Windows::ApplicationModel::Resources::IResourceLoaderStatics3)->GetForUIContext(*(void**)(&context), &result));
        return Windows::ApplicationModel::Resources::ResourceLoader{ result, take_ownership_from_abi };
    }
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoader> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoader>
    {
        int32_t __stdcall GetString(void* resource, void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().GetString(*reinterpret_cast<hstring const*>(&resource)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoader2> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoader2>
    {
        int32_t __stdcall GetStringForUri(void* uri, void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().GetStringForUri(*reinterpret_cast<Windows::Foundation::Uri const*>(&uri)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoaderFactory> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoaderFactory>
    {
        int32_t __stdcall CreateResourceLoaderByName(void* name, void** loader) noexcept final try
        {
            clear_abi(loader);
            typename D::abi_guard guard(this->shim());
            *loader = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().CreateResourceLoaderByName(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics>
    {
        int32_t __stdcall GetStringForReference(void* uri, void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().GetStringForReference(*reinterpret_cast<Windows::Foundation::Uri const*>(&uri)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics2> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics2>
    {
        int32_t __stdcall GetForCurrentView(void** loader) noexcept final try
        {
            clear_abi(loader);
            typename D::abi_guard guard(this->shim());
            *loader = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().GetForCurrentView());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetForCurrentViewWithName(void* name, void** loader) noexcept final try
        {
            clear_abi(loader);
            typename D::abi_guard guard(this->shim());
            *loader = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().GetForCurrentView(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetForViewIndependentUse(void** loader) noexcept final try
        {
            clear_abi(loader);
            typename D::abi_guard guard(this->shim());
            *loader = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().GetForViewIndependentUse());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetForViewIndependentUseWithName(void* name, void** loader) noexcept final try
        {
            clear_abi(loader);
            typename D::abi_guard guard(this->shim());
            *loader = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().GetForViewIndependentUse(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics3> : produce_base<D, Windows::ApplicationModel::Resources::IResourceLoaderStatics3>
    {
        int32_t __stdcall GetForUIContext(void* context, void** result) noexcept final try
        {
            clear_abi(result);
            typename D::abi_guard guard(this->shim());
            *result = detach_from<Windows::ApplicationModel::Resources::ResourceLoader>(this->shim().GetForUIContext(*reinterpret_cast<Windows::UI::UIContext const*>(&context)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
}
namespace winrt::Windows::ApplicationModel::Resources
{
    inline ResourceLoader::ResourceLoader() :
        ResourceLoader(impl::call_factory<ResourceLoader>([](auto&& f) { return f.template ActivateInstance<ResourceLoader>(); }))
    {
    }
    inline ResourceLoader::ResourceLoader(param::hstring const& name) :
        ResourceLoader(impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderFactory>([&](auto&& f) { return f.CreateResourceLoaderByName(name); }))
    {
    }
    inline auto ResourceLoader::GetStringForReference(Windows::Foundation::Uri const& uri)
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics>([&](auto&& f) { return f.GetStringForReference(uri); });
    }
    inline auto ResourceLoader::GetForCurrentView()
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics2>([&](auto&& f) { return f.GetForCurrentView(); });
    }
    inline auto ResourceLoader::GetForCurrentView(param::hstring const& name)
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics2>([&](auto&& f) { return f.GetForCurrentView(name); });
    }
    inline auto ResourceLoader::GetForViewIndependentUse()
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics2>([&](auto&& f) { return f.GetForViewIndependentUse(); });
    }
    inline auto ResourceLoader::GetForViewIndependentUse(param::hstring const& name)
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics2>([&](auto&& f) { return f.GetForViewIndependentUse(name); });
    }
    inline auto ResourceLoader::GetForUIContext(Windows::UI::UIContext const& context)
    {
        return impl::call_factory<ResourceLoader, Windows::ApplicationModel::Resources::IResourceLoaderStatics3>([&](auto&& f) { return f.GetForUIContext(context); });
    }
}
namespace std
{
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoader> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoader> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoader2> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoader2> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoaderFactory> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoaderFactory> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics2> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics2> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics3> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::IResourceLoaderStatics3> {};
    template<> struct hash<winrt::Windows::ApplicationModel::Resources::ResourceLoader> : winrt::impl::hash_base<winrt::Windows::ApplicationModel::Resources::ResourceLoader> {};
}
#endif
