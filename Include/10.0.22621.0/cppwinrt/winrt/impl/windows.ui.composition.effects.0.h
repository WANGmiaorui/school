// C++/WinRT v2.0.220110.5

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#pragma once
#ifndef WINRT_Windows_UI_Composition_Effects_0_H
#define WINRT_Windows_UI_Composition_Effects_0_H
WINRT_EXPORT namespace winrt::Windows::Graphics::Effects
{
    struct IGraphicsEffectSource;
}
WINRT_EXPORT namespace winrt::Windows::UI::Composition::Effects
{
    enum class SceneLightingEffectReflectanceModel : int32_t
    {
        BlinnPhong = 0,
        PhysicallyBasedBlinnPhong = 1,
    };
    struct ISceneLightingEffect;
    struct ISceneLightingEffect2;
    struct SceneLightingEffect;
}
namespace winrt::impl
{
    template <> struct category<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect>{ using type = interface_category; };
    template <> struct category<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect2>{ using type = interface_category; };
    template <> struct category<winrt::Windows::UI::Composition::Effects::SceneLightingEffect>{ using type = class_category; };
    template <> struct category<winrt::Windows::UI::Composition::Effects::SceneLightingEffectReflectanceModel>{ using type = enum_category; };
    template <> inline constexpr auto& name_v<winrt::Windows::UI::Composition::Effects::SceneLightingEffect> = L"Windows.UI.Composition.Effects.SceneLightingEffect";
    template <> inline constexpr auto& name_v<winrt::Windows::UI::Composition::Effects::SceneLightingEffectReflectanceModel> = L"Windows.UI.Composition.Effects.SceneLightingEffectReflectanceModel";
    template <> inline constexpr auto& name_v<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect> = L"Windows.UI.Composition.Effects.ISceneLightingEffect";
    template <> inline constexpr auto& name_v<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect2> = L"Windows.UI.Composition.Effects.ISceneLightingEffect2";
    template <> inline constexpr guid guid_v<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect>{ 0x91BB5E52,0x95D1,0x4F8B,{ 0x9A,0x5A,0x64,0x08,0xB2,0x4B,0x8C,0x6A } }; // 91BB5E52-95D1-4F8B-9A5A-6408B24B8C6A
    template <> inline constexpr guid guid_v<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect2>{ 0x9E270E81,0x72F0,0x4C5C,{ 0x95,0xF8,0x8A,0x6E,0x00,0x24,0xF4,0x09 } }; // 9E270E81-72F0-4C5C-95F8-8A6E0024F409
    template <> struct default_interface<winrt::Windows::UI::Composition::Effects::SceneLightingEffect>{ using type = winrt::Windows::UI::Composition::Effects::ISceneLightingEffect; };
    template <> struct abi<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AmbientAmount(float*) noexcept = 0;
            virtual int32_t __stdcall put_AmbientAmount(float) noexcept = 0;
            virtual int32_t __stdcall get_DiffuseAmount(float*) noexcept = 0;
            virtual int32_t __stdcall put_DiffuseAmount(float) noexcept = 0;
            virtual int32_t __stdcall get_NormalMapSource(void**) noexcept = 0;
            virtual int32_t __stdcall put_NormalMapSource(void*) noexcept = 0;
            virtual int32_t __stdcall get_SpecularAmount(float*) noexcept = 0;
            virtual int32_t __stdcall put_SpecularAmount(float) noexcept = 0;
            virtual int32_t __stdcall get_SpecularShine(float*) noexcept = 0;
            virtual int32_t __stdcall put_SpecularShine(float) noexcept = 0;
        };
    };
    template <> struct abi<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ReflectanceModel(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_ReflectanceModel(int32_t) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_UI_Composition_Effects_ISceneLightingEffect
    {
        [[nodiscard]] WINRT_IMPL_AUTO(float) AmbientAmount() const;
        WINRT_IMPL_AUTO(void) AmbientAmount(float value) const;
        [[nodiscard]] WINRT_IMPL_AUTO(float) DiffuseAmount() const;
        WINRT_IMPL_AUTO(void) DiffuseAmount(float value) const;
        [[nodiscard]] WINRT_IMPL_AUTO(winrt::Windows::Graphics::Effects::IGraphicsEffectSource) NormalMapSource() const;
        WINRT_IMPL_AUTO(void) NormalMapSource(winrt::Windows::Graphics::Effects::IGraphicsEffectSource const& value) const;
        [[nodiscard]] WINRT_IMPL_AUTO(float) SpecularAmount() const;
        WINRT_IMPL_AUTO(void) SpecularAmount(float value) const;
        [[nodiscard]] WINRT_IMPL_AUTO(float) SpecularShine() const;
        WINRT_IMPL_AUTO(void) SpecularShine(float value) const;
    };
    template <> struct consume<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect>
    {
        template <typename D> using type = consume_Windows_UI_Composition_Effects_ISceneLightingEffect<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Composition_Effects_ISceneLightingEffect2
    {
        [[nodiscard]] WINRT_IMPL_AUTO(winrt::Windows::UI::Composition::Effects::SceneLightingEffectReflectanceModel) ReflectanceModel() const;
        WINRT_IMPL_AUTO(void) ReflectanceModel(winrt::Windows::UI::Composition::Effects::SceneLightingEffectReflectanceModel const& value) const;
    };
    template <> struct consume<winrt::Windows::UI::Composition::Effects::ISceneLightingEffect2>
    {
        template <typename D> using type = consume_Windows_UI_Composition_Effects_ISceneLightingEffect2<D>;
    };
}
#endif
