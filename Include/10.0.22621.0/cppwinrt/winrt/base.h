// C++/WinRT v2.0.220110.5

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#define CPPWINRT_VERSION "2.0.220110.5"

#pragma once
#ifndef WINRT_BASE_H
#define WINRT_BASE_H

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <iterator>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string_view>
#include <string>
#include <thread>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

#if __has_include(<WindowsNumerics.impl.h>)
#define WINRT_IMPL_NUMERICS
#include <directxmath.h>
#endif

#ifdef __cpp_lib_format
#include <format>
#endif

#ifdef __cpp_lib_coroutine

#include <coroutine>

namespace winrt::impl
{
    template <typename T = void>
    using coroutine_handle = std::coroutine_handle<T>;

    using suspend_always = std::suspend_always;
    using suspend_never = std::suspend_never;
}

#else

#include <experimental/coroutine>

namespace winrt::impl
{
    template <typename T = void>
    using coroutine_handle = std::experimental::coroutine_handle<T>;

    using suspend_always = std::experimental::suspend_always;
    using suspend_never = std::experimental::suspend_never;
}

#endif

#ifdef _DEBUG

#define WINRT_ASSERT _ASSERTE
#define WINRT_VERIFY WINRT_ASSERT
#define WINRT_VERIFY_(result, expression) WINRT_ASSERT(result == expression)

#else

#define WINRT_ASSERT(expression) ((void)0)
#define WINRT_VERIFY(expression) (void)(expression)
#define WINRT_VERIFY_(result, expression) (void)(expression)

#endif

#define WINRT_IMPL_SHIM(...) (*(abi_t<__VA_ARGS__>**)&static_cast<__VA_ARGS__ const&>(static_cast<D const&>(*this)))

#ifdef __INTELLISENSE__
#define WINRT_IMPL_AUTO(...) __VA_ARGS__
#else
#define WINRT_IMPL_AUTO(...) auto
#endif

// Note: this is a workaround for a false-positive warning produced by the Visual C++ 15.9 compiler.
#pragma warning(disable : 5046)

// Note: this is a workaround for a false-positive warning produced by the Visual C++ 16.3 compiler.
#pragma warning(disable : 4268)

#if defined(__cpp_lib_coroutine) || defined(__cpp_coroutines) || defined(_RESUMABLE_FUNCTIONS_SUPPORTED)
#define WINRT_IMPL_COROUTINES
#endif

#ifndef WINRT_EXPORT
#define WINRT_EXPORT
#endif

#ifdef WINRT_IMPL_NUMERICS
#define _WINDOWS_NUMERICS_NAMESPACE_ winrt::Windows::Foundation::Numerics
#define _WINDOWS_NUMERICS_BEGIN_NAMESPACE_ WINRT_EXPORT namespace winrt::Windows::Foundation::Numerics
#define _WINDOWS_NUMERICS_END_NAMESPACE_
#include <WindowsNumerics.impl.h>
#undef _WINDOWS_NUMERICS_NAMESPACE_
#undef _WINDOWS_NUMERICS_BEGIN_NAMESPACE_
#undef _WINDOWS_NUMERICS_END_NAMESPACE_
#endif

#if defined(_MSC_VER)
#define WINRT_IMPL_NOINLINE __declspec(noinline)
#elif defined(__GNUC__)
#define WINRT_IMPL_NOINLINE __attribute__((noinline))
#else
#define WINRT_IMPL_NOINLINE
#endif

#ifdef __IUnknown_INTERFACE_DEFINED__
#define WINRT_IMPL_IUNKNOWN_DEFINED
#else
// Forward declare so we can talk about it.
struct IUnknown;
typedef struct _GUID GUID;
#endif

namespace winrt::impl
{
    using ptp_io = struct tp_io*;
    using ptp_timer = struct tp_timer*;
    using ptp_wait = struct tp_wait*;
    using ptp_pool = struct tp_pool*;
    using srwlock = struct srwlock_*;
    using condition_variable = struct condition_variable_*;
    using bstr = wchar_t*;

    using filetime_period = std::ratio_multiply<std::ratio<100>, std::nano>;
    struct IAgileObject;

    struct com_callback_args
    {
        uint32_t reserved1;
        uint32_t reserved2;
        void* data;
    };

    template <typename T>
    constexpr uint8_t hex_to_uint(T const c)
    {
        if (c >= '0' && c <= '9')
        {
            return static_cast<uint8_t>(c - '0');
        }
        else if (c >= 'A' && c <= 'F')
        {
            return static_cast<uint8_t>(10 + c - 'A');
        }
        else if (c >= 'a' && c <= 'f')
        {
            return static_cast<uint8_t>(10 + c - 'a');
        }
        else 
        {
            throw std::invalid_argument("Character is not a hexadecimal digit");
        }
    }

    template <typename T>
    constexpr uint8_t hex_to_uint8(T const a, T const b)
    {
        return (hex_to_uint(a) << 4) | hex_to_uint(b);
    }

    constexpr uint16_t uint8_to_uint16(uint8_t a, uint8_t b)
    {
        return (static_cast<uint16_t>(a) << 8) | static_cast<uint16_t>(b);
    }

    constexpr uint32_t uint8_to_uint32(uint8_t a, uint8_t b, uint8_t c, uint8_t d)
    {
        return (static_cast<uint32_t>(uint8_to_uint16(a, b)) << 16) |
                static_cast<uint32_t>(uint8_to_uint16(c, d));
    }
}

WINRT_EXPORT namespace winrt
{
    struct event_token;
    struct hstring;
    struct clock;

    struct hresult
    {
        int32_t value{};

        constexpr hresult() noexcept = default;

        constexpr hresult(int32_t const value) noexcept : value(value)
        {
        }

        constexpr operator int32_t() const noexcept
        {
            return value;
        }
    };

    struct guid
    {
    private:

        template <typename TStringView>
        static constexpr guid parse(TStringView const value)
        {
            if (value.size() != 36 || value[8] != '-' || value[13] != '-' || value[18] != '-' || value[23] != '-')
            {
                throw std::invalid_argument("value is not a valid GUID string");
            }

            return
            {
                impl::uint8_to_uint32
                (
                    impl::hex_to_uint8(value[0], value[1]),
                    impl::hex_to_uint8(value[2], value[3]),
                    impl::hex_to_uint8(value[4], value[5]),
                    impl::hex_to_uint8(value[6], value[7])
                ),
                impl::uint8_to_uint16
                (
                    impl::hex_to_uint8(value[9], value[10]),
                    impl::hex_to_uint8(value[11], value[12])
                ),
                impl::uint8_to_uint16
                (
                    impl::hex_to_uint8(value[14], value[15]),
                    impl::hex_to_uint8(value[16], value[17])
                ),
                {
                    impl::hex_to_uint8(value[19], value[20]),
                    impl::hex_to_uint8(value[21], value[22]),
                    impl::hex_to_uint8(value[24], value[25]),
                    impl::hex_to_uint8(value[26], value[27]),
                    impl::hex_to_uint8(value[28], value[29]),
                    impl::hex_to_uint8(value[30], value[31]),
                    impl::hex_to_uint8(value[32], value[33]),
                    impl::hex_to_uint8(value[34], value[35]),
                }
            };
        }

    public:

        uint32_t Data1;
        uint16_t Data2;
        uint16_t Data3;
        uint8_t  Data4[8];

        guid() noexcept = default;

        constexpr guid(uint32_t const Data1, uint16_t const Data2, uint16_t const Data3, std::array<uint8_t, 8> const& Data4) noexcept :
            Data1(Data1),
            Data2(Data2),
            Data3(Data3),
            Data4{ Data4[0], Data4[1], Data4[2], Data4[3], Data4[4], Data4[5], Data4[6], Data4[7] }
        {
        }

        template<bool dummy = true>
        constexpr guid(GUID const& value) noexcept : guid(convert<dummy>(value)) { }

        operator GUID const&() const noexcept
        {
            return reinterpret_cast<GUID const&>(*this);
        }

        constexpr explicit guid(std::string_view const value) :
            guid(parse(value))
        {
        }

        constexpr explicit guid(std::wstring_view const value) :
            guid(parse(value))
        {
        }

    private:
        template<bool, typename T>
        constexpr static guid convert(T const& value) noexcept
        {
            return { value.Data1, value.Data2, value.Data3,
                { value.Data4[0], value.Data4[1], value.Data4[2], value.Data4[3], value.Data4[4], value.Data4[5], value.Data4[6], value.Data4[7] }
            };
        }
    };

    inline bool operator==(guid const& left, guid const& right) noexcept
    {
        return !memcmp(&left, &right, sizeof(left));
    }

    inline bool operator!=(guid const& left, guid const& right) noexcept
    {
        return !(left == right);
    }

    inline bool operator<(guid const& left, guid const& right) noexcept
    {
        return memcmp(&left, &right, sizeof(left)) < 0;
    }
}

WINRT_EXPORT namespace winrt::Windows::Foundation
{
    enum class TrustLevel : int32_t
    {
        BaseTrust,
        PartialTrust,
        FullTrust
    };

    struct IUnknown;
    struct IInspectable;
    struct IActivationFactory;
    using TimeSpan = std::chrono::duration<int64_t, impl::filetime_period>;
    using DateTime = std::chrono::time_point<clock, TimeSpan>;
}

namespace winrt::impl
{
#ifdef WINRT_IMPL_IUNKNOWN_DEFINED
    using hresult_type = long;
    using count_type = unsigned long;
    using guid_type = GUID;
#else
    using hresult_type = int32_t;
    using count_type = uint32_t;
    using guid_type = guid;
#endif

#ifdef __IInspectable_INTERFACE_DEFINED__
    using hstring_type = HSTRING;
    using trust_level_type = ::TrustLevel;
#else
    using hstring_type = void*;
    using trust_level_type = Windows::Foundation::TrustLevel;
#endif

    inline constexpr hresult error_ok{ 0 }; // S_OK
    inline constexpr hresult error_fail{ static_cast<hresult>(0x80004005) }; // E_FAIL
    inline constexpr hresult error_access_denied{ static_cast<hresult>(0x80070005) }; // E_ACCESSDENIED
    inline constexpr hresult error_wrong_thread{ static_cast<hresult>(0x8001010E) }; // RPC_E_WRONG_THREAD
    inline constexpr hresult error_not_implemented{ static_cast<hresult>(0x80004001) }; // E_NOTIMPL
    inline constexpr hresult error_invalid_argument{ static_cast<hresult>(0x80070057) }; // E_INVALIDARG
    inline constexpr hresult error_out_of_bounds{ static_cast<hresult>(0x8000000B) }; // E_BOUNDS
    inline constexpr hresult error_no_interface{ static_cast<hresult>(0x80004002) }; // E_NOINTERFACE
    inline constexpr hresult error_class_not_available{ static_cast<hresult>(0x80040111) }; // CLASS_E_CLASSNOTAVAILABLE
    inline constexpr hresult error_class_not_registered{ static_cast<hresult>(0x80040154) }; // REGDB_E_CLASSNOTREG
    inline constexpr hresult error_changed_state{ static_cast<hresult>(0x8000000C) }; // E_CHANGED_STATE
    inline constexpr hresult error_illegal_method_call{ static_cast<hresult>(0x8000000E) }; // E_ILLEGAL_METHOD_CALL
    inline constexpr hresult error_illegal_state_change{ static_cast<hresult>(0x8000000D) }; // E_ILLEGAL_STATE_CHANGE
    inline constexpr hresult error_illegal_delegate_assignment{ static_cast<hresult>(0x80000018) }; // E_ILLEGAL_DELEGATE_ASSIGNMENT
    inline constexpr hresult error_canceled{ static_cast<hresult>(0x800704C7) }; // HRESULT_FROM_WIN32(ERROR_CANCELLED)
    inline constexpr hresult error_bad_alloc{ static_cast<hresult>(0x8007000E) }; // E_OUTOFMEMORY
    inline constexpr hresult error_not_initialized{ static_cast<hresult>(0x800401F0) }; // CO_E_NOTINITIALIZED
    inline constexpr hresult error_file_not_found{ static_cast<hresult>(0x80070002) }; // HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND)
}

__declspec(selectany) int32_t(__stdcall* winrt_to_hresult_handler)(void* address) noexcept {};
__declspec(selectany) winrt::hstring(__stdcall* winrt_to_message_handler)(void* address) {};
__declspec(selectany) void(__stdcall* winrt_throw_hresult_handler)(uint32_t lineNumber, char const* fileName, char const* functionName, void* returnAddress, winrt::hresult const result) noexcept {};
__declspec(selectany) void(__stdcall* winrt_suspend_handler)(void const* token) noexcept {};
__declspec(selectany) void(__stdcall* winrt_resume_handler)(void const* token) noexcept {};
__declspec(selectany) int32_t(__stdcall* winrt_activation_handler)(void* classId, winrt::guid const& iid, void** factory) noexcept {};

extern "C"
{
    void* __stdcall WINRT_IMPL_LoadLibraryW(wchar_t const* name) noexcept;
    int32_t __stdcall WINRT_IMPL_FreeLibrary(void* library) noexcept;
    void* __stdcall WINRT_IMPL_GetProcAddress(void* library, char const* name) noexcept;

    int32_t __stdcall WINRT_IMPL_SetErrorInfo(uint32_t reserved, void* info) noexcept;
    int32_t __stdcall WINRT_IMPL_GetErrorInfo(uint32_t reserved, void** info) noexcept;
    int32_t __stdcall WINRT_IMPL_CoInitializeEx(void*, uint32_t type) noexcept;
    void    __stdcall WINRT_IMPL_CoUninitialize() noexcept;

    int32_t  __stdcall WINRT_IMPL_CoCreateFreeThreadedMarshaler(void* outer, void** marshaler) noexcept;
    int32_t  __stdcall WINRT_IMPL_CoCreateInstance(winrt::guid const& clsid, void* outer, uint32_t context, winrt::guid const& iid, void** object) noexcept;
    int32_t  __stdcall WINRT_IMPL_CoGetCallContext(winrt::guid const& iid, void** object) noexcept;
    int32_t  __stdcall WINRT_IMPL_CoGetObjectContext(winrt::guid const& iid, void** object) noexcept;
    int32_t  __stdcall WINRT_IMPL_CoGetApartmentType(int32_t* type, int32_t* qualifier) noexcept;
    void*    __stdcall WINRT_IMPL_CoTaskMemAlloc(std::size_t size) noexcept;
    void     __stdcall WINRT_IMPL_CoTaskMemFree(void* ptr) noexcept;
    winrt::impl::bstr __stdcall WINRT_IMPL_SysAllocString(wchar_t const* value) noexcept;
    void     __stdcall WINRT_IMPL_SysFreeString(winrt::impl::bstr string) noexcept;
    uint32_t __stdcall WINRT_IMPL_SysStringLen(winrt::impl::bstr string) noexcept;
    int32_t  __stdcall WINRT_IMPL_IIDFromString(wchar_t const* string, winrt::guid* iid) noexcept;
    int32_t  __stdcall WINRT_IMPL_MultiByteToWideChar(uint32_t codepage, uint32_t flags, char const* in_string, int32_t in_size, wchar_t* out_string, int32_t out_size) noexcept;
    int32_t  __stdcall WINRT_IMPL_WideCharToMultiByte(uint32_t codepage, uint32_t flags, wchar_t const* int_string, int32_t in_size, char* out_string, int32_t out_size, char const* default_char, int32_t* default_used) noexcept;
    void* __stdcall    WINRT_IMPL_HeapAlloc(void* heap, uint32_t flags, size_t bytes) noexcept;
    int32_t  __stdcall WINRT_IMPL_HeapFree(void* heap, uint32_t flags, void* value) noexcept;
    void*    __stdcall WINRT_IMPL_GetProcessHeap() noexcept;
    uint32_t __stdcall WINRT_IMPL_FormatMessageW(uint32_t flags, void const* source, uint32_t code, uint32_t language, wchar_t* buffer, uint32_t size, va_list* arguments) noexcept;
    uint32_t __stdcall WINRT_IMPL_GetLastError() noexcept;
    void     __stdcall WINRT_IMPL_GetSystemTimePreciseAsFileTime(void* result) noexcept;
    uintptr_t __stdcall WINRT_IMPL_VirtualQuery(void* address, void* buffer, uintptr_t length) noexcept;
    void*    __stdcall WINRT_IMPL_EncodePointer(void* ptr) noexcept;

    int32_t  __stdcall WINRT_IMPL_OpenProcessToken(void* process, uint32_t access, void** token) noexcept;
    void*    __stdcall WINRT_IMPL_GetCurrentProcess() noexcept;
    int32_t  __stdcall WINRT_IMPL_DuplicateToken(void* existing, uint32_t level, void** duplicate) noexcept;
    int32_t  __stdcall WINRT_IMPL_OpenThreadToken(void* thread, uint32_t access, int32_t self, void** token) noexcept;
    void*    __stdcall WINRT_IMPL_GetCurrentThread() noexcept;
    int32_t  __stdcall WINRT_IMPL_SetThreadToken(void** thread, void* token) noexcept;

    void    __stdcall WINRT_IMPL_AcquireSRWLockExclusive(winrt::impl::srwlock* lock) noexcept;
    void    __stdcall WINRT_IMPL_AcquireSRWLockShared(winrt::impl::srwlock* lock) noexcept;
    uint8_t __stdcall WINRT_IMPL_TryAcquireSRWLockExclusive(winrt::impl::srwlock* lock) noexcept;
    uint8_t __stdcall WINRT_IMPL_TryAcquireSRWLockShared(winrt::impl::srwlock* lock) noexcept;
    void    __stdcall WINRT_IMPL_ReleaseSRWLockExclusive(winrt::impl::srwlock* lock) noexcept;
    void    __stdcall WINRT_IMPL_ReleaseSRWLockShared(winrt::impl::srwlock* lock) noexcept;
    int32_t __stdcall WINRT_IMPL_SleepConditionVariableSRW(winrt::impl::condition_variable* cv, winrt::impl::srwlock* lock, uint32_t milliseconds, uint32_t flags) noexcept;
    void    __stdcall WINRT_IMPL_WakeConditionVariable(winrt::impl::condition_variable* cv) noexcept;
    void    __stdcall WINRT_IMPL_WakeAllConditionVariable(winrt::impl::condition_variable* cv) noexcept;
    void*   __stdcall WINRT_IMPL_InterlockedPushEntrySList(void* head, void* entry) noexcept;
    void*   __stdcall WINRT_IMPL_InterlockedFlushSList(void* head) noexcept;

    void* __stdcall WINRT_IMPL_CreateEventW(void*, int32_t, int32_t, void*) noexcept;
    int32_t __stdcall WINRT_IMPL_SetEvent(void*) noexcept;
    int32_t  __stdcall WINRT_IMPL_CloseHandle(void* hObject) noexcept;
    uint32_t __stdcall WINRT_IMPL_WaitForSingleObject(void* handle, uint32_t milliseconds) noexcept;

    int32_t  __stdcall WINRT_IMPL_TrySubmitThreadpoolCallback(void(__stdcall *callback)(void*, void* context), void* context, void*) noexcept;
    winrt::impl::ptp_timer __stdcall WINRT_IMPL_CreateThreadpoolTimer(void(__stdcall *callback)(void*, void* context, void*), void* context, void*) noexcept;
    void     __stdcall WINRT_IMPL_SetThreadpoolTimer(winrt::impl::ptp_timer timer, void* time, uint32_t period, uint32_t window) noexcept;
    void     __stdcall WINRT_IMPL_CloseThreadpoolTimer(winrt::impl::ptp_timer timer) noexcept;
    winrt::impl::ptp_wait __stdcall WINRT_IMPL_CreateThreadpoolWait(void(__stdcall *callback)(void*, void* context, void*, uint32_t result), void* context, void*) noexcept;
    void     __stdcall WINRT_IMPL_SetThreadpoolWait(winrt::impl::ptp_wait wait, void* handle, void* timeout) noexcept;
    void     __stdcall WINRT_IMPL_CloseThreadpoolWait(winrt::impl::ptp_wait wait) noexcept;
    winrt::impl::ptp_io __stdcall WINRT_IMPL_CreateThreadpoolIo(void* object, void(__stdcall *callback)(void*, void* context, void* overlapped, uint32_t result, std::size_t bytes, void*) noexcept, void* context, void*) noexcept;
    void     __stdcall WINRT_IMPL_StartThreadpoolIo(winrt::impl::ptp_io io) noexcept;
    void     __stdcall WINRT_IMPL_CancelThreadpoolIo(winrt::impl::ptp_io io) noexcept;
    void     __stdcall WINRT_IMPL_CloseThreadpoolIo(winrt::impl::ptp_io io) noexcept;
    winrt::impl::ptp_pool __stdcall WINRT_IMPL_CreateThreadpool(void* reserved) noexcept;
    void __stdcall WINRT_IMPL_SetThreadpoolThreadMaximum(winrt::impl::ptp_pool pool, uint32_t value) noexcept;
    int32_t __stdcall WINRT_IMPL_SetThreadpoolThreadMinimum(winrt::impl::ptp_pool pool, uint32_t value) noexcept;
    void     __stdcall WINRT_IMPL_CloseThreadpool(winrt::impl::ptp_pool pool) noexcept;

    int32_t __stdcall WINRT_CanUnloadNow() noexcept;
    int32_t __stdcall WINRT_GetActivationFactory(void* classId, void** factory) noexcept;
}

#ifdef _M_HYBRID
#define WINRT_IMPL_LINK(function, count) __pragma(comment(linker, "/alternatename:#WINRT_IMPL_" #function "@" #count "=#" #function "@" #count))
#elif _M_ARM64EC
#define WINRT_IMPL_LINK(function, count) __pragma(comment(linker, "/alternatename:#WINRT_IMPL_" #function "=#" #function))
#elif _M_IX86
#define WINRT_IMPL_LINK(function, count) __pragma(comment(linker, "/alternatename:_WINRT_IMPL_" #function "@" #count "=_" #function "@" #count))
#else
#define WINRT_IMPL_LINK(function, count) __pragma(comment(linker, "/alternatename:WINRT_IMPL_" #function "=" #function))
#endif

WINRT_IMPL_LINK(LoadLibraryW, 4)
WINRT_IMPL_LINK(FreeLibrary, 4)
WINRT_IMPL_LINK(GetProcAddress, 8)
WINRT_IMPL_LINK(SetErrorInfo, 8)
WINRT_IMPL_LINK(GetErrorInfo, 8)
WINRT_IMPL_LINK(CoInitializeEx, 8)
WINRT_IMPL_LINK(CoUninitialize, 0)

WINRT_IMPL_LINK(CoCreateFreeThreadedMarshaler, 8)
WINRT_IMPL_LINK(CoCreateInstance, 20)
WINRT_IMPL_LINK(CoGetCallContext, 8)
WINRT_IMPL_LINK(CoGetObjectContext, 8)
WINRT_IMPL_LINK(CoGetApartmentType, 8)
WINRT_IMPL_LINK(CoTaskMemAlloc, 4)
WINRT_IMPL_LINK(CoTaskMemFree, 4)
WINRT_IMPL_LINK(SysAllocString, 4)
WINRT_IMPL_LINK(SysFreeString, 4)
WINRT_IMPL_LINK(SysStringLen, 4)
WINRT_IMPL_LINK(IIDFromString, 8)
WINRT_IMPL_LINK(MultiByteToWideChar, 24)
WINRT_IMPL_LINK(WideCharToMultiByte, 32)
WINRT_IMPL_LINK(HeapAlloc, 12)
WINRT_IMPL_LINK(HeapFree, 12)
WINRT_IMPL_LINK(GetProcessHeap, 0)
WINRT_IMPL_LINK(FormatMessageW, 28)
WINRT_IMPL_LINK(GetLastError, 0)
WINRT_IMPL_LINK(GetSystemTimePreciseAsFileTime, 4)
WINRT_IMPL_LINK(VirtualQuery, 12)
WINRT_IMPL_LINK(EncodePointer, 4)

WINRT_IMPL_LINK(OpenProcessToken, 12)
WINRT_IMPL_LINK(GetCurrentProcess, 0)
WINRT_IMPL_LINK(DuplicateToken, 12)
WINRT_IMPL_LINK(OpenThreadToken, 16)
WINRT_IMPL_LINK(GetCurrentThread, 0)
WINRT_IMPL_LINK(SetThreadToken, 8)

WINRT_IMPL_LINK(AcquireSRWLockExclusive, 4)
WINRT_IMPL_LINK(AcquireSRWLockShared, 4)
WINRT_IMPL_LINK(TryAcquireSRWLockExclusive, 4)
WINRT_IMPL_LINK(TryAcquireSRWLockShared, 4)
WINRT_IMPL_LINK(ReleaseSRWLockExclusive, 4)
WINRT_IMPL_LINK(ReleaseSRWLockShared, 4)
WINRT_IMPL_LINK(SleepConditionVariableSRW, 16)
WINRT_IMPL_LINK(WakeConditionVariable, 4)
WINRT_IMPL_LINK(WakeAllConditionVariable, 4)
WINRT_IMPL_LINK(InterlockedPushEntrySList, 8)
WINRT_IMPL_LINK(InterlockedFlushSList, 4)

WINRT_IMPL_LINK(CreateEventW, 16)
WINRT_IMPL_LINK(SetEvent, 4)
WINRT_IMPL_LINK(CloseHandle, 4)
WINRT_IMPL_LINK(WaitForSingleObject, 8)

WINRT_IMPL_LINK(TrySubmitThreadpoolCallback, 12)
WINRT_IMPL_LINK(CreateThreadpoolTimer, 12)
WINRT_IMPL_LINK(SetThreadpoolTimer, 16)
WINRT_IMPL_LINK(CloseThreadpoolTimer, 4)
WINRT_IMPL_LINK(CreateThreadpoolWait, 12)
WINRT_IMPL_LINK(SetThreadpoolWait, 12)
WINRT_IMPL_LINK(CloseThreadpoolWait, 4)
WINRT_IMPL_LINK(CreateThreadpoolIo, 16)
WINRT_IMPL_LINK(StartThreadpoolIo, 4)
WINRT_IMPL_LINK(CancelThreadpoolIo, 4)
WINRT_IMPL_LINK(CloseThreadpoolIo, 4)
WINRT_IMPL_LINK(CreateThreadpool, 4)
WINRT_IMPL_LINK(SetThreadpoolThreadMaximum, 8)
WINRT_IMPL_LINK(SetThreadpoolThreadMinimum, 8)
WINRT_IMPL_LINK(CloseThreadpool, 4)

#undef WINRT_IMPL_LINK

WINRT_EXPORT namespace winrt
{
    hresult check_hresult(hresult const result);
    hresult to_hresult() noexcept;

    template <typename D, typename I>
    D* get_self(I const& from) noexcept;

    struct take_ownership_from_abi_t {};
    inline constexpr take_ownership_from_abi_t take_ownership_from_abi{};

    template <typename T>
    struct com_ptr;

    namespace param
    {
        template <typename T>
        struct iterable;

        template <typename T>
        struct async_iterable;

        template <typename K, typename V>
        struct map_view;

        template <typename K, typename V>
        struct async_map_view;

        template <typename K, typename V>
        struct map;

        template <typename T>
        struct vector_view;

        template <typename T>
        struct async_vector_view;

        template <typename T>
        struct vector;
    }
}

namespace winrt::impl
{
    using namespace std::literals;

    template <typename T>
    struct reference_traits;

    template <typename T>
    struct identity
    {
        using type = T;
    };

    template <typename T, typename Enable = void>
    struct abi
    {
        using type = T;
    };

    template <typename T>
    struct abi<T, std::enable_if_t<std::is_enum_v<T>>>
    {
        using type = std::underlying_type_t<T>;
    };

    template <typename T>
    using abi_t = typename abi<T>::type;

    template <typename T>
    struct consume;

    template <typename D, typename I = D>
    using consume_t = typename consume<I>::template type<D>;

    template <typename T, typename H>
    struct delegate;

    template <typename T, typename = std::void_t<>>
    struct default_interface
    {
        using type = T;
    };

    struct basic_category;
    struct interface_category;
    struct delegate_category;
    struct enum_category;
    struct class_category;

    template <typename T>
    struct category
    {
        using type = void;
    };

    template <typename T>
    using category_t = typename category<T>::type;

    template <typename T>
    inline constexpr bool has_category_v = !std::is_same_v<category_t<T>, void>;

    template <typename... Args>
    struct generic_category;

    template <typename... Fields>
    struct struct_category;

    template <typename Category, typename T>
    struct category_signature;

    template <typename T>
    struct signature
    {
        static constexpr auto data{ category_signature<category_t<T>, T>::data };
    };

    template <typename T>
#if defined(__clang__)
#if __has_declspec_attribute(uuid)
    inline const guid guid_v{ __uuidof(T) };
#else
    inline constexpr guid guid_v{};
#endif
#elif defined(_MSC_VER)
    inline constexpr guid guid_v{ __uuidof(T) };
#else
    inline constexpr guid guid_v{};
#endif

    template <typename T>
    constexpr auto to_underlying_type(T const value) noexcept
    {
        return static_cast<std::underlying_type_t<T>>(value);
    }

    template <typename, typename = std::void_t<>>
    struct is_implements : std::false_type {};

    template <typename T>
    struct is_implements<T, std::void_t<typename T::implements_type>> : std::true_type {};

    template <typename T>
    inline constexpr bool is_implements_v = is_implements<T>::value;

    template <typename D, typename I>
    struct require_one : consume_t<D, I>
    {
        operator I() const noexcept
        {
            return static_cast<D const*>(this)->template try_as<I>();
        }
    };

    template <typename D, typename... I>
    struct __declspec(empty_bases) require : require_one<D, I>...
    {};

    template <typename D, typename I>
    struct base_one
    {
        operator I() const noexcept
        {
            return static_cast<D const*>(this)->template try_as<I>();
        }
    };

    template <typename D, typename... I>
    struct __declspec(empty_bases) base : base_one<D, I>...
    {};

    template <typename T>
    T empty_value() noexcept
    {
        if constexpr (std::is_base_of_v<Windows::Foundation::IUnknown, T>)
        {
            return nullptr;
        }
        else
        {
            return {};
        }
    }

    template <typename T, typename Enable = void>
    struct arg
    {
        using in = abi_t<T>;
    };

    template <typename T>
    struct arg<T, std::enable_if_t<std::is_base_of_v<Windows::Foundation::IUnknown, T>>>
    {
        using in = void*;
    };

    template <typename T>
    using arg_in = typename arg<T>::in;

    template <typename T>
    using arg_out = arg_in<T>*;

    template <typename D, typename I, typename Enable = void>
    struct produce_base;

    template <typename D, typename I>
    struct produce;

    template <typename D>
    struct produce<D, Windows::Foundation::IInspectable> : produce_base<D, Windows::Foundation::IInspectable>
    {
    };

    template <typename T>
    struct wrapped_type
    {
        using type = T;
    };

    template <typename T>
    struct wrapped_type<com_ptr<T>>
    {
        using type = T;
    };

    template <typename T>
    using wrapped_type_t = typename wrapped_type<T>::type;

    template <typename ... Types>
    struct typelist {};

    template <typename ... Lists>
    struct typelist_concat;

    template <>
    struct typelist_concat<> { using type = winrt::impl::typelist<>; };

    template <typename ... List>
    struct typelist_concat<winrt::impl::typelist<List...>> { using type = winrt::impl::typelist<List...>; };

    template <typename ... List1, typename ... List2, typename ... Rest>
    struct typelist_concat<winrt::impl::typelist<List1...>, winrt::impl::typelist<List2...>, Rest...>
        : typelist_concat<winrt::impl::typelist<List1..., List2...>, Rest...>
    {};

    template <typename T>
    struct for_each;

    template <typename ... Types>
    struct for_each<typelist<Types...>>
    {
        template <typename Func>
        static auto apply([[maybe_unused]] Func&& func)
        {
            return (func(Types{}), ...);
        }
    };

    template <typename T>
    struct find_if;

    template <typename ... Types>
    struct find_if<typelist<Types...>>
    {
        template <typename Func>
        static bool apply([[maybe_unused]] Func&& func)
        {
            return (func(Types{}) || ...);
        }
    };
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    using default_interface = typename impl::default_interface<T>::type;

    template <typename T>
    constexpr guid const& guid_of() noexcept
    {
        return impl::guid_v<default_interface<T>>;
    }

    template <typename... T>
    bool is_guid_of(guid const& id) noexcept
    {
        return ((id == guid_of<T>()) || ...);
    }
}

namespace winrt::impl
{
    template <size_t Size, typename T, size_t... Index>
    constexpr std::array<T, Size> to_array(T const* value, std::index_sequence<Index...> const) noexcept
    {
        return { value[Index]... };
    }

    template <typename T, size_t Size>
    constexpr auto to_array(std::array<T, Size> const& value) noexcept
    {
        return value;
    }

    template <size_t Size>
    constexpr auto to_array(char const(&value)[Size]) noexcept
    {
        return to_array<Size - 1>(value, std::make_index_sequence<Size - 1>());
    }

    template <size_t Size>
    constexpr auto to_array(wchar_t const(&value)[Size]) noexcept
    {
        return to_array<Size - 1>(value, std::make_index_sequence<Size - 1>());
    }

    template <typename T, size_t LeftSize, size_t RightSize, size_t... LeftIndex, size_t... RightIndex>
    constexpr std::array<T, LeftSize + RightSize> concat(
        [[maybe_unused]] std::array<T, LeftSize> const& left,
        [[maybe_unused]] std::array<T, RightSize> const& right,
        std::index_sequence<LeftIndex...> const,
        std::index_sequence<RightIndex...> const) noexcept
    {
        return { left[LeftIndex]..., right[RightIndex]... };
    }

    template <typename T, size_t LeftSize, size_t RightSize>
    constexpr auto concat(std::array<T, LeftSize> const& left, std::array<T, RightSize> const& right) noexcept
    {
        return concat(left, right, std::make_index_sequence<LeftSize>(), std::make_index_sequence<RightSize>());
    }

    template <typename T, size_t LeftSize, size_t RightSize>
    constexpr auto concat(std::array<T, LeftSize> const& left, T const(&right)[RightSize]) noexcept
    {
        return concat(left, to_array(right));
    }

    template <typename T, size_t LeftSize, size_t RightSize>
    constexpr auto concat(T const(&left)[LeftSize], std::array<T, RightSize> const& right) noexcept
    {
        return concat(to_array(left), right);
    }

    template <typename T, size_t LeftSize>
    constexpr auto concat(std::array<T, LeftSize> const& left, T const right) noexcept
    {
        return concat(left, std::array<T, 1>{right});
    }

    template <typename T, size_t RightSize>
    constexpr auto concat(T const left, std::array<T, RightSize> const& right) noexcept
    {
        return concat(std::array<T, 1>{left}, right);
    }

    template <typename First, typename... Rest>
    constexpr auto combine(First const& first, Rest const&... rest) noexcept
    {
        if constexpr (sizeof...(rest) == 0)
        {
            return to_array(first);
        }
        else
        {
            return concat(first, combine(rest...));
        }
    }

    template <typename T, size_t LS, size_t RS, size_t... LI, size_t... RI>
    constexpr std::array<T, LS + RS - 1> zconcat_base(std::array<T, LS> const& left, std::array<T, RS> const& right, std::index_sequence<LI...> const, std::index_sequence<RI...> const) noexcept
    {
        return { left[LI]..., right[RI]..., T{} };
    }

    template <typename T, size_t LS, size_t RS>
    constexpr auto zconcat(std::array<T, LS> const& left, std::array<T, RS> const& right) noexcept
    {
        return zconcat_base(left, right, std::make_index_sequence<LS - 1>(), std::make_index_sequence<RS - 1>());
    }

    template <typename T, size_t S, size_t... I>
    constexpr std::array<T, S> to_zarray_base(T const(&value)[S], std::index_sequence<I...> const) noexcept
    {
        return { value[I]... };
    }

    template <typename T, size_t S>
    constexpr auto to_zarray(T const(&value)[S]) noexcept
    {
        return to_zarray_base(value, std::make_index_sequence<S>());
    }

    template <typename T, size_t S>
    constexpr auto to_zarray(std::array<T, S> const& value) noexcept
    {
        return value;
    }

    template <typename First, typename... Rest>
    constexpr auto zcombine(First const& first, Rest const&... rest) noexcept
    {
        if constexpr (sizeof...(rest) == 0)
        {
            return to_zarray(first);
        }
        else
        {
            return zconcat(to_zarray(first), zcombine(rest...));
        }
    }

    constexpr std::array<uint8_t, 4> to_array(uint32_t value) noexcept
    {
        return { static_cast<uint8_t>(value & 0x000000ff), static_cast<uint8_t>((value & 0x0000ff00) >> 8), static_cast<uint8_t>((value & 0x00ff0000) >> 16), static_cast<uint8_t>((value & 0xff000000) >> 24) };
    }

    constexpr std::array<uint8_t, 2> to_array(uint16_t value) noexcept
    {
        return { static_cast<uint8_t>(value & 0x00ff), static_cast<uint8_t>((value & 0xff00) >> 8) };
    }

    constexpr auto to_array(guid const& value) noexcept
    {
        return combine(to_array(value.Data1), to_array(value.Data2), to_array(value.Data3),
            std::array<uint8_t, 8>{ value.Data4[0], value.Data4[1], value.Data4[2], value.Data4[3], value.Data4[4], value.Data4[5], value.Data4[6], value.Data4[7] });
    }

    template <typename T>
    constexpr T to_hex_digit(uint8_t value) noexcept
    {
        value &= 0xF;
        return value < 10 ? static_cast<T>('0') + value : static_cast<T>('a') + (value - 10);
    }

    template <typename T>
    constexpr std::array<T, 2> uint8_to_hex(uint8_t const value) noexcept
    {
        return { to_hex_digit<T>(value >> 4), to_hex_digit<T>(value & 0xF) };
    }

    template <typename T>
    constexpr auto uint16_to_hex(uint16_t value) noexcept
    {
        return combine(uint8_to_hex<T>(static_cast<uint8_t>(value >> 8)), uint8_to_hex<T>(value & 0xFF));
    }

    template <typename T>
    constexpr auto uint32_to_hex(uint32_t const value) noexcept
    {
        return combine(uint16_to_hex<T>(value >> 16), uint16_to_hex<T>(value & 0xFFFF));
    }

    template <typename T>
    constexpr auto to_array(guid const& value) noexcept
    {
        return combine
        (
            std::array<T, 1>{'{'},
            uint32_to_hex<T>(value.Data1), std::array<T, 1>{'-'},
            uint16_to_hex<T>(value.Data2), std::array<T, 1>{'-'},
            uint16_to_hex<T>(value.Data3), std::array<T, 1>{'-'},
            uint16_to_hex<T>(value.Data4[0] << 8 | value.Data4[1]), std::array<T, 1>{'-'},
            uint16_to_hex<T>(value.Data4[2] << 8 | value.Data4[3]),
            uint16_to_hex<T>(value.Data4[4] << 8 | value.Data4[5]),
            uint16_to_hex<T>(value.Data4[6] << 8 | value.Data4[7]),
            std::array<T, 1>{'}'}
        );
    }

    constexpr uint32_t to_guid(uint8_t a, uint8_t b, uint8_t c, uint8_t d) noexcept
    {
        return (static_cast<uint32_t>(d) << 24) | (static_cast<uint32_t>(c) << 16) | (static_cast<uint32_t>(b) << 8) | static_cast<uint32_t>(a);
    }

    constexpr uint16_t to_guid(uint8_t a, uint8_t b) noexcept
    {
        return (static_cast<uint32_t>(b) << 8) | static_cast<uint32_t>(a);
    }

    template <size_t Size>
    constexpr guid to_guid(std::array<uint8_t, Size> const& arr) noexcept
    {
        return
        {
            to_guid(arr[0], arr[1], arr[2], arr[3]),
            to_guid(arr[4], arr[5]),
            to_guid(arr[6], arr[7]),
        { arr[8], arr[9], arr[10], arr[11], arr[12], arr[13], arr[14], arr[15] }
        };
    }

    constexpr uint32_t endian_swap(uint32_t value) noexcept
    {
        return (value & 0xFF000000) >> 24 | (value & 0x00FF0000) >> 8 | (value & 0x0000FF00) << 8 | (value & 0x000000FF) << 24;
    }

    constexpr uint16_t endian_swap(uint16_t value) noexcept
    {
        return (value & 0xFF00) >> 8 | (value & 0x00FF) << 8;
    }

    constexpr guid endian_swap(guid value) noexcept
    {
        value.Data1 = endian_swap(value.Data1);
        value.Data2 = endian_swap(value.Data2);
        value.Data3 = endian_swap(value.Data3);
        return value;
    }

    constexpr guid set_named_guid_fields(guid value) noexcept
    {
        value.Data3 = static_cast<uint16_t>((value.Data3 & 0x0fff) | (5 << 12));
        value.Data4[0] = static_cast<uint8_t>((value.Data4[0] & 0x3f) | 0x80);
        return value;
    }

    template <typename T, size_t Size, size_t... Index>
    constexpr std::array<uint8_t, Size> char_to_byte_array(std::array<T, Size> const& value, std::index_sequence<Index...> const) noexcept
    {
        return { static_cast<uint8_t>(value[Index])... };
    }

    constexpr auto sha1_rotl(uint8_t bits, uint32_t word) noexcept
    {
        return  (word << bits) | (word >> (32 - bits));
    }

    constexpr auto sha_ch(uint32_t x, uint32_t y, uint32_t z) noexcept
    {
        return (x & y) ^ ((~x) & z);
    }

    constexpr auto sha_parity(uint32_t x, uint32_t y, uint32_t z) noexcept
    {
        return x ^ y ^ z;
    }

    constexpr auto sha_maj(uint32_t x, uint32_t y, uint32_t z) noexcept
    {
        return (x & y) ^ (x & z) ^ (y & z);
    }

    constexpr std::array<uint32_t, 5> process_msg_block(uint8_t const* input, size_t start_pos, std::array<uint32_t, 5> const& intermediate_hash) noexcept
    {
        uint32_t const K[4] = { 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6 };
        std::array<uint32_t, 80> W = {};

        size_t t = 0;
        uint32_t temp = 0;

        for (t = 0; t < 16; t++)
        {
            W[t] = static_cast<uint32_t>(input[start_pos + t * 4]) << 24;
            W[t] = W[t] | static_cast<uint32_t>(input[start_pos + t * 4 + 1]) << 16;
            W[t] = W[t] | static_cast<uint32_t>(input[start_pos + t * 4 + 2]) << 8;
            W[t] = W[t] | static_cast<uint32_t>(input[start_pos + t * 4 + 3]);
        }

        for (t = 16; t < 80; t++)
        {
            W[t] = sha1_rotl(1, W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16]);
        }

        uint32_t A = intermediate_hash[0];
        uint32_t B = intermediate_hash[1];
        uint32_t C = intermediate_hash[2];
        uint32_t D = intermediate_hash[3];
        uint32_t E = intermediate_hash[4];

        for (t = 0; t < 20; t++)
        {
            temp = sha1_rotl(5, A) + sha_ch(B, C, D) + E + W[t] + K[0];
            E = D;
            D = C;
            C = sha1_rotl(30, B);
            B = A;
            A = temp;
        }

        for (t = 20; t < 40; t++)
        {
            temp = sha1_rotl(5, A) + sha_parity(B, C, D) + E + W[t] + K[1];
            E = D;
            D = C;
            C = sha1_rotl(30, B);
            B = A;
            A = temp;
        }

        for (t = 40; t < 60; t++)
        {
            temp = sha1_rotl(5, A) + sha_maj(B, C, D) + E + W[t] + K[2];
            E = D;
            D = C;
            C = sha1_rotl(30, B);
            B = A;
            A = temp;
        }

        for (t = 60; t < 80; t++)
        {
            temp = sha1_rotl(5, A) + sha_parity(B, C, D) + E + W[t] + K[3];
            E = D;
            D = C;
            C = sha1_rotl(30, B);
            B = A;
            A = temp;
        }

        return { intermediate_hash[0] + A, intermediate_hash[1] + B, intermediate_hash[2] + C, intermediate_hash[3] + D, intermediate_hash[4] + E };
    }

    template <size_t Size>
    constexpr std::array<uint32_t, 5> process_msg_block(std::array<uint8_t, Size> const& input, size_t start_pos, std::array<uint32_t, 5> const& intermediate_hash) noexcept
    {
        return process_msg_block(input.data(), start_pos, intermediate_hash);
    }

    constexpr std::array<uint8_t, 8> size_to_bytes(size_t size) noexcept
    {
        return
        {
            static_cast<uint8_t>((size & 0xff00000000000000) >> 56),
            static_cast<uint8_t>((size & 0x00ff000000000000) >> 48),
            static_cast<uint8_t>((size & 0x0000ff0000000000) >> 40),
            static_cast<uint8_t>((size & 0x000000ff00000000) >> 32),
            static_cast<uint8_t>((size & 0x00000000ff000000) >> 24),
            static_cast<uint8_t>((size & 0x0000000000ff0000) >> 16),
            static_cast<uint8_t>((size & 0x000000000000ff00) >> 8),
            static_cast<uint8_t>((size & 0x00000000000000ff) >> 0)
        };
    }

    template <size_t Size, size_t RemainingSize, size_t... Index>
    constexpr std::array<uint8_t, RemainingSize + 1> make_remaining([[maybe_unused]] std::array<uint8_t, Size> const& input, [[maybe_unused]] size_t start_pos, std::index_sequence<Index...>) noexcept
    {
        return { input[Index + start_pos]..., 0x80 };
    }

    template <size_t Size>
    constexpr auto make_remaining(std::array<uint8_t, Size> const& input, size_t start_pos) noexcept
    {
        constexpr auto remaining_size = Size % 64;
        return make_remaining<Size, remaining_size>(input, start_pos, std::make_index_sequence<remaining_size>());
    }

    template <size_t InputSize, size_t RemainderSize>
    constexpr auto make_buffer(std::array<uint8_t, RemainderSize> const& remaining_buffer) noexcept
    {
        constexpr auto message_length = (RemainderSize + 8 <= 64) ? 64 : 64 * 2;
        constexpr auto padding_length = message_length - RemainderSize - 8;

        auto padding_buffer = std::array<uint8_t, padding_length>{};
        auto length_buffer = size_to_bytes(InputSize * 8);

        return combine(remaining_buffer, padding_buffer, length_buffer);
    }

    template <size_t Size>
    constexpr std::array<uint32_t, 5> finalize_remaining_buffer(std::array<uint8_t, Size> const& input, std::array<uint32_t, 5> const& intermediate_hash) noexcept
    {
        if constexpr (Size == 64)
        {
            return process_msg_block(input, 0, intermediate_hash);
        }
        else if constexpr (Size == 64 * 2)
        {
            return process_msg_block(input, 64, process_msg_block(input, 0, intermediate_hash));
        }
    }

    template <size_t... Index>
    constexpr std::array<uint8_t, 20> get_result(std::array<uint32_t, 5> const& intermediate_hash, std::index_sequence<Index...>) noexcept
    {
        return { static_cast<uint8_t>(intermediate_hash[Index >> 2] >> (8 * (3 - (Index & 0x03))))... };
    }

    constexpr auto get_result(std::array<uint32_t, 5> const& intermediate_hash) noexcept
    {
        return get_result(intermediate_hash, std::make_index_sequence<20>{});
    }

    template <size_t Size>
    constexpr auto calculate_sha1(std::array<uint8_t, Size> const& input) noexcept
    {
        std::array<uint32_t, 5> intermediate_hash{ 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 };
        size_t i = 0;

        while (i + 64 <= Size)
        {
            intermediate_hash = process_msg_block(input, i, intermediate_hash);
            i += 64;
        }

        intermediate_hash = finalize_remaining_buffer(make_buffer<Size>(make_remaining(input, i)), intermediate_hash);
        return get_result(intermediate_hash);
    }

    template <size_t Size>
    constexpr guid generate_guid(std::array<char, Size> const& value) noexcept
    {
        guid namespace_guid = { 0xd57af411, 0x737b, 0xc042,{ 0xab, 0xae, 0x87, 0x8b, 0x1e, 0x16, 0xad, 0xee } };

        auto buffer = combine(to_array(namespace_guid), char_to_byte_array(value, std::make_index_sequence<Size>()));
        auto hash = calculate_sha1(buffer);
        auto big_endian_guid = to_guid(hash);
        auto little_endian_guid = endian_swap(big_endian_guid);
        return set_named_guid_fields(little_endian_guid);
    }

    template <typename TArg, typename... TRest>
    struct arg_collection
    {
        constexpr static auto data{ combine(to_array(signature<TArg>::data), ";", arg_collection<TRest...>::data) };
    };

    template <typename TArg>
    struct arg_collection<TArg>
    {
        constexpr static auto data{ to_array(signature<TArg>::data) };
    };

    template <typename T>
    struct pinterface_guid
    {
#pragma warning(suppress: 4307)
        static constexpr guid value{ generate_guid(signature<T>::data) };
    };

    template <typename T>
#ifdef __clang__
    inline static const auto name_v
#else
#pragma warning(suppress: 4307)
    inline constexpr auto name_v
#endif
    {
        combine
        (
            to_array<wchar_t>(guid_of<T>()),
            std::array<wchar_t, 1>{ L'\0' }
        )
    };

    constexpr size_t to_utf8_size(wchar_t const value) noexcept
    {
        if (value <= 0x7F)
        {
            return 1;
        }

        if (value <= 0x7FF)
        {
            return 2;
        }

        return 3;
    }

    constexpr size_t to_utf8(wchar_t const value, char* buffer) noexcept
    {
        if (value <= 0x7F)
        {
            *buffer = static_cast<char>(value);
            return 1;
        }

        if (value <= 0x7FF)
        {
            *buffer = static_cast<char>(0xC0 | (value >> 6));
            *(buffer + 1) = 0x80 | (value & 0x3F);
            return 2;
        }

        *buffer = 0xE0 | (value >> 12);
        *(buffer + 1) = 0x80 | ((value >> 6) & 0x3F);
        *(buffer + 2) = 0x80 | (value & 0x3F);
        return 3;
    }

    template <typename T>
    constexpr size_t to_utf8_size() noexcept
    {
        auto input = to_array(name_v<T>);
        size_t length = 0;

        for (wchar_t const element : input)
        {
            length += to_utf8_size(element);
        }

        return length;
    }

    template <typename T>
    constexpr auto to_utf8() noexcept
    {
        auto input = to_array(name_v<T>);
        std::array<char, to_utf8_size<T>()> output{};
        size_t offset{};

        for (wchar_t const element : input)
        {
            offset += to_utf8(element, &output[offset]);
        }

        return output;
    }

    template <typename T>
    constexpr guid generic_guid_v{};

    template <typename T>
    constexpr auto& basic_signature_v = "";

    template <> inline constexpr auto& basic_signature_v<bool> = "b1";
    template <> inline constexpr auto& basic_signature_v<int8_t> = "i1";
    template <> inline constexpr auto& basic_signature_v<int16_t> = "i2";
    template <> inline constexpr auto& basic_signature_v<int32_t> = "i4";
    template <> inline constexpr auto& basic_signature_v<int64_t> = "i8";
    template <> inline constexpr auto& basic_signature_v<uint8_t> = "u1";
    template <> inline constexpr auto& basic_signature_v<uint16_t> = "u2";
    template <> inline constexpr auto& basic_signature_v<uint32_t> = "u4";
    template <> inline constexpr auto& basic_signature_v<uint64_t> = "u8";
    template <> inline constexpr auto& basic_signature_v<float> = "f4";
    template <> inline constexpr auto& basic_signature_v<double> = "f8";
    template <> inline constexpr auto& basic_signature_v<char16_t> = "c2";
    template <> inline constexpr auto& basic_signature_v<guid> = "g16";
    template <> inline constexpr auto& basic_signature_v<hstring> = "string";
    template <> inline constexpr auto& basic_signature_v<Windows::Foundation::IInspectable> = "cinterface(IInspectable)";

    template <> inline constexpr auto& name_v<bool> = L"Boolean";
    template <> inline constexpr auto& name_v<int8_t> = L"Int8";
    template <> inline constexpr auto& name_v<int16_t> = L"Int16";
    template <> inline constexpr auto& name_v<int32_t> = L"Int32";
    template <> inline constexpr auto& name_v<int64_t> = L"Int64";
    template <> inline constexpr auto& name_v<uint8_t> = L"UInt8";
    template <> inline constexpr auto& name_v<uint16_t> = L"UInt16";
    template <> inline constexpr auto& name_v<uint32_t> = L"UInt32";
    template <> inline constexpr auto& name_v<uint64_t> = L"UInt64";
    template <> inline constexpr auto& name_v<float> = L"Single";
    template <> inline constexpr auto& name_v<double> = L"Double";
    template <> inline constexpr auto& name_v<char16_t> = L"Char16";
    template <> inline constexpr auto& name_v<guid> = L"Guid";
    template <> inline constexpr auto& name_v<hstring> = L"String";
    template <> inline constexpr auto& name_v<hresult> = L"Windows.Foundation.HResult";
    template <> inline constexpr auto& name_v<event_token> = L"Windows.Foundation.EventRegistrationToken";
    template <> inline constexpr auto& name_v<Windows::Foundation::IInspectable> = L"Object";
    template <> inline constexpr auto& name_v<Windows::Foundation::TimeSpan> = L"Windows.Foundation.TimeSpan";
    template <> inline constexpr auto& name_v<Windows::Foundation::DateTime> = L"Windows.Foundation.DateTime";
    template <> inline constexpr auto& name_v<IAgileObject> = L"IAgileObject";

    template <> struct category<bool> { using type = basic_category; };
    template <> struct category<int8_t> { using type = basic_category; };
    template <> struct category<int16_t> { using type = basic_category; };
    template <> struct category<int32_t> { using type = basic_category; };
    template <> struct category<int64_t> { using type = basic_category; };
    template <> struct category<uint8_t> { using type = basic_category; };
    template <> struct category<uint16_t> { using type = basic_category; };
    template <> struct category<uint32_t> { using type = basic_category; };
    template <> struct category<uint64_t> { using type = basic_category; };
    template <> struct category<float> { using type = basic_category; };
    template <> struct category<double> { using type = basic_category; };
    template <> struct category<char16_t> { using type = basic_category; };
    template <> struct category<guid> { using type = basic_category; };
    template <> struct category<hresult> { using type = struct_category<int32_t>; };
    template <> struct category<event_token> { using type = struct_category<int64_t>; };
    template <> struct category<Windows::Foundation::IInspectable> { using type = basic_category; };
    template <> struct category<Windows::Foundation::TimeSpan> { using type = struct_category<int64_t>; };
    template <> struct category<Windows::Foundation::DateTime> { using type = struct_category<int64_t>; };

    template <typename T>
    struct category_signature<basic_category, T>
    {
        constexpr static auto data{ to_array(basic_signature_v<T>) };
    };

    template <typename T>
    struct category_signature<enum_category, T>
    {
        using enum_type = std::underlying_type_t<T>;
        constexpr static auto data{ combine("enum(", to_utf8<T>(), ";", signature<enum_type>::data, ")") };
    };

    template <typename... Fields, typename T>
    struct category_signature<struct_category<Fields...>, T>
    {
        constexpr static auto data{ combine("struct(", to_utf8<T>(), ";", arg_collection<Fields...>::data, ")") };
    };

    template <typename T>
    struct category_signature<class_category, T>
    {
        constexpr static auto data{ combine("rc(", to_utf8<T>(), ";", signature<winrt::default_interface<T>>::data, ")") };
    };

    template <typename... Args, typename T>
    struct category_signature<generic_category<Args...>, T>
    {
        constexpr static auto data{ combine("pinterface(", to_array<char>(generic_guid_v<T>), ";", arg_collection<Args...>::data, ")") };
    };

    template <typename T>
    struct category_signature<interface_category, T>
    {
        constexpr static auto data{ to_array<char>(guid_of<T>()) };
    };

    template <typename T>
    struct category_signature<delegate_category, T>
    {
        constexpr static auto data{ combine("delegate(", to_array<char>(guid_of<T>()), ")") };
    };

    template <size_t Size>
    constexpr std::wstring_view to_wstring_view(std::array<wchar_t, Size> const& value) noexcept
    {
        return { value.data(), Size - 1 };
    }

    template <size_t Size>
    constexpr std::wstring_view to_wstring_view(wchar_t const (&value)[Size]) noexcept
    {
        return { value, Size - 1 };
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    constexpr auto name_of() noexcept
    {
        return impl::to_wstring_view(impl::name_v<T>);
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct handle_type
    {
        using type = typename T::type;

        handle_type() noexcept = default;

        explicit handle_type(type value) noexcept : m_value(value)
        {
        }

        handle_type(handle_type&& other) noexcept : m_value(other.detach())
        {
        }

        handle_type& operator=(handle_type&& other) noexcept
        {
            if (this != &other)
            {
                attach(other.detach());
            }

            return*this;
        }

        ~handle_type() noexcept
        {
            close();
        }

        void close() noexcept
        {
            if (*this)
            {
                T::close(m_value);
                m_value = T::invalid();
            }
        }

        explicit operator bool() const noexcept
        {
            return T::invalid() != m_value;
        }

        type get() const noexcept
        {
            return m_value;
        }

        type* put() noexcept
        {
            close();
            return &m_value;
        }

        void attach(type value) noexcept
        {
            close();
            *put() = value;
        }

        type detach() noexcept
        {
            type value = m_value;
            m_value = T::invalid();
            return value;
        }

        friend void swap(handle_type& left, handle_type& right) noexcept
        {
            std::swap(left.m_value, right.m_value);
        }

    private:

        type m_value = T::invalid();
    };

    struct handle_traits
    {
        using type = void*;

        static void close(type value) noexcept
        {
            WINRT_VERIFY_(1, WINRT_IMPL_CloseHandle(value));
        }

        static constexpr type invalid() noexcept
        {
            return nullptr;
        }
    };

    using handle = handle_type<handle_traits>;

    struct file_handle_traits
    {
        using type = void*;

        static void close(type value) noexcept
        {
            WINRT_VERIFY_(1, WINRT_IMPL_CloseHandle(value));
        }

        static type invalid() noexcept
        {
            return reinterpret_cast<type>(-1);
        }
    };

    using file_handle = handle_type<file_handle_traits>;
}

WINRT_EXPORT namespace winrt
{
    struct slim_condition_variable;

    struct slim_mutex
    {
        slim_mutex(slim_mutex const&) = delete;
        slim_mutex& operator=(slim_mutex const&) = delete;
        slim_mutex() noexcept = default;

        void lock() noexcept
        {
            WINRT_IMPL_AcquireSRWLockExclusive(&m_lock);
        }

        void lock_shared() noexcept
        {
            WINRT_IMPL_AcquireSRWLockShared(&m_lock);
        }

        bool try_lock() noexcept
        {
            return 0 != WINRT_IMPL_TryAcquireSRWLockExclusive(&m_lock);
        }

        bool try_lock_shared() noexcept
        {
            return 0 != WINRT_IMPL_TryAcquireSRWLockShared(&m_lock);
        }

        void unlock() noexcept
        {
            WINRT_IMPL_ReleaseSRWLockExclusive(&m_lock);
        }

        void unlock_shared() noexcept
        {
            WINRT_IMPL_ReleaseSRWLockShared(&m_lock);
        }

    private:
        friend slim_condition_variable;

        auto get() noexcept
        {
            return &m_lock;
        }

        impl::srwlock m_lock{};
    };

    struct slim_lock_guard
    {
        explicit slim_lock_guard(slim_mutex& m) noexcept :
        m_mutex(m)
        {
            m_mutex.lock();
        }

        slim_lock_guard(slim_lock_guard const&) = delete;

        ~slim_lock_guard() noexcept
        {
            m_mutex.unlock();
        }

    private:
        slim_mutex& m_mutex;
    };

    struct slim_shared_lock_guard
    {
        explicit slim_shared_lock_guard(slim_mutex& m) noexcept :
            m_mutex(m)
        {
            m_mutex.lock_shared();
        }

        slim_shared_lock_guard(slim_shared_lock_guard const&) = delete;

        ~slim_shared_lock_guard() noexcept
        {
            m_mutex.unlock_shared();
        }

    private:
        slim_mutex& m_mutex;
    };

    struct slim_condition_variable
    {
        slim_condition_variable(slim_condition_variable const&) = delete;
        slim_condition_variable const& operator=(slim_condition_variable const&) = delete;
        slim_condition_variable() noexcept = default;

        template <typename T>
        void wait(slim_mutex& x, T predicate)
        {
            while (!predicate())
            {
                WINRT_VERIFY(WINRT_IMPL_SleepConditionVariableSRW(&m_cv, x.get(), 0xFFFFFFFF /*INFINITE*/, 0));
            }
        }

        template <typename T>
        bool wait_for(slim_mutex& x, std::chrono::high_resolution_clock::duration const timeout, T predicate)
        {
            auto const until = std::chrono::high_resolution_clock::now() + timeout;

            while (!predicate())
            {
                auto const milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(until - std::chrono::high_resolution_clock::now()).count();

                if (milliseconds <= 0)
                {
                    return false;
                }

                if (!WINRT_IMPL_SleepConditionVariableSRW(&m_cv, x.get(), static_cast<uint32_t>(milliseconds), 0))
                {
                    return predicate();
                }
            }

            return true;
        }

        void notify_one() noexcept
        {
            WINRT_IMPL_WakeConditionVariable(&m_cv);
        }

        void notify_all() noexcept
        {
            WINRT_IMPL_WakeAllConditionVariable(&m_cv);
        }

    private:
        impl::condition_variable m_cv{};
    };
}

namespace winrt::impl
{
    template <> struct abi<Windows::Foundation::IUnknown>
    {
        struct __declspec(novtable) type
        {
            virtual int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept = 0;
            virtual uint32_t __stdcall AddRef() noexcept = 0;
            virtual uint32_t __stdcall Release() noexcept = 0;
        };
    };

    using unknown_abi = abi_t<Windows::Foundation::IUnknown>;

    template <> struct abi<Windows::Foundation::IInspectable>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall GetIids(uint32_t* count, guid** ids) noexcept = 0;
            virtual int32_t __stdcall GetRuntimeClassName(void** name) noexcept = 0;
            virtual int32_t __stdcall GetTrustLevel(Windows::Foundation::TrustLevel* level) noexcept = 0;
        };
    };

    using inspectable_abi = abi_t<Windows::Foundation::IInspectable>;

    template <> struct abi<Windows::Foundation::IActivationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ActivateInstance(void** instance) noexcept = 0;
        };
    };

    struct __declspec(novtable) IAgileObject : unknown_abi {};

    struct __declspec(novtable) IAgileReference : unknown_abi
    {
        virtual int32_t __stdcall Resolve(guid const& id, void** object) noexcept = 0;
    };

    struct __declspec(novtable) IMarshal : unknown_abi
    {
        virtual int32_t __stdcall GetUnmarshalClass(guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, guid* pCid) noexcept = 0;
        virtual int32_t __stdcall GetMarshalSizeMax(guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, uint32_t* pSize) noexcept = 0;
        virtual int32_t __stdcall MarshalInterface(void* pStm, guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags) noexcept = 0;
        virtual int32_t __stdcall UnmarshalInterface(void* pStm, guid const& riid, void** ppv) noexcept = 0;
        virtual int32_t __stdcall ReleaseMarshalData(void* pStm) noexcept = 0;
        virtual int32_t __stdcall DisconnectObject(uint32_t dwReserved) noexcept = 0;
    };

    struct __declspec(novtable) IGlobalInterfaceTable : unknown_abi
    {
        virtual int32_t __stdcall RegisterInterfaceInGlobal(void* object, guid const& iid, uint32_t* cookie) noexcept = 0;
        virtual int32_t __stdcall RevokeInterfaceFromGlobal(uint32_t cookie) noexcept = 0;
        virtual int32_t __stdcall GetInterfaceFromGlobal(uint32_t cookie, guid const& iid, void** object) noexcept = 0;
    };

    struct __declspec(novtable) IStaticLifetime : inspectable_abi
    {
        virtual int32_t __stdcall unused() noexcept = 0;
        virtual int32_t __stdcall GetCollection(void** value) noexcept = 0;
    };

    struct __declspec(novtable) IStaticLifetimeCollection : inspectable_abi
    {
        virtual int32_t __stdcall Lookup(void*, void**) noexcept = 0;
        virtual int32_t __stdcall unused() noexcept = 0;
        virtual int32_t __stdcall unused2() noexcept = 0;
        virtual int32_t __stdcall unused3() noexcept = 0;
        virtual int32_t __stdcall Insert(void*, void*, bool*) noexcept = 0;
        virtual int32_t __stdcall Remove(void*) noexcept = 0;
        virtual int32_t __stdcall unused4() noexcept = 0;
    };

    struct __declspec(novtable) IWeakReference : unknown_abi
    {
        virtual int32_t __stdcall Resolve(guid const& iid, void** objectReference) noexcept = 0;
    };

    struct __declspec(novtable) IWeakReferenceSource : unknown_abi
    {
        virtual int32_t __stdcall GetWeakReference(IWeakReference** weakReference) noexcept = 0;
    };

    struct __declspec(novtable) IRestrictedErrorInfo : unknown_abi
    {
        virtual int32_t __stdcall GetErrorDetails(bstr* description, int32_t* error, bstr* restrictedDescription, bstr* capabilitySid) noexcept = 0;
        virtual int32_t __stdcall GetReference(bstr* reference) noexcept = 0;
    };

    struct __declspec(novtable) IErrorInfo : unknown_abi
    {
        virtual int32_t __stdcall GetGUID(guid* value) noexcept = 0;
        virtual int32_t __stdcall GetSource(bstr* value) noexcept = 0;
        virtual int32_t __stdcall GetDescription(bstr* value) noexcept = 0;
        virtual int32_t __stdcall GetHelpFile(bstr* value) noexcept = 0;
        virtual int32_t __stdcall GetHelpContext(uint32_t* value) noexcept = 0;
    };

    struct __declspec(novtable) ILanguageExceptionErrorInfo2 : unknown_abi
    {
        virtual int32_t __stdcall GetLanguageException(void** exception) noexcept = 0;
        virtual int32_t __stdcall GetPreviousLanguageExceptionErrorInfo(ILanguageExceptionErrorInfo2** previous) noexcept = 0;
        virtual int32_t __stdcall CapturePropagationContext(void* exception) noexcept = 0;
        virtual int32_t __stdcall GetPropagationContextHead(ILanguageExceptionErrorInfo2** head) noexcept = 0;
    };

    struct ICallbackWithNoReentrancyToApplicationSTA;

    struct __declspec(novtable) IContextCallback : unknown_abi
    {
        virtual int32_t __stdcall ContextCallback(int32_t(__stdcall* callback)(com_callback_args*), com_callback_args* args, guid const& iid, int method, void* reserved) noexcept = 0;
    };

    struct __declspec(novtable) IServerSecurity : unknown_abi
    {
        virtual int32_t __stdcall QueryBlanket(uint32_t*, uint32_t*, wchar_t**, uint32_t*, uint32_t*, void**, uint32_t*) noexcept = 0;
        virtual int32_t __stdcall ImpersonateClient() noexcept = 0;
        virtual int32_t __stdcall RevertToSelf() noexcept = 0;
        virtual int32_t __stdcall IsImpersonating() noexcept = 0;
    };

    struct __declspec(novtable) IBufferByteAccess : unknown_abi
    {
        virtual int32_t __stdcall Buffer(uint8_t** value) noexcept = 0;
    };

    struct __declspec(novtable) IMemoryBufferByteAccess : unknown_abi
    {
        virtual int32_t __stdcall GetBuffer(uint8_t** value, uint32_t* capacity) noexcept = 0;
    };

    template <> struct abi<Windows::Foundation::TimeSpan>
    {
        using type = int64_t;
    };

    template <> struct abi<Windows::Foundation::DateTime>
    {
        using type = int64_t;
    };

    template <> inline constexpr guid guid_v<Windows::Foundation::IUnknown>{ 0x00000000, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<Windows::Foundation::IInspectable>{ 0xAF86E2E0, 0xB12D, 0x4C6A, { 0x9C,0x5A,0xD7,0xAA,0x65,0x10,0x1E,0x90 } };
    template <> inline constexpr guid guid_v<Windows::Foundation::IActivationFactory>{ 0x00000035, 0x0000, 0x0000, { 0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IAgileObject>{ 0x94EA2B94, 0xE9CC, 0x49E0, { 0xC0,0xFF,0xEE,0x64,0xCA,0x8F,0x5B,0x90 } };
    template <> inline constexpr guid guid_v<IAgileReference>{ 0xC03F6A43, 0x65A4, 0x9818, { 0x98,0x7E,0xE0,0xB8,0x10,0xD2,0xA6,0xF2 } };
    template <> inline constexpr guid guid_v<IMarshal>{ 0x00000003, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IGlobalInterfaceTable>{ 0x00000146, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IStaticLifetime>{ 0x17b0e613, 0x942a, 0x422d, { 0x90,0x4c,0xf9,0x0d,0xc7,0x1a,0x7d,0xae } };
    template <> inline constexpr guid guid_v<IStaticLifetimeCollection>{ 0x1b0d3570, 0x0877, 0x5ec2, { 0x8a,0x2c,0x3b,0x95,0x39,0x50,0x6a,0xca } };
    template <> inline constexpr guid guid_v<IWeakReference>{ 0x00000037, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IWeakReferenceSource>{ 0x00000038, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IRestrictedErrorInfo>{ 0x82BA7092, 0x4C88, 0x427D, { 0xA7,0xBC,0x16,0xDD,0x93,0xFE,0xB6,0x7E } };
    template <> inline constexpr guid guid_v<IErrorInfo>{ 0x1CF2B120, 0x547D, 0x101B, { 0x8E,0x65,0x08,0x00,0x2B,0x2B,0xD1,0x19 } };
    template <> inline constexpr guid guid_v<ILanguageExceptionErrorInfo2>{ 0x5746E5C4, 0x5B97, 0x424C, { 0xB6,0x20,0x28,0x22,0x91,0x57,0x34,0xDD } };
    template <> inline constexpr guid guid_v<ICallbackWithNoReentrancyToApplicationSTA>{ 0x0A299774, 0x3E4E, 0xFC42, { 0x1D,0x9D,0x72,0xCE,0xE1,0x05,0xCA,0x57 } };
    template <> inline constexpr guid guid_v<IContextCallback>{ 0x000001da, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IServerSecurity>{ 0x0000013E, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    template <> inline constexpr guid guid_v<IBufferByteAccess>{ 0x905a0fef, 0xbc53, 0x11df, { 0x8c,0x49,0x00,0x1e,0x4f,0xc6,0x86,0xda } };
    template <> inline constexpr guid guid_v<IMemoryBufferByteAccess>{ 0x5b0d3235, 0x4dba, 0x4d44, { 0x86,0x5e,0x8f,0x1d,0x0e,0x4f,0xd0,0x4d } };
}

namespace winrt::impl
{
#ifdef WINRT_DIAGNOSTICS

    struct factory_diagnostics_info
    {
        bool is_agile{ true };
        uint32_t requests{ 0 };
    };

    struct diagnostics_info
    {
        std::map<std::wstring_view, uint32_t> queries;
        std::map<std::wstring_view, factory_diagnostics_info> factories;
    };

    struct diagnostics_cache
    {
        template <typename T>
        void add_query()
        {
            slim_lock_guard const guard(m_lock);
            ++m_info.queries[name_of<T>()];
        }

        template <typename T>
        void add_factory()
        {
            slim_lock_guard const guard(m_lock);
            factory_diagnostics_info& factory = m_info.factories[name_of<T>()];
            ++factory.requests;
        }

        template <typename T>
        void non_agile_factory()
        {
            slim_lock_guard const guard(m_lock);
            factory_diagnostics_info& factory = m_info.factories[name_of<T>()];
            factory.is_agile = false;
        }

        auto get()
        {
            slim_lock_guard const guard(m_lock);
            return m_info;
        }

        auto detach()
        {
            slim_lock_guard const guard(m_lock);
            return std::move(m_info);
        }

    private:

        slim_mutex m_lock;
        diagnostics_info m_info;
    };

    inline diagnostics_cache& get_diagnostics_info() noexcept
    {
        static diagnostics_cache info;
        return info;
    }

#endif

    template <typename T>
    using com_ref = std::conditional_t<std::is_base_of_v<Windows::Foundation::IUnknown, T>, T, com_ptr<T>>;

    template <typename T, std::enable_if_t<is_implements_v<T>, int> = 0>
    com_ref<T> wrap_as_result(void* result)
    {
        return { &static_cast<produce<T, typename default_interface<T>::type>*>(result)->shim(), take_ownership_from_abi };
    }

    template <typename T, std::enable_if_t<!is_implements_v<T>, int> = 0>
    com_ref<T> wrap_as_result(void* result)
    {
        return { result, take_ownership_from_abi };
    }

    template<typename T>
    struct is_classic_com_interface : std::conjunction<std::is_base_of<::IUnknown, T>, std::negation<is_implements<T>>> {};

    template <typename T>
    struct is_com_interface : std::disjunction<std::is_base_of<Windows::Foundation::IUnknown, T>, std::is_base_of<unknown_abi, T>, is_implements<T>, is_classic_com_interface<T>> {};

    template <typename T>
    inline constexpr bool is_com_interface_v = is_com_interface<T>::value;

    // You must include <winrt/Windows.Foundation.h> to use this overload.
    template <typename To, typename From, std::enable_if_t<!is_com_interface_v<To>, int> = 0>
    auto as(From* ptr);

    template <typename To, typename From, std::enable_if_t<is_com_interface_v<To>, int> = 0>
    com_ref<To> as(From* ptr)
    {
#ifdef WINRT_DIAGNOSTICS
        get_diagnostics_info().add_query<To>();
#endif

        if (!ptr)
        {
            return nullptr;
        }

        void* result{};
        check_hresult(ptr->QueryInterface(guid_of<To>(), &result));
        return wrap_as_result<To>(result);
    }

    // You must include <winrt/Windows.Foundation.h> to use this overload.
    template <typename To, typename From, std::enable_if_t<!is_com_interface_v<To>, int> = 0>
    auto try_as(From* ptr) noexcept;

    template <typename To, typename From, std::enable_if_t<is_com_interface_v<To>, int> = 0>
    com_ref<To> try_as(From* ptr) noexcept
    {
#ifdef WINRT_DIAGNOSTICS
        get_diagnostics_info().add_query<To>();
#endif

        if (!ptr)
        {
            return nullptr;
        }

        void* result{};
        ptr->QueryInterface(guid_of<To>(), &result);
        return wrap_as_result<To>(result);
    }
}

WINRT_EXPORT namespace winrt::Windows::Foundation
{
    struct IUnknown
    {
        IUnknown() noexcept = default;
        IUnknown(std::nullptr_t) noexcept {}
        void* operator new(size_t) = delete;

        IUnknown(void* ptr, take_ownership_from_abi_t) noexcept : m_ptr(static_cast<impl::unknown_abi*>(ptr))
        {
        }

        IUnknown(IUnknown const& other) noexcept : m_ptr(other.m_ptr)
        {
            add_ref();
        }

        IUnknown(IUnknown&& other) noexcept : m_ptr(std::exchange(other.m_ptr, {}))
        {
        }

        ~IUnknown() noexcept
        {
            release_ref();
        }

        IUnknown& operator=(IUnknown const& other) noexcept
        {
            if (this != &other)
            {
                release_ref();
                m_ptr = other.m_ptr;
                add_ref();
            }

            return*this;
        }

        IUnknown& operator=(IUnknown&& other) noexcept
        {
            if (this != &other)
            {
                release_ref();
                m_ptr = std::exchange(other.m_ptr, {});
            }

            return*this;
        }

        explicit operator bool() const noexcept
        {
            return nullptr != m_ptr;
        }

        IUnknown& operator=(std::nullptr_t) noexcept
        {
            release_ref();
            return*this;
        }

        template <typename To>
        auto as() const
        {
            return impl::as<To>(m_ptr);
        }

        template <typename To>
        auto try_as() const noexcept
        {
            return impl::try_as<To>(m_ptr);
        }

        template <typename To>
        void as(To& to) const
        {
            to = as<impl::wrapped_type_t<To>>();
        }

        template <typename To>
        bool try_as(To& to) const noexcept
        {
            if constexpr (impl::is_com_interface_v<To> || !std::is_same_v<To, impl::wrapped_type_t<To>>)
            {
                to = try_as<impl::wrapped_type_t<To>>();
                return static_cast<bool>(to);
            }
            else
            {
                auto result = try_as<To>();
                to = result.has_value() ? result.value() : impl::empty_value<To>();
                return result.has_value();
            }
        }

        hresult as(guid const& id, void** result) const noexcept
        {
            return m_ptr->QueryInterface(id, result);
        }

        friend void swap(IUnknown& left, IUnknown& right) noexcept
        {
            std::swap(left.m_ptr, right.m_ptr);
        }

    private:

        void add_ref() const noexcept
        {
            if (m_ptr)
            {
                m_ptr->AddRef();
            }
        }

        void release_ref() noexcept
        {
            if (m_ptr)
            {
                unconditional_release_ref();
            }
        }

        WINRT_IMPL_NOINLINE void unconditional_release_ref() noexcept
        {
            std::exchange(m_ptr, {})->Release();
        }

        impl::unknown_abi* m_ptr{};
    };
}

WINRT_EXPORT namespace winrt
{
    template <typename T, std::enable_if_t<!std::is_base_of_v<Windows::Foundation::IUnknown, T>, int> = 0>
    auto get_abi(T const& object) noexcept
    {
        return reinterpret_cast<impl::abi_t<T> const&>(object);
    }

    template <typename T, std::enable_if_t<!std::is_base_of_v<Windows::Foundation::IUnknown, T>, int> = 0>
    auto put_abi(T& object) noexcept
    {
        if constexpr (!std::is_trivially_destructible_v<T>)
        {
            object = {};
        }

        return reinterpret_cast<impl::abi_t<T>*>(&object);
    }

    template <typename T, typename V, std::enable_if_t<!std::is_base_of_v<Windows::Foundation::IUnknown, T>, int> = 0>
    void copy_from_abi(T& object, V&& value)
    {
        object = reinterpret_cast<T const&>(value);
    }

    template <typename T, typename V, std::enable_if_t<!std::is_base_of_v<Windows::Foundation::IUnknown, T>, int> = 0>
    void copy_to_abi(T const& object, V& value)
    {
        reinterpret_cast<T&>(value) = object;
    }

    template <typename T, std::enable_if_t<!std::is_base_of_v<Windows::Foundation::IUnknown, std::decay_t<T>> && !std::is_convertible_v<T, std::wstring_view>, int> = 0>
    auto detach_abi(T&& object)
    {
        impl::abi_t<T> result{};
        reinterpret_cast<T&>(result) = std::move(object);
        return result;
    }

    inline void* get_abi(Windows::Foundation::IUnknown const& object) noexcept
    {
        return *(void**)(&object);
    }

    inline void** put_abi(Windows::Foundation::IUnknown& object) noexcept
    {
        object = nullptr;
        return reinterpret_cast<void**>(&object);
    }

    inline void attach_abi(Windows::Foundation::IUnknown& object, void* value) noexcept
    {
        object = nullptr;
        *put_abi(object) = value;
    }

    inline void* detach_abi(Windows::Foundation::IUnknown& object) noexcept
    {
        void* temp = get_abi(object);
        *reinterpret_cast<void**>(&object) = nullptr;
        return temp;
    }

    inline void* detach_abi(Windows::Foundation::IUnknown&& object) noexcept
    {
        void* temp = get_abi(object);
        *reinterpret_cast<void**>(&object) = nullptr;
        return temp;
    }

    constexpr void* detach_abi(std::nullptr_t) noexcept
    {
        return nullptr;
    }

    inline void copy_from_abi(Windows::Foundation::IUnknown& object, void* value) noexcept
    {
        object = nullptr;

        if (value)
        {
            static_cast<impl::unknown_abi*>(value)->AddRef();
            *put_abi(object) = value;
        }
    }

    inline void copy_to_abi(Windows::Foundation::IUnknown const& object, void*& value) noexcept
    {
        WINRT_ASSERT(value == nullptr);
        value = get_abi(object);

        if (value)
        {
            static_cast<impl::unknown_abi*>(value)->AddRef();
        }
    }

    inline ::IUnknown* get_unknown(Windows::Foundation::IUnknown const& object) noexcept
    {
        return static_cast<::IUnknown*>(get_abi(object));
    }
}

WINRT_EXPORT namespace winrt::Windows::Foundation
{
    inline bool operator==(IUnknown const& left, IUnknown const& right) noexcept
    {
        if (get_abi(left) == get_abi(right))
        {
            return true;
        }
        if (!left || !right)
        {
            return false;
        }
        return get_abi(left.try_as<IUnknown>()) == get_abi(right.try_as<IUnknown>());
    }

    inline bool operator!=(IUnknown const& left, IUnknown const& right) noexcept
    {
        return !(left == right);
    }

    inline bool operator<(IUnknown const& left, IUnknown const& right) noexcept
    {
        if (get_abi(left) == get_abi(right))
        {
            return false;
        }
        if (!left || !right)
        {
            return get_abi(left) < get_abi(right);
        }
        return get_abi(left.try_as<IUnknown>()) < get_abi(right.try_as<IUnknown>());
    }

    inline bool operator>(IUnknown const& left, IUnknown const& right) noexcept
    {
        return right < left;
    }

    inline bool operator<=(IUnknown const& left, IUnknown const& right) noexcept
    {
        return !(right < left);
    }

    inline bool operator>=(IUnknown const& left, IUnknown const& right) noexcept
    {
        return !(left < right);
    }

    struct IInspectable : IUnknown
    {
        IInspectable(std::nullptr_t = nullptr) noexcept {}
        IInspectable(void* ptr, take_ownership_from_abi_t) noexcept : IUnknown(ptr, take_ownership_from_abi) {}
    };
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct com_ptr;
}

namespace winrt::impl
{
    template <typename T, typename F, typename...Args>
    int32_t capture_to(void**result, F function, Args&& ...args)
    {
        return function(args..., guid_of<T>(), result);
    }

    template <typename T, typename O, typename M, typename...Args, std::enable_if_t<std::is_class_v<O> || std::is_union_v<O>, int> = 0>
    int32_t capture_to(void** result, O* object, M method, Args&& ...args)
    {
        return (object->*method)(args..., guid_of<T>(), result);
    }

    template <typename T, typename O, typename M, typename...Args>
    int32_t capture_to(void** result, com_ptr<O> const& object, M method, Args&& ...args);
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct com_ptr
    {
        using type = impl::abi_t<T>;

        com_ptr(std::nullptr_t = nullptr) noexcept {}

        com_ptr(void* ptr, take_ownership_from_abi_t) noexcept : m_ptr(static_cast<type*>(ptr))
        {
        }

        com_ptr(com_ptr const& other) noexcept : m_ptr(other.m_ptr)
        {
            add_ref();
        }

        template <typename U>
        com_ptr(com_ptr<U> const& other) noexcept : m_ptr(other.m_ptr)
        {
            add_ref();
        }

        template <typename U>
        com_ptr(com_ptr<U>&& other) noexcept : m_ptr(std::exchange(other.m_ptr, {}))
        {
        }

        ~com_ptr() noexcept
        {
            release_ref();
        }

        com_ptr& operator=(com_ptr const& other) noexcept
        {
            copy_ref(other.m_ptr);
            return*this;
        }

        com_ptr& operator=(com_ptr&& other) noexcept
        {
            if (this != &other)
            {
                release_ref();
                m_ptr = std::exchange(other.m_ptr, {});
            }

            return*this;
        }

        template <typename U>
        com_ptr& operator=(com_ptr<U> const& other) noexcept
        {
            copy_ref(other.m_ptr);
            return*this;
        }

        template <typename U>
        com_ptr& operator=(com_ptr<U>&& other) noexcept
        {
            release_ref();
            m_ptr = std::exchange(other.m_ptr, {});
            return*this;
        }

        explicit operator bool() const noexcept
        {
            return m_ptr != nullptr;
        }

        auto operator->() const noexcept
        {
            return m_ptr;
        }

        T& operator*() const noexcept
        {
            return *m_ptr;
        }

        type* get() const noexcept
        {
            return m_ptr;
        }

        type** put() noexcept
        {
            release_ref();
            return &m_ptr;
        }

        void** put_void() noexcept
        {
            return reinterpret_cast<void**>(put());
        }

        void attach(type* value) noexcept
        {
            release_ref();
            *put() = value;
        }

        type* detach() noexcept
        {
            return std::exchange(m_ptr, {});
        }

        friend void swap(com_ptr& left, com_ptr& right) noexcept
        {
            std::swap(left.m_ptr, right.m_ptr);
        }

        template <typename To>
        auto as() const
        {
            return impl::as<To>(m_ptr);
        }

        template <typename To>
        auto try_as() const noexcept
        {
            return impl::try_as<To>(m_ptr);
        }

        template <typename To>
        void as(To& to) const
        {
            to = as<impl::wrapped_type_t<To>>();
        }

        template <typename To>
        bool try_as(To& to) const noexcept
        {
            if constexpr (impl::is_com_interface_v<To> || !std::is_same_v<To, impl::wrapped_type_t<To>>)
            {
                to = try_as<impl::wrapped_type_t<To>>();
                return static_cast<bool>(to);
            }
            else
            {
                auto result = try_as<To>();
                to = result.has_value() ? result.value() : impl::empty_value<To>();
                return result.has_value();
            }
        }

        hresult as(guid const& id, void** result) const noexcept
        {
            return m_ptr->QueryInterface(id, result);
        }

        void copy_from(type* other) noexcept
        {
            copy_ref(other);
        }

        void copy_to(type** other) const noexcept
        {
            add_ref();
            *other = m_ptr;
        }

        template <typename...Args>
        bool try_capture(Args&&...args)
        {
            return impl::capture_to<T>(put_void(), std::forward<Args>(args)...) >= 0;
        }

        template <typename...Args>
        void capture(Args&&...args)
        {
            check_hresult(impl::capture_to<T>(put_void(), std::forward<Args>(args)...));
        }

    private:

        void copy_ref(type* other) noexcept
        {
            if (m_ptr != other)
            {
                release_ref();
                m_ptr = other;
                add_ref();
            }
        }

        void add_ref() const noexcept
        {
            if (m_ptr)
            {
                const_cast<std::remove_const_t<type>*>(m_ptr)->AddRef();
            }
        }

        void release_ref() noexcept
        {
            if (m_ptr)
            {
                unconditional_release_ref();
            }
        }

        WINRT_IMPL_NOINLINE void unconditional_release_ref() noexcept
        {
            std::exchange(m_ptr, {})->Release();
        }

        template <typename U>
        friend struct com_ptr;

        type* m_ptr{};
    };

    template <typename T, typename...Args>
    impl::com_ref<T> try_capture(Args&& ...args)
    {
        void* result{};
        impl::capture_to<T>(&result, std::forward<Args>(args)...);
        return { result, take_ownership_from_abi };
    }

    template <typename T, typename...Args>
    impl::com_ref<T> capture(Args&& ...args)
    {
        void* result{};
        check_hresult(impl::capture_to<T>(&result, std::forward<Args>(args)...));
        return { result, take_ownership_from_abi };
    }

    template <typename T>
    auto get_abi(com_ptr<T> const& object) noexcept
    {
        return object.get();
    }

    template <typename T>
    auto put_abi(com_ptr<T>& object) noexcept
    {
        return object.put_void();
    }

    template <typename T>
    void attach_abi(com_ptr<T>& object, impl::abi_t<T>* value) noexcept
    {
        object.attach(value);
    }

    template <typename T>
    auto detach_abi(com_ptr<T>& object) noexcept
    {
        return object.detach();
    }

    template <typename T>
    bool operator==(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return get_abi(left) == get_abi(right);
    }

    template <typename T>
    bool operator==(com_ptr<T> const& left, std::nullptr_t) noexcept
    {
        return get_abi(left) == nullptr;
    }

    template <typename T>
    bool operator==(std::nullptr_t, com_ptr<T> const& right) noexcept
    {
        return nullptr == get_abi(right);
    }

    template <typename T>
    bool operator!=(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return !(left == right);
    }

    template <typename T>
    bool operator!=(com_ptr<T> const& left, std::nullptr_t) noexcept
    {
        return !(left == nullptr);
    }

    template <typename T>
    bool operator!=(std::nullptr_t, com_ptr<T> const& right) noexcept
    {
        return !(nullptr == right);
    }

    template <typename T>
    bool operator<(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return get_abi(left) < get_abi(right);
    }

    template <typename T>
    bool operator>(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return right < left;
    }

    template <typename T>
    bool operator<=(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return !(right < left);
    }

    template <typename T>
    bool operator>=(com_ptr<T> const& left, com_ptr<T> const& right) noexcept
    {
        return !(left < right);
    }
}

namespace winrt::impl
{
    template <typename T, typename O, typename M, typename...Args>
    int32_t capture_to(void** result, com_ptr<O> const& object, M method, Args&& ...args)
    {
        return (object.get()->*(method))(args..., guid_of<T>(), result);
    }
}

template <typename T>
void** IID_PPV_ARGS_Helper(winrt::com_ptr<T>* ptr) noexcept
{
    return winrt::put_abi(*ptr);
}

namespace winrt::impl
{
    struct atomic_ref_count
    {
        atomic_ref_count() noexcept = default;

        explicit atomic_ref_count(uint32_t count) noexcept : m_count(count)
        {
        }

        uint32_t operator=(uint32_t count) noexcept
        {
            return m_count = count;
        }

        uint32_t operator++() noexcept
        {
            return m_count.fetch_add(1, std::memory_order_relaxed) + 1;
        }

        uint32_t operator--() noexcept
        {
            auto const remaining = m_count.fetch_sub(1, std::memory_order_release) - 1;

            if (remaining == 0)
            {
                std::atomic_thread_fence(std::memory_order_acquire);
            }
            else if (remaining < 0)
            {
                abort();
            }

            return remaining;
        }

        operator uint32_t() const noexcept
        {
            return m_count;
        }

    private:

        std::atomic<int32_t> m_count;
    };

    constexpr uint32_t hstring_reference_flag{ 1 };

    struct hstring_header
    {
        uint32_t flags;
        uint32_t length;
        uint32_t padding1;
        uint32_t padding2;
        wchar_t const* ptr;
    };

    struct shared_hstring_header : hstring_header
    {
        atomic_ref_count count;
        wchar_t buffer[1];
    };

    inline void release_hstring(hstring_header* handle) noexcept
    {
        WINRT_ASSERT((handle->flags & hstring_reference_flag) == 0);

        if (0 == --static_cast<shared_hstring_header*>(handle)->count)
        {
            WINRT_IMPL_HeapFree(WINRT_IMPL_GetProcessHeap(), 0, handle);
        }
    }

    inline shared_hstring_header* precreate_hstring_on_heap(uint32_t length)
    {
        WINRT_ASSERT(length != 0);
        uint64_t bytes_required = static_cast<uint64_t>(sizeof(shared_hstring_header)) + static_cast<uint64_t>(sizeof(wchar_t)) * static_cast<uint64_t>(length);

        if (bytes_required > UINT_MAX)
        {
            throw std::invalid_argument("length");
        }

        auto header = static_cast<shared_hstring_header*>(WINRT_IMPL_HeapAlloc(WINRT_IMPL_GetProcessHeap(), 0, static_cast<std::size_t>(bytes_required)));

        if (!header)
        {
            throw std::bad_alloc();
        }

        header->flags = 0;
        header->length = length;
        header->ptr = header->buffer;
        header->count = 1;
        header->buffer[length] = 0;
        return header;
    }

    inline hstring_header* create_hstring_on_heap(wchar_t const* value, uint32_t length)
    {
        if (!length)
        {
            return nullptr;
        }

        auto header = precreate_hstring_on_heap(length);
        memcpy_s(header->buffer, sizeof(wchar_t) * length, value, sizeof(wchar_t) * length);
        return header;
    }

    inline void create_hstring_on_stack(hstring_header& header, wchar_t const* value, uint32_t length) noexcept
    {
        WINRT_ASSERT(value);
        WINRT_ASSERT(length != 0);

        if (value[length] != 0)
        {
            abort();
        }

        header.flags = hstring_reference_flag;
        header.length = length;
        header.ptr = value;
    }

    inline hstring_header* duplicate_hstring(hstring_header* handle)
    {
        if (!handle)
        {
            return nullptr;
        }
        else if ((handle->flags & hstring_reference_flag) == 0)
        {
            ++static_cast<shared_hstring_header*>(handle)->count;
            return handle;
        }
        else
        {
            return create_hstring_on_heap(handle->ptr, handle->length);
        }
    }

    struct hstring_traits
    {
        using type = hstring_header*;

        static void close(type value) noexcept
        {
            release_hstring(value);
        }

        static constexpr type invalid() noexcept
        {
            return nullptr;
        }
    };
}

WINRT_EXPORT namespace winrt
{
    struct hstring
    {
        using value_type = wchar_t;
        using size_type = uint32_t;
        using const_reference = value_type const&;
        using pointer = value_type*;
        using const_pointer = value_type const*;
        using const_iterator = const_pointer;
        using const_reverse_iterator = std::reverse_iterator<const_iterator>;

        hstring() noexcept = default;

        hstring(void* ptr, take_ownership_from_abi_t) noexcept : m_handle(static_cast<impl::hstring_header*>(ptr))
        {
        }

        hstring(hstring const& value) :
            m_handle(impl::duplicate_hstring(value.m_handle.get()))
        {}

        hstring& operator=(hstring const& value)
        {
            m_handle.attach(impl::duplicate_hstring(value.m_handle.get()));
            return*this;
        }

        hstring(hstring&&) noexcept = default;
        hstring& operator=(hstring&&) = default;
        hstring(std::nullptr_t) = delete;
        hstring& operator=(std::nullptr_t) = delete;

        hstring(std::initializer_list<wchar_t> value) :
            hstring(value.begin(), static_cast<uint32_t>(value.size()))
        {}

        hstring(wchar_t const* value) :
            hstring(std::wstring_view(value))
        {}

        hstring(wchar_t const* value, size_type size) :
            m_handle(impl::create_hstring_on_heap(value, size))
        {}

        explicit hstring(std::wstring_view const& value) :
            hstring(value.data(), static_cast<size_type>(value.size()))
        {}

        hstring& operator=(std::wstring_view const& value)
        {
            return *this = hstring{ value };
        }

        hstring& operator=(wchar_t const* const value)
        {
            return *this = hstring{ value };
        }

        hstring& operator=(std::initializer_list<wchar_t> value)
        {
            return *this = hstring{ value };
        }

        void clear() noexcept
        {
            m_handle.close();
        }

        operator std::wstring_view() const noexcept
        {
            if (m_handle)
            {
                return{ m_handle.get()->ptr, m_handle.get()->length };
            }
            else
            {
                return { L"", 0 };
            }
        }

        const_reference operator[](size_type pos) const noexcept
        {
            WINRT_ASSERT(pos < size());
            return*(begin() + pos);
        }

        const_reference front() const noexcept
        {
            WINRT_ASSERT(!empty());
            return*begin();
        }

        const_reference back() const noexcept
        {
            WINRT_ASSERT(!empty());
            return*(end() - 1);
        }

        const_pointer data() const noexcept
        {
            return c_str();
        }

        const_pointer c_str() const noexcept
        {
            if (!empty())
            {
                return begin();
            }
            else
            {
                return L"";
            }
        }

        const_iterator begin() const noexcept
        {
            if (m_handle)
            {
                return m_handle.get()->ptr;
            }
            else
            {
                return {};
            }
        }

        const_iterator cbegin() const noexcept
        {
            return begin();
        }

        const_iterator end() const noexcept
        {
            if (m_handle)
            {
                return m_handle.get()->ptr + m_handle.get()->length;
            }
            else
            {
                return {};
            }
        }

        const_iterator cend() const noexcept
        {
            return end();
        }

        const_reverse_iterator rbegin() const noexcept
        {
            return const_reverse_iterator(end());
        }

        const_reverse_iterator crbegin() const noexcept
        {
            return rbegin();
        }

        const_reverse_iterator rend() const noexcept
        {
            return const_reverse_iterator(begin());
        }

        const_reverse_iterator crend() const noexcept
        {
            return rend();
        }
        
#ifdef __cpp_lib_starts_ends_with
        bool starts_with(wchar_t const value) const noexcept
        {
            return operator std::wstring_view().starts_with(value);
        }

        bool starts_with(std::wstring_view const another) const noexcept
        {
            return operator std::wstring_view().starts_with(another);
        }

        bool starts_with(const wchar_t* const pointer) const noexcept
        {
            return operator std::wstring_view().starts_with(pointer);
        }

        bool ends_with(wchar_t const value) const noexcept
        {
            return operator std::wstring_view().ends_with(value);
        }

        bool ends_with(std::wstring_view const another) const noexcept
        {
            return operator std::wstring_view().ends_with(another);
        }

        bool ends_with(const wchar_t* const pointer) const noexcept
        {
            return operator std::wstring_view().ends_with(pointer);
        }
#endif
        
        bool empty() const noexcept
        {
            return !m_handle;
        }

        size_type size() const noexcept
        {
            if (m_handle)
            {
                return m_handle.get()->length;
            }
            else
            {
                return 0;
            }
        }

        friend void swap(hstring& left, hstring& right) noexcept
        {
            swap(left.m_handle, right.m_handle);
        }

    private:

        handle_type<impl::hstring_traits> m_handle;
    };

    inline void* get_abi(hstring const& object) noexcept
    {
        return *(void**)(&object);
    }

    inline void** put_abi(hstring& object) noexcept
    {
        object.clear();
        return reinterpret_cast<void**>(&object);
    }

    inline void attach_abi(hstring& object, void* value) noexcept
    {
        object.clear();
        *put_abi(object) = value;
    }

    inline void* detach_abi(hstring& object) noexcept
    {
        void* temp = get_abi(object);
        *reinterpret_cast<void**>(&object) = nullptr;
        return temp;
    }

    inline void* detach_abi(hstring&& object) noexcept
    {
        return detach_abi(object);
    }

    inline void copy_from_abi(hstring& object, void* value)
    {
        attach_abi(object, impl::duplicate_hstring(static_cast<impl::hstring_header*>(value)));
    }

    inline void copy_to_abi(hstring const& object, void*& value)
    {
        WINRT_ASSERT(value == nullptr);
        value = impl::duplicate_hstring(static_cast<impl::hstring_header*>(get_abi(object)));
    }

    inline void* detach_abi(std::wstring_view const& value)
    {
        return impl::create_hstring_on_heap(value.data(), static_cast<uint32_t>(value.size()));
    }

    inline void* detach_abi(wchar_t const* const value)
    {
        return impl::create_hstring_on_heap(value, static_cast<uint32_t>(wcslen(value)));
    }
}

#ifdef __cpp_lib_format
template<>
struct std::formatter<winrt::hstring, wchar_t> : std::formatter<std::wstring_view, wchar_t> {};
#endif

namespace winrt::impl
{
    template <> struct abi<hstring>
    {
        using type = void*;
    };

    template <> struct category<hstring>
    {
        using type = basic_category;
    };

    struct hstring_builder
    {
        hstring_builder(hstring_builder const&) = delete;
        hstring_builder& operator=(hstring_builder const&) = delete;

        explicit hstring_builder(uint32_t const size) :
            m_handle(impl::precreate_hstring_on_heap(size))
        {
        }

        wchar_t* data() noexcept
        {
            return const_cast<wchar_t*>(m_handle.get()->ptr);
        }

        hstring to_hstring()
        {
            return { m_handle.detach(), take_ownership_from_abi };
        }

    private:

        handle_type<impl::hstring_traits> m_handle;
    };

    template <typename T>
    struct bind_in
    {
        bind_in(T const& object) noexcept : object(object)
        {
        }

        T const& object;

        template <typename R>
        operator R const& () const noexcept
        {
            return reinterpret_cast<R const&>(object);
        }
    };

    template <typename T>
    struct bind_out
    {
        bind_out(T& object) noexcept : object(object)
        {
        }

        T& object;

        operator void** () const noexcept
        {
            if constexpr (std::is_same_v<T, hstring>)
            {
                object.clear();
            }
            else
            {
                object = nullptr;
            }

            return (void**)(&object);
        }

        template <typename R>
        operator R* () const noexcept
        {
            if constexpr (!std::is_trivially_destructible_v<T>)
            {
                object = {};
            }

            return reinterpret_cast<R*>(&object);
        }
    };

    template <typename T>
    inline hstring hstring_convert(T value)
    {
        static_assert(std::is_arithmetic_v<T>);
        char temp[32];
        std::to_chars_result result;
        if constexpr (std::is_integral_v<T>)
        {
            result = std::to_chars(std::begin(temp), std::end(temp), value);
        }
        else
        {
            // Floating point
            result = std::to_chars(std::begin(temp), std::end(temp), value, std::chars_format::general);
        }
        WINRT_ASSERT(result.ec == std::errc{});
        wchar_t buffer[32];
        auto end = std::copy(std::begin(temp), result.ptr, buffer);
        return hstring{ std::wstring_view{ buffer, static_cast<std::size_t>(end - buffer)} };
    }
}

WINRT_EXPORT namespace winrt
{
    inline bool embedded_null(hstring const& value) noexcept
    {
        return std::any_of(value.begin(), value.end(), [](auto item)
            {
                return item == 0;
            });
    }

    inline hstring to_hstring(uint8_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(int8_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(uint16_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(int16_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(uint32_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(int32_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(uint64_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(int64_t value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(float value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(double value)
    {
        return impl::hstring_convert(value);
    }

    inline hstring to_hstring(char16_t value)
    {
        wchar_t buffer[2] = { value, 0 };
        return hstring{ std::wstring_view{ buffer, 1 } };
    }

    inline hstring to_hstring(hstring const& value) noexcept
    {
        return value;
    }

    template <typename T, std::enable_if_t<std::is_same_v<T, bool>, int> = 0>
    hstring to_hstring(T const value)
    {
        if (value)
        {
            return hstring{ L"true" };
        }
        else
        {
            return hstring{ L"false" };
        }
    }

    inline hstring to_hstring(guid const& value)
    {
        wchar_t buffer[40];
        //{00000000-0000-0000-0000-000000000000}
        swprintf_s(buffer, L"{%08x-%04hx-%04hx-%02hhx%02hhx-%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx}",
            value.Data1, value.Data2, value.Data3, value.Data4[0], value.Data4[1],
            value.Data4[2], value.Data4[3], value.Data4[4], value.Data4[5], value.Data4[6], value.Data4[7]);
        return hstring{ buffer };
    }

    template <typename T, std::enable_if_t<std::is_convertible_v<T, std::string_view>, int> = 0>
    hstring to_hstring(T const& value)
    {
        std::string_view const view(value);
        int const size = WINRT_IMPL_MultiByteToWideChar(65001 /*CP_UTF8*/, 0, view.data(), static_cast<int32_t>(view.size()), nullptr, 0);

        if (size == 0)
        {
            return{};
        }

        impl::hstring_builder result(size);
        WINRT_VERIFY_(size, WINRT_IMPL_MultiByteToWideChar(65001 /*CP_UTF8*/, 0, view.data(), static_cast<int32_t>(view.size()), result.data(), size));
        return result.to_hstring();
    }

    inline std::string to_string(std::wstring_view value)
    {
        int const size = WINRT_IMPL_WideCharToMultiByte(65001 /*CP_UTF8*/, 0, value.data(), static_cast<int32_t>(value.size()), nullptr, 0, nullptr, nullptr);

        if (size == 0)
        {
            return{};
        }

        std::string result(size, '?');
        WINRT_VERIFY_(size, WINRT_IMPL_WideCharToMultiByte(65001 /*CP_UTF8*/, 0, value.data(), static_cast<int32_t>(value.size()), result.data(), size, nullptr, nullptr));
        return result;
    }
}

WINRT_EXPORT namespace winrt::param
{
    struct hstring
    {
#pragma warning(suppress: 26495)
        hstring() noexcept : m_handle(nullptr) {}
        hstring(hstring const& values) = delete;
        hstring& operator=(hstring const& values) = delete;
        hstring(std::nullptr_t) = delete;

#pragma warning(suppress: 26495)
        hstring(winrt::hstring const& value) noexcept : m_handle(get_abi(value))
        {
        }

        hstring(std::wstring_view const& value) noexcept
        {
            create_string_reference(value.data(), value.size());
        }

        hstring(std::wstring const& value) noexcept
        {
            create_string_reference(value.data(), value.size());
        }

        hstring(wchar_t const* const value) noexcept
        {
            create_string_reference(value, wcslen(value));
        }

        operator winrt::hstring const&() const noexcept
        {
            return *reinterpret_cast<winrt::hstring const*>(this);
        }

    private:
        void create_string_reference(wchar_t const* const data, size_t size) noexcept
        {
            WINRT_ASSERT(size < UINT_MAX);
            auto size32 = static_cast<uint32_t>(size);

            if (size32 == 0)
            {
                m_handle = nullptr;
            }
            else
            {
                impl::create_hstring_on_stack(m_header, data, size32);
                m_handle = &m_header;
            }
        }

        void* m_handle;
        impl::hstring_header m_header;
    };

    inline void* get_abi(hstring const& object) noexcept
    {
        return *(void**)(&object);
    }
}

namespace winrt::impl
{
    template <typename T>
    using param_type = std::conditional_t<std::is_same_v<T, hstring>, param::hstring, T>;
}

WINRT_EXPORT namespace winrt
{
    inline bool operator==(hstring const& left, hstring const& right) noexcept
    {
        return std::wstring_view(left) == std::wstring_view(right);
    }

    inline bool operator==(hstring const& left, std::wstring const& right) noexcept
    {
        return std::wstring_view(left) == right;
    }

    inline bool operator==(std::wstring const& left, hstring const& right) noexcept
    {
        return left == std::wstring_view(right);
    }

    inline bool operator==(hstring const& left, wchar_t const* right) noexcept
    {
        return std::wstring_view(left) == right;
    }

    inline bool operator==(wchar_t const* left, hstring const& right) noexcept
    {
        return left == std::wstring_view(right);
    }

    bool operator==(hstring const& left, std::nullptr_t) = delete;

    bool operator==(std::nullptr_t, hstring const& right) = delete;

    inline bool operator<(hstring const& left, hstring const& right) noexcept
    {
        return std::wstring_view(left) < std::wstring_view(right);
    }

    inline bool operator<(std::wstring const& left, hstring const& right) noexcept
    {
        return left < std::wstring_view(right);
    }

    inline bool operator<(hstring const& left, std::wstring const& right) noexcept
    {
        return std::wstring_view(left) < right;
    }

    inline bool operator<(hstring const& left, wchar_t const* right) noexcept
    {
        return std::wstring_view(left) < right;
    }

    inline bool operator<(wchar_t const* left, hstring const& right) noexcept
    {
        return left < std::wstring_view(right);
    }

    bool operator<(hstring const& left, nullptr_t) = delete;

    bool operator<(nullptr_t, hstring const& right) = delete;
    inline bool operator!=(hstring const& left, hstring const& right) noexcept { return !(left == right); }
    inline bool operator>(hstring const& left, hstring const& right) noexcept { return right < left; }
    inline bool operator<=(hstring const& left, hstring const& right) noexcept { return !(right < left); }
    inline bool operator>=(hstring const& left, hstring const& right) noexcept { return !(left < right); }

    inline bool operator!=(hstring const& left, std::wstring const& right) noexcept { return !(left == right); }
    inline bool operator>(hstring const& left, std::wstring const& right) noexcept { return right < left; }
    inline bool operator<=(hstring const& left, std::wstring const& right) noexcept { return !(right < left); }
    inline bool operator>=(hstring const& left, std::wstring const& right) noexcept { return !(left < right); }

    inline bool operator!=(std::wstring const& left, hstring const& right) noexcept { return !(left == right); }
    inline bool operator>(std::wstring const& left, hstring const& right) noexcept { return right < left; }
    inline bool operator<=(std::wstring const& left, hstring const& right) noexcept { return !(right < left); }
    inline bool operator>=(std::wstring const& left, hstring const& right) noexcept { return !(left < right); }

    inline bool operator!=(hstring const& left, wchar_t const* right) noexcept { return !(left == right); }
    inline bool operator>(hstring const& left, wchar_t const* right) noexcept { return right < left; }
    inline bool operator<=(hstring const& left, wchar_t const* right) noexcept { return !(right < left); }
    inline bool operator>=(hstring const& left, wchar_t const* right) noexcept { return !(left < right); }

    inline bool operator!=(wchar_t const* left, hstring const& right) noexcept { return !(left == right); }
    inline bool operator>(wchar_t const* left, hstring const& right) noexcept { return right < left; }
    inline bool operator<=(wchar_t const* left, hstring const& right) noexcept { return !(right < left); }
    inline bool operator>=(wchar_t const* left, hstring const& right) noexcept { return !(left < right); }

    bool operator!=(hstring const& left, std::nullptr_t right) = delete;
    bool operator>(hstring const& left, std::nullptr_t right) = delete;
    bool operator<=(hstring const& left, std::nullptr_t right) = delete;
    bool operator>=(hstring const& left, std::nullptr_t right) = delete;

    bool operator!=(std::nullptr_t left, hstring const& right) = delete;
    bool operator>(std::nullptr_t left, hstring const& right) = delete;
    bool operator<=(std::nullptr_t left, hstring const& right) = delete;
    bool operator>=(std::nullptr_t left, hstring const& right) = delete;
}

namespace winrt::impl
{
    inline hstring concat_hstring(std::wstring_view const& left, std::wstring_view const& right)
    {
        auto size = static_cast<uint32_t>(left.size() + right.size());
        if (size == 0)
        {
            return{};
        }
        hstring_builder text(size);
        memcpy_s(text.data(), left.size() * sizeof(wchar_t), left.data(), left.size() * sizeof(wchar_t));
        memcpy_s(text.data() + left.size(), right.size() * sizeof(wchar_t), right.data(), right.size() * sizeof(wchar_t));
        return text.to_hstring();
    }
}

WINRT_EXPORT namespace winrt
{
    inline hstring operator+(hstring const& left, hstring const& right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(hstring const& left, std::wstring const& right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(std::wstring const& left, hstring const& right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(hstring const& left, wchar_t const* right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(wchar_t const* left, hstring const& right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(hstring const& left, wchar_t right)
    {
        return impl::concat_hstring(left, std::wstring_view(&right, 1));
    }

    inline hstring operator+(wchar_t left, hstring const& right)
    {
        return impl::concat_hstring(std::wstring_view(&left, 1), right);
    }

    hstring operator+(hstring const& left, std::nullptr_t) = delete;

    hstring operator+(std::nullptr_t, hstring const& right) = delete;

    inline hstring operator+(hstring const& left, std::wstring_view const& right)
    {
        return impl::concat_hstring(left, right);
    }

    inline hstring operator+(std::wstring_view const& left, hstring const& right)
    {
        return impl::concat_hstring(left, right);
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct array_view
    {
        using value_type = T;
        using size_type = uint32_t;
        using reference = value_type&;
        using const_reference = value_type const&;
        using pointer = value_type*;
        using const_pointer = value_type const*;
        using iterator = value_type*;
        using const_iterator = value_type const*;
        using reverse_iterator = std::reverse_iterator<iterator>;
        using const_reverse_iterator = std::reverse_iterator<const_iterator>;

        array_view() noexcept = default;

        array_view(pointer data, size_type size) noexcept :
            m_data(data),
            m_size(size)
        {}

        array_view(pointer first, pointer last) noexcept :
            m_data(first),
            m_size(static_cast<size_type>(last - first))
        {}

        array_view(std::initializer_list<value_type> value) noexcept :
            array_view(value.begin(), static_cast<size_type>(value.size()))
        {}

        template <typename C, size_type N>
        array_view(C(&value)[N]) noexcept :
            array_view(value, N)
        {}

        template <typename C>
        array_view(std::vector<C>& value) noexcept :
            array_view(data(value), static_cast<size_type>(value.size()))
        {
        }

        template <typename C>
        array_view(std::vector<C> const& value) noexcept :
            array_view(data(value), static_cast<size_type>(value.size()))
        {
        }

        template <typename C, size_t N>
        array_view(std::array<C, N>& value) noexcept :
            array_view(value.data(), static_cast<size_type>(value.size()))
        {}

        template <typename C, size_t N>
        array_view(std::array<C, N> const& value) noexcept :
            array_view(value.data(), static_cast<size_type>(value.size()))
        {}

        template <typename OtherType>
        array_view(array_view<OtherType> const& other,
            std::enable_if_t<std::is_convertible_v<OtherType(*)[], T(*)[]>, int> = 0) noexcept :
            array_view(other.data(), other.size())
        {}

        reference operator[](size_type const pos) noexcept
        {
            WINRT_ASSERT(pos < size());
            return m_data[pos];
        }

        const_reference operator[](size_type const pos) const noexcept
        {
            WINRT_ASSERT(pos < size());
            return m_data[pos];
        }

        reference at(size_type const pos)
        {
            if (size() <= pos)
            {
                throw std::out_of_range("Invalid array subscript");
            }

            return m_data[pos];
        }

        const_reference at(size_type const pos) const
        {
            if (size() <= pos)
            {
                throw std::out_of_range("Invalid array subscript");
            }

            return m_data[pos];
        }

        reference front() noexcept
        {
            WINRT_ASSERT(m_size > 0);
            return*m_data;
        }

        const_reference front() const noexcept
        {
            WINRT_ASSERT(m_size > 0);
            return*m_data;
        }

        reference back() noexcept
        {
            WINRT_ASSERT(m_size > 0);
            return m_data[m_size - 1];
        }

        const_reference back() const noexcept
        {
            WINRT_ASSERT(m_size > 0);
            return m_data[m_size - 1];
        }

        pointer data() const noexcept
        {
            return m_data;
        }

        iterator begin() noexcept
        {
            return m_data;
        }

        const_iterator begin() const noexcept
        {
            return m_data;
        }

        const_iterator cbegin() const noexcept
        {
            return m_data;
        }

        iterator end() noexcept
        {
            return m_data + m_size;
        }

        const_iterator end() const noexcept
        {
            return m_data + m_size;
        }

        const_iterator cend() const noexcept
        {
            return m_data + m_size;
        }

        reverse_iterator rbegin() noexcept
        {
            return reverse_iterator(end());
        }

        const_reverse_iterator rbegin() const noexcept
        {
            return const_reverse_iterator(end());
        }

        const_reverse_iterator crbegin() const noexcept
        {
            return rbegin();
        }

        reverse_iterator rend() noexcept
        {
            return reverse_iterator(begin());
        }

        const_reverse_iterator rend() const noexcept
        {
            return const_reverse_iterator(begin());
        }

        const_reverse_iterator crend() const noexcept
        {
            return rend();
        }

        bool empty() const noexcept
        {
            return m_size == 0;
        }

        size_type size() const noexcept
        {
            return m_size;
        }

    protected:

        pointer m_data{ nullptr };
        size_type m_size{ 0 };

    private:

        template <typename C>
        auto data(std::vector<C> const& value) noexcept
        {
            static_assert(!std::is_same_v<C, bool>, "Cannot use std::vector<bool> as an array_view. Consider std::array or std::unique_ptr<bool[]>.");
            return value.data();
        }

        template <typename C>
        auto data(std::vector<C>& value) noexcept
        {
            static_assert(!std::is_same_v<C, bool>, "Cannot use std::vector<bool> as an array_view. Consider std::array or std::unique_ptr<bool[]>.");
            return value.data();
        }
    };

    template <typename C, size_t N> array_view(C(&value)[N]) -> array_view<C>;
    template <typename C> array_view(std::vector<C>& value) -> array_view<C>;
    template <typename C> array_view(std::vector<C> const& value) -> array_view<C const>;
    template <typename C, size_t N> array_view(std::array<C, N>& value) -> array_view<C>;
    template <typename C, size_t N> array_view(std::array<C, N> const& value) -> array_view<C const>;

    template <typename T>
    struct com_array : array_view<T>
    {
        using typename array_view<T>::value_type;
        using typename array_view<T>::size_type;
        using typename array_view<T>::reference;
        using typename array_view<T>::const_reference;
        using typename array_view<T>::pointer;
        using typename array_view<T>::const_pointer;
        using typename array_view<T>::iterator;
        using typename array_view<T>::const_iterator;
        using typename array_view<T>::reverse_iterator;
        using typename array_view<T>::const_reverse_iterator;

        com_array(com_array const&) = delete;
        com_array& operator=(com_array const&) = delete;

        com_array() noexcept = default;

        explicit com_array(size_type const count) :
            com_array(count, value_type())
        {}

        com_array(void* ptr, uint32_t const count, take_ownership_from_abi_t) noexcept :
            array_view<T>(static_cast<value_type*>(ptr), static_cast<value_type*>(ptr) + count)
        {
        }

        com_array(size_type const count, value_type const& value)
        {
            alloc(count);
            std::uninitialized_fill_n(this->m_data, count, value);
        }

        template <typename InIt, typename = std::void_t<typename std::iterator_traits<InIt>::difference_type>>
        com_array(InIt first, InIt last)
        {
            alloc(static_cast<size_type>(std::distance(first, last)));
            std::uninitialized_copy(first, last, this->begin());
        }

        template <typename U>
        explicit com_array(std::vector<U> const& value) :
            com_array(value.begin(), value.end())
        {}

        template <typename U, size_t N>
        explicit com_array(std::array<U, N> const& value) :
            com_array(value.begin(), value.end())
        {}

        template <typename U, size_t N>
        explicit com_array(U const(&value)[N]) :
            com_array(value, value + N)
        {}

        com_array(std::initializer_list<value_type> value) :
            com_array(value.begin(), value.end())
        {}

        template <typename U, typename = std::enable_if_t<std::is_convertible_v<U, T>>>
        com_array(std::initializer_list<U> value) :
            com_array(value.begin(), value.end())
        {}

        com_array(com_array&& other) noexcept :
            array_view<T>(other.m_data, other.m_size)
        {
            other.m_data = nullptr;
            other.m_size = 0;
        }

        com_array& operator=(com_array&& other) noexcept
        {
            clear();
            this->m_data = other.m_data;
            this->m_size = other.m_size;
            other.m_data = nullptr;
            other.m_size = 0;
            return*this;
        }

        ~com_array() noexcept
        {
            clear();
        }

        void clear() noexcept
        {
            if (this->m_data == nullptr) { return; }

            std::destroy(this->begin(), this->end());

            WINRT_IMPL_CoTaskMemFree(this->m_data);
            this->m_data = nullptr;
            this->m_size = 0;
        }

        friend void swap(com_array& left, com_array& right) noexcept
        {
            std::swap(left.m_data, right.m_data);
            std::swap(left.m_size, right.m_size);
        }

    private:

        void alloc(size_type const size)
        {
            WINRT_ASSERT(this->empty());

            if (0 != size)
            {
                this->m_data = static_cast<value_type*>(WINRT_IMPL_CoTaskMemAlloc(size * sizeof(value_type)));

                if (this->m_data == nullptr)
                {
                    throw std::bad_alloc();
                }

                this->m_size = size;
            }
        }
    };

    template <typename C> com_array(uint32_t, C const&) -> com_array<std::decay_t<C>>;
    template <typename InIt, typename = std::void_t<typename std::iterator_traits<InIt>::difference_type>>
    com_array(InIt, InIt) -> com_array<std::decay_t<typename std::iterator_traits<InIt>::value_type>>;
    template <typename C> com_array(std::vector<C> const&) -> com_array<std::decay_t<C>>;
    template <size_t N, typename C> com_array(std::array<C, N> const&) -> com_array<std::decay_t<C>>;
    template <size_t N, typename C> com_array(C const(&)[N]) -> com_array<std::decay_t<C>>;
    template <typename C> com_array(std::initializer_list<C>) -> com_array<std::decay_t<C>>;

    namespace impl
    {
        template <typename T, typename U>
        inline constexpr bool array_comparable = std::is_same_v<std::remove_cv_t<T>, std::remove_cv_t<U>>;
    }

    template <typename T, typename U, 
        std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator==(array_view<T> const& left, array_view<U> const& right) noexcept
    {
        return std::equal(left.begin(), left.end(), right.begin(), right.end());
    }

    template <typename T, typename U,
        std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator<(array_view<T> const& left, array_view<U> const& right) noexcept
    {
        return std::lexicographical_compare(left.begin(), left.end(), right.begin(), right.end());
    }

    template <typename T, typename U, std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator!=(array_view<T> const& left, array_view<U> const& right) noexcept { return !(left == right); }
    template <typename T, typename U,std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator>(array_view<T> const& left, array_view<U> const& right) noexcept { return right < left; }
    template <typename T, typename U,std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator<=(array_view<T> const& left, array_view<U> const& right) noexcept { return !(right < left); }
    template <typename T, typename U, std::enable_if_t<impl::array_comparable<T, U>, int> = 0>
    bool operator>=(array_view<T> const& left, array_view<U> const& right) noexcept { return !(left < right); }

    template <typename T>
    auto get_abi(array_view<T> object) noexcept
    {
        auto data = object.size() ? object.data() : (T*)alignof(T);

        if constexpr (std::is_base_of_v<Windows::Foundation::IUnknown, T>)
        {
            return (void**)data;
        }
        else
        {
            return reinterpret_cast<impl::arg_out<std::remove_const_t<T>>>(const_cast<std::remove_const_t<T>*>(data));
        }
    }

    template <typename T>
    auto put_abi(array_view<T> object) noexcept
    {
        if constexpr (!std::is_trivially_destructible_v<T>)
        {
            std::fill(object.begin(), object.end(), impl::empty_value<T>());
        }

        return get_abi(object);
    }

    template<typename T>
    auto put_abi(com_array<T>& object) noexcept
    {
        object.clear();
        return reinterpret_cast<impl::arg_out<T>*>(&object);
    }

    template <typename T>
    auto detach_abi(com_array<T>& object) noexcept
    {
        std::pair<uint32_t, impl::arg_out<T>> result(object.size(), *reinterpret_cast<impl::arg_out<T>*>(&object));
        memset(&object, 0, sizeof(com_array<T>));
        return result;
    }

    template <typename T>
    auto detach_abi(com_array<T>&& object) noexcept
    {
        return detach_abi(object);
    }
}

namespace winrt::impl
{
    template <typename T>
    struct array_size_proxy
    {
        array_size_proxy& operator=(array_size_proxy const&) = delete;

        array_size_proxy(com_array<T>& value) noexcept : m_value(value)
        {}

        ~array_size_proxy() noexcept
        {
            WINRT_ASSERT(m_value.data() || (!m_value.data() && m_size == 0));
            *reinterpret_cast<uint32_t*>(reinterpret_cast<uintptr_t*>(&m_value) + 1) = m_size;
        }

        operator uint32_t*() noexcept
        {
            return &m_size;
        }

        operator unsigned long*() noexcept
        {
            return reinterpret_cast<unsigned long*>(&m_size);
        }

    private:

        com_array<T>& m_value;
        uint32_t m_size{ 0 };
    };

    template<typename T>
    array_size_proxy<T> put_size_abi(com_array<T>& object) noexcept
    {
        return array_size_proxy<T>(object);
    }

    template <typename T>
    struct com_array_proxy
    {
        com_array_proxy(uint32_t* size, winrt::impl::arg_out<T>* value) noexcept : m_size(size), m_value(value)
        {}

        ~com_array_proxy() noexcept
        {
            std::tie(*m_size, *m_value) = detach_abi(m_temp);
        }

        operator com_array<T>&() noexcept
        {
            return m_temp;
        }

        com_array_proxy(com_array_proxy const&) noexcept
        {
            // A Visual C++ compiler bug (550631) requires the copy constructor even though it is never called.
            WINRT_ASSERT(false);
        }

    private:

        uint32_t* m_size;
        arg_out<T>* m_value;
        com_array<T> m_temp;
    };
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    auto detach_abi(uint32_t* __valueSize, impl::arg_out<T>* value) noexcept
    {
        return impl::com_array_proxy<T>(__valueSize, value);
    }

    inline hstring get_class_name(Windows::Foundation::IInspectable const& object)
    {
        void* value{};
        check_hresult((*(impl::inspectable_abi**)&object)->GetRuntimeClassName(&value));
        return { value, take_ownership_from_abi };
    }

    inline com_array<guid> get_interfaces(Windows::Foundation::IInspectable const& object)
    {
        com_array<guid> value;
        check_hresult((*(impl::inspectable_abi**)&object)->GetIids(impl::put_size_abi(value), put_abi(value)));
        return value;
    }

    inline Windows::Foundation::TrustLevel get_trust_level(Windows::Foundation::IInspectable const& object)
    {
        Windows::Foundation::TrustLevel value{};
        check_hresult((*(impl::inspectable_abi**)&object)->GetTrustLevel(&value));
        return value;
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct weak_ref
    {
        weak_ref(std::nullptr_t = nullptr) noexcept {}

        template<typename U = impl::com_ref<T> const&, typename = std::enable_if_t<std::is_convertible_v<U&&, impl::com_ref<T> const&>>>
        weak_ref(U&& object)
        {
            from_com_ref(static_cast<impl::com_ref<T> const&>(object));
        }

        [[nodiscard]] auto get() const noexcept
        {
            if (!m_ref)
            {
                return impl::com_ref<T>{ nullptr };
            }

            if constexpr(impl::is_implements_v<T>)
            {
                impl::com_ref<default_interface<T>> temp;
                m_ref->Resolve(guid_of<T>(), put_abi(temp));
                void* result = get_self<T>(temp);
                detach_abi(temp);
                return impl::com_ref<T>{ result, take_ownership_from_abi };
            }
            else
            {
                void* result{};
                m_ref->Resolve(guid_of<T>(), &result);
                return impl::com_ref<T>{ result, take_ownership_from_abi };
            }
        }

        auto put() noexcept
        {
            return m_ref.put();
        }

        explicit operator bool() const noexcept
        {
            return static_cast<bool>(m_ref);
        }

    private:

        template<typename U>
        void from_com_ref(U&& object)
        {
            if (object)
            {
                if constexpr (impl::is_implements_v<T>)
                {
                    m_ref = std::move(object->get_weak().m_ref);
                }
                else
                {
                    // An access violation (crash) on the following line means that the object does not support weak references.
                    // Avoid using weak_ref/auto_revoke with such objects.
                    check_hresult(object.template try_as<impl::IWeakReferenceSource>()->GetWeakReference(m_ref.put()));
                }
            }
        }

        com_ptr<impl::IWeakReference> m_ref;
    };

    template<typename T> weak_ref(T const&)->weak_ref<impl::wrapped_type_t<T>>;

    template<typename T>
    struct impl::abi<weak_ref<T>> : impl::abi<com_ptr<impl::IWeakReference>>
    {
    };

    template <typename T>
    inline bool operator==(weak_ref<T> const& left, weak_ref<T> const& right) noexcept
    {
        return get_abi(left) == get_abi(right);
    }

    template <typename T>
    inline bool operator==(weak_ref<T> const& left, std::nullptr_t) noexcept
    {
        return get_abi(left) == nullptr;
    }

    template <typename T>
    inline bool operator==(std::nullptr_t, weak_ref<T> const& right) noexcept
    {
        return nullptr == get_abi(right);
    }

    template <typename T>
    inline bool operator!=(weak_ref<T> const& left, weak_ref<T> const& right) noexcept
    {
        return !(left == right);
    }

    template <typename T>
    inline bool operator!=(weak_ref<T> const& left, std::nullptr_t) noexcept
    {
        return !(left == nullptr);
    }

    template <typename T>
    inline bool operator!=(std::nullptr_t, weak_ref<T> const& right) noexcept
    {
        return !(nullptr == right);
    }

    template <typename T>
    weak_ref<impl::wrapped_type_t<T>> make_weak(T const& object)
    {
        return object;
    }
}

WINRT_EXPORT namespace winrt
{
#if defined (WINRT_NO_MODULE_LOCK)

    // Defining WINRT_NO_MODULE_LOCK is appropriate for apps (executables) or pinned DLLs (that don't support unloading)
    // and can thus avoid the synchronization overhead imposed by the default module lock.

    constexpr auto get_module_lock() noexcept
    {
        struct lock
        {
            constexpr uint32_t operator++() noexcept
            {
                return 1;
            }

            constexpr uint32_t operator--() noexcept
            {
                return 0;
            }

            constexpr explicit operator bool() noexcept
            {
                return true;
            }
        };

        return lock{};
    }

#elif defined (WINRT_CUSTOM_MODULE_LOCK)

    // When WINRT_CUSTOM_MODULE_LOCK is defined, you must provide an implementation of winrt::get_module_lock()
    // that returns an object that implements operator++ and operator--.

#else

    // This is the default implementation for use with DllCanUnloadNow.

    inline impl::atomic_ref_count& get_module_lock() noexcept
    {
        static impl::atomic_ref_count s_lock;
        return s_lock;
    }

#endif
}

namespace winrt::impl
{
    template<bool UseModuleLock>
    struct module_lock_updater;

    template<>
    struct module_lock_updater<true>
    {
        module_lock_updater() noexcept
        {
            ++get_module_lock();
        }

        ~module_lock_updater() noexcept
        {
            --get_module_lock();
        }
    };

    template<>
    struct module_lock_updater<false> {};

    using update_module_lock = module_lock_updater<true>;

    struct agile_ref_fallback final : IAgileReference, update_module_lock
    {
        agile_ref_fallback(com_ptr<IGlobalInterfaceTable>&& git, uint32_t cookie) noexcept :
            m_git(std::move(git)),
            m_cookie(cookie)
        {
        }

        ~agile_ref_fallback() noexcept
        {
            m_git->RevokeInterfaceFromGlobal(m_cookie);
        }

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept final
        {
            if (is_guid_of<IAgileReference>(id) || is_guid_of<Windows::Foundation::IUnknown>(id) || is_guid_of<IAgileObject>(id))
            {
                *object = static_cast<IAgileReference*>(this);
                AddRef();
                return 0;
            }

            *object = nullptr;
            return error_no_interface;
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return ++m_references;
        }

        uint32_t __stdcall Release() noexcept final
        {
            auto const remaining = --m_references;

            if (remaining == 0)
            {
                delete this;
            }

            return remaining;
        }

        int32_t __stdcall Resolve(guid const& id, void** object) noexcept final
        {
            return m_git->GetInterfaceFromGlobal(m_cookie, id, object);
        }

    private:

        com_ptr<IGlobalInterfaceTable> m_git;
        uint32_t m_cookie{};
        atomic_ref_count m_references{ 1 };
    };

    template <typename F, typename L>
    void load_runtime_function(wchar_t const* library, char const* name, F& result, L fallback) noexcept
    {
        if (result)
        {
            return;
        }

        result = reinterpret_cast<F>(WINRT_IMPL_GetProcAddress(WINRT_IMPL_LoadLibraryW(library), name));

        if (result)
        {
            return;
        }

        result = fallback;
    }

    inline int32_t __stdcall fallback_RoGetAgileReference(uint32_t, winrt::guid const& iid, void* object, void** reference) noexcept
    {
        *reference = nullptr;
        static constexpr guid git_clsid{ 0x00000323, 0x0000, 0x0000, { 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };

        com_ptr<IGlobalInterfaceTable> git;
        hresult hr = WINRT_IMPL_CoCreateInstance(git_clsid, nullptr, 1 /*CLSCTX_INPROC_SERVER*/, guid_of<IGlobalInterfaceTable>(), git.put_void());

        if (hr < 0)
        {
            return hr;
        }

        uint32_t cookie{};
        hr = git->RegisterInterfaceInGlobal(object, iid, &cookie);

        if (hr < 0)
        {
            return hr;
        }

        *reference = new agile_ref_fallback(std::move(git), cookie);
        return 0;
    }

    inline hresult get_agile_reference(winrt::guid const& iid, void* object, void** reference) noexcept
    {
        static int32_t(__stdcall * handler)(uint32_t options, winrt::guid const& iid, void* object, void** reference) noexcept;
        load_runtime_function(L"combase.dll", "RoGetAgileReference", handler, fallback_RoGetAgileReference);
        return handler(0, iid, object, reference);
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename T>
    struct agile_ref
    {
        agile_ref(std::nullptr_t = nullptr) noexcept {}

        agile_ref(impl::com_ref<T> const& object)
        {
            if (object)
            {
                check_hresult(impl::get_agile_reference(guid_of<T>(), winrt::get_abi(object), m_ref.put_void()));
            }
        }

        [[nodiscard]] impl::com_ref<T> get() const noexcept
        {
            if (!m_ref)
            {
                return nullptr;
            }

            void* result{};
            m_ref->Resolve(guid_of<T>(), &result);
            return { result, take_ownership_from_abi };
        }

        explicit operator bool() const noexcept
        {
            return static_cast<bool>(m_ref);
        }

    private:

        com_ptr<impl::IAgileReference> m_ref;
    };

    template<typename T> agile_ref(T const&)->agile_ref<impl::wrapped_type_t<T>>;

    template <typename T>
    agile_ref<impl::wrapped_type_t<T>> make_agile(T const& object)
    {
        return object;
    }
}

#if defined(_MSC_VER)
#include <intrin.h>
#define WINRT_IMPL_RETURNADDRESS() _ReturnAddress()
#elif defined(__GNUC__)
#define WINRT_IMPL_RETURNADDRESS() __builtin_extract_return_addr(__builtin_return_address(0))
#else
#define WINRT_IMPL_RETURNADDRESS() nullptr
#endif

namespace winrt::impl
{
    struct heap_traits
    {
        using type = wchar_t*;

        static void close(type value) noexcept
        {
            WINRT_VERIFY(WINRT_IMPL_HeapFree(WINRT_IMPL_GetProcessHeap(), 0, value));
        }

        static constexpr type invalid() noexcept
        {
            return nullptr;
        }
    };

    struct bstr_traits
    {
        using type = wchar_t*;

        static void close(type value) noexcept
        {
            WINRT_IMPL_SysFreeString(value);
        }

        static constexpr type invalid() noexcept
        {
            return nullptr;
        }
    };

    using bstr_handle = handle_type<bstr_traits>;

    inline hstring trim_hresult_message(wchar_t const* const message, uint32_t size) noexcept
    {
        wchar_t const* back = message + size - 1;

        while (size&& iswspace(*back))
        {
            --size;
            --back;
        }

        return { message, size };
    }

    inline hstring message_from_hresult(hresult code) noexcept
    {
        handle_type<impl::heap_traits> message;

        uint32_t const size = WINRT_IMPL_FormatMessageW(0x00001300, // FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS
            nullptr,
            code,
            0x00000400, // MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT)
            reinterpret_cast<wchar_t*>(message.put()),
            0,
            nullptr);

        return trim_hresult_message(message.get(), size);
    }

    constexpr int32_t hresult_from_win32(uint32_t const x) noexcept
    {
        return (int32_t)(x) <= 0 ? (int32_t)(x) : (int32_t)(((x) & 0x0000FFFF) | (7 << 16) | 0x80000000);
    }

    constexpr int32_t hresult_from_nt(uint32_t const x) noexcept
    {
        return ((int32_t)((x) | 0x10000000));
    }

    struct error_info_fallback final : IErrorInfo, IRestrictedErrorInfo, update_module_lock
    {
        error_info_fallback(int32_t code, void* message) noexcept :
            m_code(code),
            m_message(message ? *reinterpret_cast<winrt::hstring*>(&message) : message_from_hresult(code))
        {
        }

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept final
        {
            if (is_guid_of<IRestrictedErrorInfo>(id) || is_guid_of<Windows::Foundation::IUnknown>(id) || is_guid_of<IAgileObject>(id))
            {
                *object = static_cast<IRestrictedErrorInfo*>(this);
                AddRef();
                return 0;
            }

            if (is_guid_of<IErrorInfo>(id))
            {
                *object = static_cast<IErrorInfo*>(this);
                AddRef();
                return 0;
            }

            *object = nullptr;
            return error_no_interface;
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return ++m_references;
        }

        uint32_t __stdcall Release() noexcept final
        {
            auto const remaining = --m_references;

            if (remaining == 0)
            {
                delete this;
            }

            return remaining;
        }

        int32_t __stdcall GetGUID(guid* value) noexcept final
        {
            *value = {};
            return 0;
        }

        int32_t __stdcall GetSource(bstr* value) noexcept final
        {
            *value = nullptr;
            return 0;
        }

        int32_t __stdcall GetDescription(bstr* value) noexcept final
        {
            *value = WINRT_IMPL_SysAllocString(m_message.c_str());
            return *value ? error_ok : error_bad_alloc;
        }

        int32_t __stdcall GetHelpFile(bstr* value) noexcept final
        {
            *value = nullptr;
            return 0;
        }

        int32_t __stdcall GetHelpContext(uint32_t* value) noexcept final
        {
            *value = 0;
            return 0;
        }

        int32_t __stdcall GetErrorDetails(bstr* fallback, int32_t* error, bstr* message, bstr* capability) noexcept final
        {
            *fallback = nullptr;
            *error = m_code;
            *capability = nullptr;
            *message = WINRT_IMPL_SysAllocString(m_message.c_str());
            return *message ? error_ok : error_bad_alloc;
        }

        int32_t __stdcall GetReference(bstr* value) noexcept final
        {
            *value = nullptr;
            return 0;
        }

    private:

        hresult const m_code;
        hstring const m_message;
        atomic_ref_count m_references{ 1 };
    };

    [[noreturn]] inline void __stdcall fallback_RoFailFastWithErrorContext(int32_t) noexcept
    {
        abort();
    }
}

WINRT_EXPORT namespace winrt
{
    struct hresult_error
    {
        using from_abi_t = take_ownership_from_abi_t;
        static constexpr auto from_abi{ take_ownership_from_abi };

        hresult_error() noexcept = default;
        hresult_error(hresult_error&&) = default;
        hresult_error& operator=(hresult_error&&) = default;

        hresult_error(hresult_error const& other) noexcept :
            m_code(other.m_code),
            m_info(other.m_info)
        {
        }

        hresult_error& operator=(hresult_error const& other) noexcept
        {
            m_code = other.m_code;
            m_info = other.m_info;
            return *this;
        }

        explicit hresult_error(hresult const code) noexcept : m_code(verify_error(code))
        {
            originate(code, nullptr);
        }

        hresult_error(hresult const code, param::hstring const& message) noexcept : m_code(verify_error(code))
        {
            originate(code, get_abi(message));
        }

        hresult_error(hresult const code, take_ownership_from_abi_t) noexcept : m_code(verify_error(code))
        {
            com_ptr<impl::IErrorInfo> info;
            WINRT_IMPL_GetErrorInfo(0, info.put_void());

            if ((m_info = info.try_as<impl::IRestrictedErrorInfo>()))
            {
                WINRT_VERIFY_(0, m_info->GetReference(m_debug_reference.put()));

                if (auto info2 = m_info.try_as<impl::ILanguageExceptionErrorInfo2>())
                {
                    WINRT_VERIFY_(0, info2->CapturePropagationContext(nullptr));
                }
            }
            else
            {
                impl::bstr_handle legacy;

                if (info)
                {
                    info->GetDescription(legacy.put());
                }

                hstring message;

                if (legacy)
                {
                    message = impl::trim_hresult_message(legacy.get(), WINRT_IMPL_SysStringLen(legacy.get()));
                }

                originate(code, get_abi(message));
            }
        }

        hresult code() const noexcept
        {
            return m_code;
        }

        hstring message() const noexcept
        {
            if (m_info)
            {
                int32_t code{};
                impl::bstr_handle fallback;
                impl::bstr_handle message;
                impl::bstr_handle unused;

                if (0 == m_info->GetErrorDetails(fallback.put(), &code, message.put(), unused.put()))
                {
                    if (code == m_code)
                    {
                        if (message)
                        {
                            return impl::trim_hresult_message(message.get(), WINRT_IMPL_SysStringLen(message.get()));
                        }
                        else
                        {
                            return impl::trim_hresult_message(fallback.get(), WINRT_IMPL_SysStringLen(fallback.get()));
                        }
                    }
                }
            }

            return impl::message_from_hresult(m_code);
        }

        template <typename To>
        auto try_as() const noexcept
        {
            return m_info.try_as<To>();
        }

        hresult to_abi() const noexcept
        {
            if (m_info)
            {
                WINRT_IMPL_SetErrorInfo(0, m_info.try_as<impl::IErrorInfo>().get());
            }

            return m_code;
        }

    private:

        static int32_t __stdcall fallback_RoOriginateLanguageException(int32_t error, void* message, void*) noexcept
        {
            com_ptr<impl::IErrorInfo> info(new (std::nothrow) impl::error_info_fallback(error, message), take_ownership_from_abi);
            WINRT_VERIFY_(0, WINRT_IMPL_SetErrorInfo(0, info.get()));
            return 1;
        }

        void originate(hresult const code, void* message) noexcept
        {
            static int32_t(__stdcall* handler)(int32_t error, void* message, void* exception) noexcept;
            impl::load_runtime_function(L"combase.dll", "RoOriginateLanguageException", handler, fallback_RoOriginateLanguageException);
            WINRT_VERIFY(handler(code, message, nullptr));

            com_ptr<impl::IErrorInfo> info;
            WINRT_VERIFY_(0, WINRT_IMPL_GetErrorInfo(0, info.put_void()));
            WINRT_VERIFY(info.try_as(m_info));
        }

        static hresult verify_error(hresult const code) noexcept
        {
            WINRT_ASSERT(code < 0);
            return code;
        }


#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-private-field"
#endif

        impl::bstr_handle m_debug_reference;
        uint32_t m_debug_magic{ 0xAABBCCDD };
        hresult m_code{ impl::error_fail };
        com_ptr<impl::IRestrictedErrorInfo> m_info;

#ifdef __clang__
#pragma clang diagnostic pop
#endif
    };

    struct hresult_access_denied : hresult_error
    {
        hresult_access_denied() noexcept : hresult_error(impl::error_access_denied) {}
        hresult_access_denied(param::hstring const& message) noexcept : hresult_error(impl::error_access_denied, message) {}
        hresult_access_denied(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_access_denied, take_ownership_from_abi) {}
    };

    struct hresult_wrong_thread : hresult_error
    {
        hresult_wrong_thread() noexcept : hresult_error(impl::error_wrong_thread) {}
        hresult_wrong_thread(param::hstring const& message) noexcept : hresult_error(impl::error_wrong_thread, message) {}
        hresult_wrong_thread(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_wrong_thread, take_ownership_from_abi) {}
    };

    struct hresult_not_implemented : hresult_error
    {
        hresult_not_implemented() noexcept : hresult_error(impl::error_not_implemented) {}
        hresult_not_implemented(param::hstring const& message) noexcept : hresult_error(impl::error_not_implemented, message) {}
        hresult_not_implemented(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_not_implemented, take_ownership_from_abi) {}
    };

    struct hresult_invalid_argument : hresult_error
    {
        hresult_invalid_argument() noexcept : hresult_error(impl::error_invalid_argument) {}
        hresult_invalid_argument(param::hstring const& message) noexcept : hresult_error(impl::error_invalid_argument, message) {}
        hresult_invalid_argument(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_invalid_argument, take_ownership_from_abi) {}
    };

    struct hresult_out_of_bounds : hresult_error
    {
        hresult_out_of_bounds() noexcept : hresult_error(impl::error_out_of_bounds) {}
        hresult_out_of_bounds(param::hstring const& message) noexcept : hresult_error(impl::error_out_of_bounds, message) {}
        hresult_out_of_bounds(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_out_of_bounds, take_ownership_from_abi) {}
    };

    struct hresult_no_interface : hresult_error
    {
        hresult_no_interface() noexcept : hresult_error(impl::error_no_interface) {}
        hresult_no_interface(param::hstring const& message) noexcept : hresult_error(impl::error_no_interface, message) {}
        hresult_no_interface(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_no_interface, take_ownership_from_abi) {}
    };

    struct hresult_class_not_available : hresult_error
    {
        hresult_class_not_available() noexcept : hresult_error(impl::error_class_not_available) {}
        hresult_class_not_available(param::hstring const& message) noexcept : hresult_error(impl::error_class_not_available, message) {}
        hresult_class_not_available(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_class_not_available, take_ownership_from_abi) {}
    };

    struct hresult_class_not_registered : hresult_error
    {
        hresult_class_not_registered() noexcept : hresult_error(impl::error_class_not_registered) {}
        hresult_class_not_registered(param::hstring const& message) noexcept : hresult_error(impl::error_class_not_registered, message) {}
        hresult_class_not_registered(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_class_not_registered, take_ownership_from_abi) {}
    };

    struct hresult_changed_state : hresult_error
    {
        hresult_changed_state() noexcept : hresult_error(impl::error_changed_state) {}
        hresult_changed_state(param::hstring const& message) noexcept : hresult_error(impl::error_changed_state, message) {}
        hresult_changed_state(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_changed_state, take_ownership_from_abi) {}
    };

    struct hresult_illegal_method_call : hresult_error
    {
        hresult_illegal_method_call() noexcept : hresult_error(impl::error_illegal_method_call) {}
        hresult_illegal_method_call(param::hstring const& message) noexcept : hresult_error(impl::error_illegal_method_call, message) {}
        hresult_illegal_method_call(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_illegal_method_call, take_ownership_from_abi) {}
    };

    struct hresult_illegal_state_change : hresult_error
    {
        hresult_illegal_state_change() noexcept : hresult_error(impl::error_illegal_state_change) {}
        hresult_illegal_state_change(param::hstring const& message) noexcept : hresult_error(impl::error_illegal_state_change, message) {}
        hresult_illegal_state_change(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_illegal_state_change, take_ownership_from_abi) {}
    };

    struct hresult_illegal_delegate_assignment : hresult_error
    {
        hresult_illegal_delegate_assignment() noexcept : hresult_error(impl::error_illegal_delegate_assignment) {}
        hresult_illegal_delegate_assignment(param::hstring const& message) noexcept : hresult_error(impl::error_illegal_delegate_assignment, message) {}
        hresult_illegal_delegate_assignment(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_illegal_delegate_assignment, take_ownership_from_abi) {}
    };

    struct hresult_canceled : hresult_error
    {
        hresult_canceled() noexcept : hresult_error(impl::error_canceled) {}
        hresult_canceled(param::hstring const& message) noexcept : hresult_error(impl::error_canceled, message) {}
        hresult_canceled(take_ownership_from_abi_t) noexcept : hresult_error(impl::error_canceled, take_ownership_from_abi) {}
    };

    [[noreturn]] inline WINRT_IMPL_NOINLINE void throw_hresult(hresult const result)
    {
        if (winrt_throw_hresult_handler)
        {
            winrt_throw_hresult_handler(0, nullptr, nullptr, WINRT_IMPL_RETURNADDRESS(), result);
        }

        if (result == impl::error_bad_alloc)
        {
            throw std::bad_alloc();
        }

        if (result == impl::error_access_denied)
        {
            throw hresult_access_denied(take_ownership_from_abi);
        }

        if (result == impl::error_wrong_thread)
        {
            throw hresult_wrong_thread(take_ownership_from_abi);
        }

        if (result == impl::error_not_implemented)
        {
            throw hresult_not_implemented(take_ownership_from_abi);
        }

        if (result == impl::error_invalid_argument)
        {
            throw hresult_invalid_argument(take_ownership_from_abi);
        }

        if (result == impl::error_out_of_bounds)
        {
            throw hresult_out_of_bounds(take_ownership_from_abi);
        }

        if (result == impl::error_no_interface)
        {
            throw hresult_no_interface(take_ownership_from_abi);
        }

        if (result == impl::error_class_not_available)
        {
            throw hresult_class_not_available(take_ownership_from_abi);
        }

        if (result == impl::error_class_not_registered)
        {
            throw hresult_class_not_registered(take_ownership_from_abi);
        }

        if (result == impl::error_changed_state)
        {
            throw hresult_changed_state(take_ownership_from_abi);
        }

        if (result == impl::error_illegal_method_call)
        {
            throw hresult_illegal_method_call(take_ownership_from_abi);
        }

        if (result == impl::error_illegal_state_change)
        {
            throw hresult_illegal_state_change(take_ownership_from_abi);
        }

        if (result == impl::error_illegal_delegate_assignment)
        {
            throw hresult_illegal_delegate_assignment(take_ownership_from_abi);
        }

        if (result == impl::error_canceled)
        {
            throw hresult_canceled(take_ownership_from_abi);
        }

        throw hresult_error(result, take_ownership_from_abi);
    }

    inline WINRT_IMPL_NOINLINE hresult to_hresult() noexcept
    {
        if (winrt_to_hresult_handler)
        {
            return winrt_to_hresult_handler(WINRT_IMPL_RETURNADDRESS());
        }

        try
        {
            throw;
        }
        catch (hresult_error const& e)
        {
            return e.to_abi();
        }
        catch (std::bad_alloc const&)
        {
            return impl::error_bad_alloc;
        }
        catch (std::out_of_range const& e)
        {
            return hresult_out_of_bounds(to_hstring(e.what())).to_abi();
        }
        catch (std::invalid_argument const& e)
        {
            return hresult_invalid_argument(to_hstring(e.what())).to_abi();
        }
        catch (std::exception const& e)
        {
            return hresult_error(impl::error_fail, to_hstring(e.what())).to_abi();
        }
    }

    inline WINRT_IMPL_NOINLINE hstring to_message()
    {
        if (winrt_to_message_handler)
        {
            return winrt_to_message_handler(WINRT_IMPL_RETURNADDRESS());
        }

        try
        {
            throw;
        }
        catch (hresult_error const& e)
        {
            return e.message();
        }
        catch (std::exception const& ex)
        {
            return to_hstring(ex.what());
        }
        catch (...)
        {
            abort();
        }
    }

    [[noreturn]] inline void throw_last_error()
    {
        throw_hresult(impl::hresult_from_win32(WINRT_IMPL_GetLastError()));
    }

    inline hresult check_hresult(hresult const result)
    {
        if (result < 0)
        {
            throw_hresult(result);
        }
        return result;
    }

    template<typename T>
    void check_nt(T result)
    {
        if (result != 0)
        {
            throw_hresult(impl::hresult_from_nt(result));
        }
    }

    template<typename T>
    void check_win32(T result)
    {
        if (result != 0)
        {
            throw_hresult(impl::hresult_from_win32(result));
        }
    }

    template<typename T>
    void check_bool(T result)
    {
        if (!result)
        {
            winrt::throw_last_error();
        }
    }

    template<typename T>
    T* check_pointer(T* pointer)
    {
        if (!pointer)
        {
            throw_last_error();
        }

        return pointer;
    }

    [[noreturn]] inline void terminate() noexcept
    {
        static void(__stdcall * handler)(int32_t) noexcept;
        impl::load_runtime_function(L"combase.dll", "RoFailFastWithErrorContext", handler, impl::fallback_RoFailFastWithErrorContext);
        handler(to_hresult());
        abort();
    }
}

namespace winrt::impl
{
    inline hresult check_hresult_allow_bounds(hresult const result)
    {
        if (result != impl::error_out_of_bounds && result != impl::error_fail && result != impl::error_file_not_found)
        {
            check_hresult(result);
        }
        return result;
    }
}

#undef WINRT_IMPL_RETURNADDRESS

namespace winrt::impl
{
    inline int32_t make_marshaler(unknown_abi* outer, void** result) noexcept
    {
        struct marshaler final : IMarshal
        {
            marshaler(unknown_abi* object) noexcept
            {
                m_object.copy_from(object);
            }

            int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept final
            {
                if (is_guid_of<IMarshal>(id))
                {
                    *object = static_cast<IMarshal*>(this);
                    AddRef();
                    return 0;
                }

                return m_object->QueryInterface(id, object);
            }

            uint32_t __stdcall AddRef() noexcept final
            {
                return ++m_references;
            }

            uint32_t __stdcall Release() noexcept final
            {
                auto const remaining = --m_references;

                if (remaining == 0)
                {
                    delete this;
                }

                return remaining;
            }

            int32_t __stdcall GetUnmarshalClass(guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, guid* pCid) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->GetUnmarshalClass(riid, pv, dwDestContext, pvDestContext, mshlflags, pCid);
                }

                return error_bad_alloc;
            }

            int32_t __stdcall GetMarshalSizeMax(guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, uint32_t* pSize) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->GetMarshalSizeMax(riid, pv, dwDestContext, pvDestContext, mshlflags, pSize);
                }

                return error_bad_alloc;
            }

            int32_t __stdcall MarshalInterface(void* pStm, guid const& riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->MarshalInterface(pStm, riid, pv, dwDestContext, pvDestContext, mshlflags);
                }

                return error_bad_alloc;
            }

            int32_t __stdcall UnmarshalInterface(void* pStm, guid const& riid, void** ppv) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->UnmarshalInterface(pStm, riid, ppv);
                }

                *ppv = nullptr;
                return error_bad_alloc;
            }

            int32_t __stdcall ReleaseMarshalData(void* pStm) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->ReleaseMarshalData(pStm);
                }

                return error_bad_alloc;
            }

            int32_t __stdcall DisconnectObject(uint32_t dwReserved) noexcept final
            {
                if (m_marshaler)
                {
                    return m_marshaler->DisconnectObject(dwReserved);
                }

                return error_bad_alloc;
            }

        private:

            static com_ptr<IMarshal> get_marshaler() noexcept
            {
                com_ptr<unknown_abi> unknown;
                WINRT_VERIFY_(0, WINRT_IMPL_CoCreateFreeThreadedMarshaler(nullptr, unknown.put_void()));
                return unknown ? unknown.try_as<IMarshal>() : nullptr;
            }

            com_ptr<unknown_abi> m_object;
            com_ptr<IMarshal> m_marshaler{ get_marshaler() };
            atomic_ref_count m_references{ 1 };
        };

        *result = new (std::nothrow) marshaler(outer);
        return *result ? error_ok : error_bad_alloc;
    }
}

namespace winrt::impl
{
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable:4458) // declaration hides class member (okay because we do not use named members of base class)
#endif

    template <typename T, typename H>
    struct implements_delegate : abi_t<T>, H, update_module_lock
    {
        implements_delegate(H&& handler) : H(std::forward<H>(handler))
        {
        }

        int32_t __stdcall QueryInterface(guid const& id, void** result) noexcept final
        {
            if (is_guid_of<T>(id) || is_guid_of<Windows::Foundation::IUnknown>(id) || is_guid_of<IAgileObject>(id))
            {
                *result = static_cast<abi_t<T>*>(this);
                AddRef();
                return 0;
            }

            if (is_guid_of<IMarshal>(id))
            {
                return make_marshaler(this, result);
            }

            *result = nullptr;
            return error_no_interface;
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return ++m_references;
        }

        uint32_t __stdcall Release() noexcept final
        {
            auto const remaining = --m_references;

            if (remaining == 0)
            {
                delete static_cast<delegate<T, H>*>(this);
            }

            return remaining;
        }

    private:

        atomic_ref_count m_references{ 1 };
    };

    template <typename T, typename H>
    T make_delegate(H&& handler)
    {
        return { static_cast<void*>(static_cast<abi_t<T>*>(new delegate<T, H>(std::forward<H>(handler)))), take_ownership_from_abi };
    }

    template <typename T>
    T make_agile_delegate(T const& delegate) noexcept
    {
        if constexpr (!has_category_v<T>)
        {
            return delegate;
        }
        else
        {
            if (delegate.template try_as<IAgileObject>())
            {
                return delegate;
            }

            com_ptr<IAgileReference> ref;
            get_agile_reference(guid_of<T>(), get_abi(delegate), ref.put_void());

            if (ref)
            {
                return [ref = std::move(ref)](auto&& ... args)
                {
                    T delegate;
                    ref->Resolve(guid_of<T>(), put_abi(delegate));
                    return delegate(args...);
                };
            }

            return delegate;
        }
    }

    template <typename R, typename... Args>
    struct __declspec(novtable) variadic_delegate_abi : unknown_abi
    {
        virtual R invoke(Args const& ...) = 0;
    };

    template <typename H, typename R, typename... Args>
    struct variadic_delegate final : variadic_delegate_abi<R, Args...>, H, update_module_lock
    {
        variadic_delegate(H&& handler) : H(std::forward<H>(handler))
        {
        }

        R invoke(Args const& ... args) final
        {
            if constexpr (std::is_void_v<R>)
            {
                (*this)(args...);
            }
            else
            {
                return (*this)(args...);
            }
        }

        int32_t __stdcall QueryInterface(guid const& id, void** result) noexcept final
        {
            if (is_guid_of<Windows::Foundation::IUnknown>(id) || is_guid_of<IAgileObject>(id))
            {
                *result = static_cast<unknown_abi*>(this);
                AddRef();
                return 0;
            }

            *result = nullptr;
            return error_no_interface;
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return ++m_references;
        }

        uint32_t __stdcall Release() noexcept final
        {
            auto const remaining = --m_references;

            if (remaining == 0)
            {
                delete this;
            }

            return remaining;
        }

    private:

        atomic_ref_count m_references{ 1 };
    };

    template <typename R, typename... Args>
    struct __declspec(empty_bases) delegate_base : Windows::Foundation::IUnknown
    {
        delegate_base(std::nullptr_t = nullptr) noexcept {}
        delegate_base(void* ptr, take_ownership_from_abi_t) noexcept : IUnknown(ptr, take_ownership_from_abi) {}

        template <typename L>
        delegate_base(L handler) :
            delegate_base(make(std::forward<L>(handler)))
        {}

        template <typename F> delegate_base(F* handler) :
            delegate_base([=](auto&& ... args) { return handler(args...); })
        {}

        template <typename O, typename M> delegate_base(O* object, M method) :
            delegate_base([=](auto&& ... args) { return ((*object).*(method))(args...); })
        {}

        template <typename O, typename M> delegate_base(com_ptr<O>&& object, M method) :
            delegate_base([o = std::move(object), method](auto&& ... args) { return ((*o).*(method))(args...); })
        {
        }

        template <typename O, typename M> delegate_base(winrt::weak_ref<O>&& object, M method) :
            delegate_base([o = std::move(object), method](auto&& ... args) { if (auto s = o.get()) { ((*s).*(method))(args...); } })
        {
        }

        auto operator()(Args const& ... args) const
        {
            return (*(variadic_delegate_abi<R, Args...> * *)this)->invoke(args...);
        }

    private:

        template <typename H>
        static delegate_base<R, Args...> make(H&& handler)
        {
            return { static_cast<void*>(new variadic_delegate<H, R, Args...>(std::forward<H>(handler))), take_ownership_from_abi };
        }
    };

#if defined(_MSC_VER)
#pragma warning(pop)
#endif
}

WINRT_EXPORT namespace winrt
{
    template <typename... Args>
    struct __declspec(empty_bases) delegate : impl::delegate_base<void, Args...>
    {
        using impl::delegate_base<void, Args...>::delegate_base;
    };

    template <typename R, typename... Args>
    struct __declspec(empty_bases) delegate<R(Args...)> : impl::delegate_base<R, Args...>
    {
        using impl::delegate_base<R, Args...>::delegate_base;
    };
}

WINRT_EXPORT namespace winrt
{
    struct event_token
    {
        int64_t value{};

        explicit operator bool() const noexcept
        {
            return value != 0;
        }
    };

    inline bool operator==(event_token const& left, event_token const& right) noexcept
    {
        return left.value == right.value;
    }

    struct auto_revoke_t {};
    inline constexpr auto_revoke_t auto_revoke{};

    template <typename I>
    struct event_revoker
    {
        using method_type = int32_t(__stdcall impl::abi_t<I>::*)(winrt::event_token);

        event_revoker() noexcept = default;
        event_revoker(event_revoker const&) = delete;
        event_revoker& operator=(event_revoker const&) = delete;
        event_revoker(event_revoker&&) noexcept = default;

        event_revoker& operator=(event_revoker&& other) noexcept
        {
            if (this != &other)
            {
                revoke();
                m_object = std::move(other.m_object);
                m_method = other.m_method;
                m_token = other.m_token;
            }

            return *this;
        }

        template <typename U>
        event_revoker(U&& object, method_type method, event_token token) :
            m_object(std::forward<U>(object)),
            m_method(method),
            m_token(token)
        {}

        ~event_revoker() noexcept
        {
            revoke();
        }

        void revoke() noexcept
        {
            if (I object = std::exchange(m_object, {}).get())
            {
                ((*reinterpret_cast<impl::abi_t<I>**>(&object))->*(m_method))(m_token);
            }
        }

        explicit operator bool() const noexcept
        {
            return m_object ? true : false;
        }

    private:

        weak_ref<I> m_object;
        method_type m_method{};
        event_token m_token{};
    };

    template <typename I>
    struct factory_event_revoker
    {
        using method_type = int32_t(__stdcall impl::abi_t<I>::*)(winrt::event_token);

        factory_event_revoker() noexcept = default;
        factory_event_revoker(factory_event_revoker const&) = delete;
        factory_event_revoker& operator=(factory_event_revoker const&) = delete;
        factory_event_revoker(factory_event_revoker&&) noexcept = default;

        factory_event_revoker& operator=(factory_event_revoker&& other) noexcept
        {
            if (this != &other)
            {
                revoke();
                m_object = std::move(other.m_object);
                m_method = other.m_method;
                m_token = other.m_token;
            }

            return *this;
        }

        template <typename U>
        factory_event_revoker(U&& object, method_type method, event_token token) noexcept :
            m_object(std::forward<U>(object)),
            m_method(method),
            m_token(token)
        {}

        ~factory_event_revoker() noexcept
        {
            revoke();
        }

        void revoke() noexcept
        {
            if (auto object = std::exchange(m_object, {}))
            {
                ((*reinterpret_cast<impl::abi_t<I>**>(&object))->*(m_method))(m_token);
            }
        }

        explicit operator bool() const noexcept
        {
            return m_object ? true : false;
        }

    private:

        I m_object;
        method_type m_method{};
        event_token m_token{};
    };
}

namespace winrt::impl
{
    template <typename I, auto Method>
    struct event_revoker
    {
        event_revoker() noexcept = default;
        event_revoker(event_revoker const&) = delete;
        event_revoker& operator=(event_revoker const&) = delete;

        event_revoker(event_revoker&&) noexcept = default;
        event_revoker& operator=(event_revoker&& other) noexcept
        {
            event_revoker(std::move(other)).swap(*this);
            return *this;
        }

        event_revoker(I const& object, event_token token)
            : m_object(object)
            , m_token(token)
        {}

        operator winrt::event_revoker<I>() && noexcept
        {
            return { std::move(m_object), Method, m_token };
        }

        ~event_revoker() noexcept
        {
            if (m_object)
            {
                revoke_impl(m_object.get());
            }
        }

        void swap(event_revoker& other) noexcept
        {
            std::swap(m_object, other.m_object);
            std::swap(m_token, other.m_token);
        }

        void revoke() noexcept
        {
            revoke_impl(std::exchange(m_object, {}).get());
        }

        explicit operator bool() const noexcept
        {
            return bool{ m_object };
        }

    private:
        void revoke_impl(I object) noexcept
        {
            if (object)
            {
                ((*reinterpret_cast<impl::abi_t<I>**>(&object))->*(Method))(m_token);
            }
        }

        winrt::weak_ref<I> m_object{};
        event_token m_token{};
    };

    template <typename I, auto Method>
    struct factory_event_revoker
    {
        factory_event_revoker() noexcept = default;
        factory_event_revoker(factory_event_revoker const&) = delete;
        factory_event_revoker& operator=(factory_event_revoker const&) = delete;

        factory_event_revoker(factory_event_revoker&&) noexcept = default;
        factory_event_revoker& operator=(factory_event_revoker&& other) noexcept
        {
            factory_event_revoker(std::move(other)).swap(*this);
            return *this;
        }
        factory_event_revoker(I const& object, event_token token)
            : m_object(object)
            , m_token(token)
        {}

        operator winrt::factory_event_revoker<I>() && noexcept
        {
            return { std::move(m_object), Method, m_token };
        }

        ~factory_event_revoker() noexcept
        {
            if (m_object)
            {
                revoke_impl(m_object);
            }
        }

        void swap(factory_event_revoker& other) noexcept
        {
            std::swap(m_object, other.m_object);
            std::swap(m_token, other.m_token);
        }

        void revoke() noexcept
        {
            revoke_impl(std::exchange(m_object, {}));
        }

        explicit operator bool() const noexcept
        {
            return bool{ m_object };
        }

    private:
        void revoke_impl(I object) noexcept
        {
            if (object)
            {
                ((*reinterpret_cast<impl::abi_t<I>**>(&object))->*(Method))(m_token);
            }
        }
    private:
        I m_object;
        event_token m_token{};
    };

    template <typename D, typename Revoker, typename S>
    Revoker make_event_revoker(S source, event_token token)
    {
        return { static_cast<D const&>(*source), token };
    }

    template <typename T>
    struct event_array
    {
        using value_type = T;
        using reference = value_type&;
        using pointer = value_type*;
        using iterator = value_type*;

        explicit event_array(uint32_t const count) noexcept : m_size(count)
        {
            std::uninitialized_fill_n(data(), count, value_type());
        }

        unsigned long AddRef() noexcept
        {
            return ++m_references;
        }

        unsigned long Release() noexcept
        {
            auto const remaining = --m_references;

            if (remaining == 0)
            {
                this->~event_array();
                ::operator delete(static_cast<void*>(this));
            }

            return remaining;
        }

        reference back() noexcept
        {
            WINRT_ASSERT(m_size > 0);
            return*(data() + m_size - 1);
        }

        iterator begin() noexcept
        {
            return data();
        }

        iterator end() noexcept
        {
            return data() + m_size;
        }

        uint32_t size() const noexcept
        {
            return m_size;
        }

        ~event_array() noexcept
        {
            std::destroy(begin(), end());
        }

    private:

        pointer data() noexcept
        {
            return reinterpret_cast<pointer>(this + 1);
        }

        atomic_ref_count m_references{ 1 };
        uint32_t m_size{ 0 };
    };

    template <typename T>
    com_ptr<event_array<T>> make_event_array(uint32_t const capacity)
    {
        void* raw = ::operator new(sizeof(event_array<T>) + (sizeof(T)* capacity));
#pragma warning(suppress: 6386)
        return { new(raw) event_array<T>(capacity), take_ownership_from_abi };
    }

    inline int32_t __stdcall fallback_RoTransformError(int32_t, int32_t, void*) noexcept
    {
        return 1;
    }

    template <typename Delegate, typename... Arg>
    bool invoke(Delegate const& delegate, Arg const&... args) noexcept
    {
        try
        {
            delegate(args...);
        }
        catch (...)
        {
            int32_t const code = to_hresult();

            static int32_t(__stdcall * handler)(int32_t, int32_t, void*) noexcept;
            impl::load_runtime_function(L"combase.dll", "RoTransformError", handler, fallback_RoTransformError);
            handler(code, 0, nullptr);

            if (code == static_cast<int32_t>(0x80010108) || // RPC_E_DISCONNECTED
                code == static_cast<int32_t>(0x800706BA) || // HRESULT_FROM_WIN32(RPC_S_SERVER_UNAVAILABLE)
                code == static_cast<int32_t>(0x89020001))   // JSCRIPT_E_CANTEXECUTE
            {
                return false;
            }
        }

        return true;
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename Delegate>
    struct event
    {
        using delegate_type = Delegate;

        event() = default;
        event(event const&) = delete;
        event& operator =(event const&) = delete;

        explicit operator bool() const noexcept
        {
            return m_targets != nullptr;
        }

        event_token add(delegate_type const& delegate)
        {
            event_token token{};

            // Extends life of old targets array to release delegates outside of lock.
            delegate_array temp_targets;

            {
                slim_lock_guard const change_guard(m_change);
                delegate_array new_targets = impl::make_event_array<delegate_type>((!m_targets) ? 1 : m_targets->size() + 1);

                if (m_targets)
                {
                    std::copy_n(m_targets->begin(), m_targets->size(), new_targets->begin());
                }

                new_targets->back() = impl::make_agile_delegate(delegate);
                token = get_token(new_targets->back());

                slim_lock_guard const swap_guard(m_swap);
                temp_targets = std::exchange(m_targets, std::move(new_targets));
            }

            return token;
        }

        void remove(event_token const token)
        {
            // Extends life of old targets array to release delegates outside of lock.
            delegate_array temp_targets;

            {
                slim_lock_guard const change_guard(m_change);

                if (!m_targets)
                {
                    return;
                }

                uint32_t available_slots = m_targets->size() - 1;
                delegate_array new_targets;
                bool removed = false;

                if (available_slots == 0)
                {
                    if (get_token(*m_targets->begin()) == token)
                    {
                        removed = true;
                    }
                }
                else
                {
                    new_targets = impl::make_event_array<delegate_type>(available_slots);
                    auto new_iterator = new_targets->begin();

                    for (delegate_type const& element : *m_targets)
                    {
                        if (!removed && token == get_token(element))
                        {
                            removed = true;
                            continue;
                        }

                        if (available_slots == 0)
                        {
                            WINRT_ASSERT(!removed);
                            break;
                        }

                        *new_iterator = element;
                        ++new_iterator;
                        --available_slots;
                    }
                }

                if (removed)
                {
                    slim_lock_guard const swap_guard(m_swap);
                    temp_targets = std::exchange(m_targets, std::move(new_targets));
                }
            }
        }

        void clear()
        {
            // Extends life of old targets array to release delegates outside of lock.
            delegate_array temp_targets;

            {
                slim_lock_guard const change_guard(m_change);

                if (!m_targets)
                {
                    return;
                }

                slim_lock_guard const swap_guard(m_swap);
                temp_targets = std::exchange(m_targets, nullptr);
            }
        }

        template<typename...Arg>
        void operator()(Arg const&... args)
        {
            delegate_array temp_targets;

            {
                slim_lock_guard const swap_guard(m_swap);
                temp_targets = m_targets;
            }

            if (temp_targets)
            {
                for (delegate_type const& element : *temp_targets)
                {
                    if (!impl::invoke(element, args...))
                    {
                        remove(get_token(element));
                    }
                }
            }
        }

    private:

        event_token get_token(delegate_type const& delegate) const noexcept
        {
            return event_token{ reinterpret_cast<int64_t>(WINRT_IMPL_EncodePointer(get_abi(delegate))) };
        }

        using delegate_array = com_ptr<impl::event_array<delegate_type>>;

        delegate_array m_targets;
        slim_mutex m_swap;
        slim_mutex m_change;
    };
}

namespace winrt::impl
{
    struct library_traits
    {
        using type = void*;

        static void close(type value) noexcept
        {
            WINRT_IMPL_FreeLibrary(value);
        }

        static constexpr type invalid() noexcept
        {
            return nullptr;
        }
    };

    using library_handle = handle_type<library_traits>;

    inline int32_t __stdcall fallback_RoGetActivationFactory(void*, guid const&, void** factory) noexcept
    {
        *factory = nullptr;
        return error_class_not_available;
    }


    template <bool isSameInterfaceAsIActivationFactory>
    WINRT_IMPL_NOINLINE hresult get_runtime_activation_factory_impl(param::hstring const& name, winrt::guid const& guid, void** result) noexcept
    {
        if (winrt_activation_handler)
        {
            return winrt_activation_handler(*(void**)(&name), guid, result);
        }

        static int32_t(__stdcall * handler)(void* classId, winrt::guid const& iid, void** factory) noexcept;
        impl::load_runtime_function(L"combase.dll", "RoGetActivationFactory", handler, fallback_RoGetActivationFactory);
        hresult hr = handler(*(void**)(&name), guid, result);

        if (hr == impl::error_not_initialized)
        {
            auto usage = reinterpret_cast<int32_t(__stdcall*)(void** cookie) noexcept>(WINRT_IMPL_GetProcAddress(WINRT_IMPL_LoadLibraryW(L"combase.dll"), "CoIncrementMTAUsage"));

            if (!usage)
            {
                return hr;
            }

            void* cookie;
            usage(&cookie);
            hr = handler(*(void**)(&name), guid, result);
        }

        if (hr == 0)
        {
            return 0;
        }

        com_ptr<IErrorInfo> error_info;
        WINRT_IMPL_GetErrorInfo(0, error_info.put_void());

        std::wstring path{ static_cast<hstring const&>(name) };
        std::size_t count{};

        while (std::wstring::npos != (count = path.rfind('.')))
        {
            path.resize(count);
            path += L".dll";
            library_handle library(WINRT_IMPL_LoadLibraryW(path.c_str()));
            path.resize(path.size() - 4);

            if (!library)
            {
                continue;
            }

            auto library_call = reinterpret_cast<int32_t(__stdcall*)(void* classId, void** factory)>(WINRT_IMPL_GetProcAddress(library.get(), "DllGetActivationFactory"));

            if (!library_call)
            {
                continue;
            }

            com_ptr<abi_t<Windows::Foundation::IActivationFactory>> library_factory;

            if (0 != library_call(*(void**)(&name), library_factory.put_void()))
            {
                continue;
            }

            if constexpr (isSameInterfaceAsIActivationFactory)
            {
                *result = library_factory.detach();
                library.detach();
                return 0;
            }
            else if (0 == library_factory.as(guid, result))
            {
                library.detach();
                return 0;
            }
        }

        WINRT_IMPL_SetErrorInfo(0, error_info.get());
        return hr;
    }

    template <typename Interface>
    hresult get_runtime_activation_factory(param::hstring const& name, void** result) noexcept
    {
        return get_runtime_activation_factory_impl<std::is_same_v<Interface, Windows::Foundation::IActivationFactory>>(name, guid_of<Interface>(), result);
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename Interface = Windows::Foundation::IActivationFactory>
    impl::com_ref<Interface> get_activation_factory(param::hstring const& name)
    {
        void* result{};
        check_hresult(impl::get_runtime_activation_factory<Interface>(name, &result));
        return { result, take_ownership_from_abi };
    }
}

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#endif

#if defined _M_ARM
#define WINRT_IMPL_INTERLOCKED_READ_MEMORY_BARRIER (__dmb(_ARM_BARRIER_ISH));
#elif defined _M_ARM64
#define WINRT_IMPL_INTERLOCKED_READ_MEMORY_BARRIER (__dmb(_ARM64_BARRIER_ISH));
#endif

namespace winrt::impl
{
    inline int32_t interlocked_read_32(int32_t const volatile* target) noexcept
    {
#if defined _M_IX86 || defined _M_X64
        int32_t const result = *target;
        _ReadWriteBarrier();
        return result;
#elif defined _M_ARM || defined _M_ARM64
        int32_t const result = __iso_volatile_load32(reinterpret_cast<int32_t const volatile*>(target));
        WINRT_IMPL_INTERLOCKED_READ_MEMORY_BARRIER
        return result;
#else
#error Unsupported architecture
#endif
    }

#if defined _WIN64
    inline int64_t interlocked_read_64(int64_t const volatile* target) noexcept
    {
#if defined _M_X64
        int64_t const result = *target;
        _ReadWriteBarrier();
        return result;
#elif defined _M_ARM64
        int64_t const result = __iso_volatile_load64(target);
        WINRT_IMPL_INTERLOCKED_READ_MEMORY_BARRIER
        return result;
#else
#error Unsupported architecture
#endif
    }
#endif

#undef WINRT_IMPL_INTERLOCKED_READ_MEMORY_BARRIER

#ifdef __clang__
#pragma clang diagnostic pop
#endif

    template <typename T>
    T* interlocked_read_pointer(T* const volatile* target) noexcept
    {
#ifdef _WIN64
        return (T*)interlocked_read_64((int64_t*)target);
#else
        return (T*)interlocked_read_32((int32_t*)target);
#endif
    }

#ifdef _WIN64
    inline constexpr uint32_t memory_allocation_alignment{ 16 };
#pragma warning(push)
#pragma warning(disable:4324) // structure was padded due to alignment specifier
    struct alignas(16) slist_entry
    {
        slist_entry* next;
    };
    union alignas(16) slist_header
    {
        struct
        {
            uint64_t reserved1;
            uint64_t reserved2;
        } reserved1;
        struct
        {
            uint64_t reserved1 : 16;
            uint64_t reserved2 : 48;
            uint64_t reserved3 : 4;
            uint64_t reserved4 : 60;
        } reserved2;
    };
#pragma warning(pop)
#else
    inline constexpr uint32_t memory_allocation_alignment{ 8 };
    struct slist_entry
    {
        slist_entry* next;
    };
    union slist_header
    {
        uint64_t reserved1;
        struct
        {
            slist_entry reserved1;
            uint16_t reserved2;
            uint16_t reserved3;
        } reserved2;
    };
#endif

    struct factory_count_guard
    {
        factory_count_guard(factory_count_guard const&) = delete;
        factory_count_guard& operator=(factory_count_guard const&) = delete;

        explicit factory_count_guard(size_t& count) noexcept : m_count(count)
        {
#ifndef WINRT_NO_MODULE_LOCK
#ifdef _WIN64
            _InterlockedIncrement64((int64_t*)&m_count);
#else
            _InterlockedIncrement((long*)&m_count);
#endif
#endif
        }

        ~factory_count_guard() noexcept
        {
#ifndef WINRT_NO_MODULE_LOCK
#ifdef _WIN64
            _InterlockedDecrement64((int64_t*)&m_count);
#else
            _InterlockedDecrement((long*)&m_count);
#endif
#endif
        }

    private:

        size_t& m_count;
    };

    struct factory_cache_entry_base
    {
        struct alignas(sizeof(void*) * 2) object_and_count
        {
            unknown_abi* object;
            size_t count;
        };

        object_and_count m_value;
        alignas(memory_allocation_alignment) slist_entry m_next;

        void clear() noexcept
        {
            unknown_abi* pointer_value = interlocked_read_pointer(&m_value.object);

            if (pointer_value == nullptr)
            {
                return;
            }

            object_and_count current_value{ pointer_value, 0 };

#if defined _WIN64
            if (1 == _InterlockedCompareExchange128((int64_t*)this, 0, 0, (int64_t*)&current_value))
            {
                pointer_value->Release();
            }
#else
            int64_t const result = _InterlockedCompareExchange64((int64_t*)this, 0, *(int64_t*)&current_value);

            if (result == *(int64_t*)&current_value)
            {
                pointer_value->Release();
            }
#endif
        }
    };

    static_assert(std::is_standard_layout_v<factory_cache_entry_base>);

#if !defined _M_IX86 && !defined _M_X64 && !defined _M_ARM && !defined _M_ARM64
#error Unsupported architecture: verify that zero-initialization of SLIST_HEADER is still safe
#endif

    struct factory_cache
    {
        factory_cache(factory_cache const&) = delete;
        factory_cache& operator=(factory_cache const&) = delete;
        factory_cache() noexcept = default;

        void add(factory_cache_entry_base* const entry) noexcept
        {
            WINRT_ASSERT(entry);
            WINRT_IMPL_InterlockedPushEntrySList(&m_list, &entry->m_next);
        }

        void clear() noexcept
        {
            slist_entry* entry = static_cast<slist_entry*>(WINRT_IMPL_InterlockedFlushSList(&m_list));

            while (entry != nullptr)
            {
                // entry->next must be read before entry->clear() is called since the InterlockedCompareExchange
                // inside clear() will allow another thread to add the entry back to the cache.
                slist_entry* next = entry->next;
                reinterpret_cast<factory_cache_entry_base*>(reinterpret_cast<uint8_t*>(entry) - offsetof(factory_cache_entry_base, m_next))->clear();
                entry = next;
            }
        }

    private:

        alignas(memory_allocation_alignment) slist_header m_list;
    };

    inline factory_cache& get_factory_cache() noexcept
    {
        static factory_cache cache;
        return cache;
    }

    template <typename Class, typename Interface>
    struct factory_cache_entry : factory_cache_entry_base
    {
        template <typename F>
        WINRT_IMPL_NOINLINE auto call(F&& callback)
        {
#ifdef WINRT_DIAGNOSTICS
            get_diagnostics_info().add_factory<Class>();
#endif

            auto object = get_activation_factory<Interface>(name_of<Class>());

            if (!object.template try_as<IAgileObject>())
            {
#ifdef WINRT_DIAGNOSTICS
                get_diagnostics_info().non_agile_factory<Class>();
#endif

                return callback(object);
            }

            {
                factory_count_guard const guard(m_value.count);

                if (nullptr == _InterlockedCompareExchangePointer(reinterpret_cast<void**>(&m_value.object), *reinterpret_cast<void**>(&object), nullptr))
                {
                    *reinterpret_cast<void**>(&object) = nullptr;
#ifndef WINRT_NO_MODULE_LOCK
                    get_factory_cache().add(this);
#endif
                }

                return callback(*reinterpret_cast<com_ref<Interface> const*>(&m_value.object));
            }
        }
    };

    template <typename Class, typename Interface>
    factory_cache_entry<Class, Interface> factory_cache_entry_v{};

    template <typename Class, typename Interface = Windows::Foundation::IActivationFactory, typename F>
    auto call_factory(F&& callback)
    {
        auto& factory = factory_cache_entry_v<Class, Interface>;

        {
            factory_count_guard const guard(factory.m_value.count);

            if (factory.m_value.object)
            {
                return callback(*reinterpret_cast<com_ref<Interface> const*>(&factory.m_value.object));
            }
        }

        return factory.call(callback);
    }

    template <typename CastType, typename Class, typename Interface = Windows::Foundation::IActivationFactory, typename F>
    auto call_factory_cast(F&& callback)
    {
        auto& factory = factory_cache_entry_v<Class, Interface>;

        {
            factory_count_guard const guard(factory.m_value.count);

            if (factory.m_value.object)
            {
                return callback(*reinterpret_cast<com_ref<Interface> const*>(&factory.m_value.object));
            }
        }

        return factory.call(static_cast<CastType>(callback));
    }

    template <typename Interface = Windows::Foundation::IActivationFactory>
    com_ref<Interface> try_get_activation_factory(param::hstring const& name, hresult_error* exception = nullptr) noexcept
    {
        void* result{};
        hresult const hr = get_runtime_activation_factory<Interface>(name, &result);

        if (hr < 0)
        {
            // Ensure that the IRestrictedErrorInfo is not left on the thread.
            hresult_error local_exception{ hr, take_ownership_from_abi };

            if (exception)
            {
                // Optionally transfer ownership to the caller.
                *exception = std::move(local_exception);
            }
        }

        return { result, take_ownership_from_abi };
    }

    template <typename D> struct produce<D, Windows::Foundation::IActivationFactory> : produce_base<D, Windows::Foundation::IActivationFactory>
    {
        int32_t __stdcall ActivateInstance(void** instance) noexcept final try
        {
            *instance = nullptr;
            typename D::abi_guard guard(this->shim());
            *instance = detach_abi(this->shim().ActivateInstance());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
}

WINRT_EXPORT namespace winrt
{
    enum class apartment_type : int32_t
    {
        multi_threaded = 0,
        single_threaded = 2,
    };

    inline void init_apartment(apartment_type const type = apartment_type::multi_threaded)
    {
        hresult const result = WINRT_IMPL_CoInitializeEx(nullptr, static_cast<uint32_t>(type));

        if (result < 0)
        {
            throw_hresult(result);
        }
    }

    inline void uninit_apartment() noexcept
    {
        WINRT_IMPL_CoUninitialize();
    }

    template <typename Class, typename Interface = Windows::Foundation::IActivationFactory>
    auto get_activation_factory()
    {
        // Normally, the callback avoids having to return a ref-counted object and the resulting AddRef/Release bump.
        // In this case we do want a unique reference, so we use the lambda to return one and thus produce an
        // AddRef'd object that is returned to the caller.
        return impl::call_factory<Class, Interface>([](auto&& factory)
        {
            return factory;
        });
    }

    template <typename Class, typename Interface = Windows::Foundation::IActivationFactory>
    auto try_get_activation_factory() noexcept
    {
        return impl::try_get_activation_factory<Interface>(name_of<Class>());
    }

    template <typename Class, typename Interface = Windows::Foundation::IActivationFactory>
    auto try_get_activation_factory(hresult_error& exception) noexcept
    {
        return impl::try_get_activation_factory<Interface>(name_of<Class>(), &exception);
    }

    template <typename Interface = Windows::Foundation::IActivationFactory>
    auto try_get_activation_factory(param::hstring const& name) noexcept
    {
        return impl::try_get_activation_factory<Interface>(name);
    }

    template <typename Interface = Windows::Foundation::IActivationFactory>
    auto try_get_activation_factory(param::hstring const& name, hresult_error& exception) noexcept
    {
        return impl::try_get_activation_factory<Interface>(name, &exception);
    }

    inline void clear_factory_cache() noexcept
    {
        impl::get_factory_cache().clear();
    }

    template <typename Interface>
    auto try_create_instance(guid const& clsid, uint32_t context = 0x1 /*CLSCTX_INPROC_SERVER*/, void* outer = nullptr)
    {
        return try_capture<Interface>(WINRT_IMPL_CoCreateInstance, clsid, outer, context);
    }

    template <typename Interface>
    auto create_instance(guid const& clsid, uint32_t context = 0x1 /*CLSCTX_INPROC_SERVER*/, void* outer = nullptr)
    {
        return capture<Interface>(WINRT_IMPL_CoCreateInstance, clsid, outer, context);
    }

    namespace Windows::Foundation
    {
        struct IActivationFactory : IInspectable
        {
            IActivationFactory(std::nullptr_t = nullptr) noexcept {}
            IActivationFactory(void* ptr, take_ownership_from_abi_t) noexcept : IInspectable(ptr, take_ownership_from_abi) {}

            template <typename T>
            T ActivateInstance() const
            {
                IInspectable instance;
                check_hresult((*(impl::abi_t<IActivationFactory>**)this)->ActivateInstance(put_abi(instance)));
                return instance.try_as<T>();
            }
        };
    }
}

namespace winrt::impl
{
    template <typename T>
    T fast_activate(Windows::Foundation::IActivationFactory const& factory)
    {
        void* result{};
        check_hresult((*(impl::abi_t<Windows::Foundation::IActivationFactory>**)&factory)->ActivateInstance(&result));
        return{ result, take_ownership_from_abi };
    }
}
#if defined(_MSC_VER)
#if defined(_DEBUG) && !defined(WINRT_NO_MAKE_DETECTION)
#pragma detect_mismatch("C++/WinRT WINRT_NO_MAKE_DETECTION", "make detection enabled (DEBUG and !WINRT_NO_MAKE_DETECTION)")
#else
#pragma detect_mismatch("C++/WinRT WINRT_NO_MAKE_DETECTION", "make detection disabled (!DEBUG or WINRT_NO_MAKE_DETECTION)")
#endif
#endif

namespace winrt::impl
{
    struct marker
    {
        marker() = delete;
    };
}

WINRT_EXPORT namespace winrt
{
    struct non_agile : impl::marker {};
    struct no_weak_ref : impl::marker {};
    struct composing : impl::marker {};
    struct composable : impl::marker {};
    struct no_module_lock : impl::marker {};
    struct static_lifetime : impl::marker {};

    template <typename Interface>
    struct cloaked : Interface {};

    template <typename D, typename... I>
    struct implements;
}

namespace winrt::impl
{
    template<typename...T>
    using tuple_cat_t = decltype(std::tuple_cat(std::declval<T>()...));

    template <template <typename> typename Condition, typename>
    struct tuple_if_base;

    template <template <typename> typename Condition, typename...T>
    struct tuple_if_base<Condition, std::tuple<T...>> { using type = tuple_cat_t<typename std::conditional<Condition<T>::value, std::tuple<T>, std::tuple<>>::type...>; };

    template <template <typename> typename Condition, typename T>
    using tuple_if = typename tuple_if_base<Condition, T>::type;

    template <typename T>
    struct is_interface : std::disjunction<std::is_base_of<Windows::Foundation::IInspectable, T>, is_classic_com_interface<T>> {};

    template <typename T>
    struct is_marker : std::disjunction<std::is_base_of<marker, T>, std::is_void<T>> {};

    template <typename T>
    struct uncloak_base
    {
        using type = T;
    };

    template <typename T>
    struct uncloak_base<cloaked<T>>
    {
        using type = T;
    };

    template <typename T>
    using uncloak = typename uncloak_base<T>::type;

    template <typename I>
    struct is_cloaked : std::disjunction<
        std::is_same<Windows::Foundation::IInspectable, I>,
        std::negation<std::is_base_of<Windows::Foundation::IInspectable, I>>
    > {};

    template <typename I>
    struct is_cloaked<cloaked<I>> : std::true_type {};

    template <typename D, typename I, typename Enable = void>
    struct producer;

    template <typename D, typename T>
    struct producers_base;

    template <typename D, typename I, typename Enable = void>
    struct producer_convert;

    template <typename T>
    struct producer_ref : T
    {
        producer_ref(producer_ref const&) = delete;
        producer_ref& operator=(producer_ref const&) = delete;
        producer_ref(producer_ref&&) = delete;
        producer_ref& operator=(producer_ref&&) = delete;

        producer_ref(void* ptr) noexcept : T(ptr, take_ownership_from_abi)
        {
        }

        ~producer_ref() noexcept
        {
            detach_abi(*this);
        }
    };

    template <typename T>
    struct producer_vtable
    {
        void* value;
    };

    template <typename D, typename I, typename Enable>
    struct producer_convert : producer<D, typename default_interface<I>::type>
    {
        operator producer_ref<I> const() const noexcept
        {
            return { (produce<D, typename default_interface<I>::type>*)this };
        }

        operator producer_vtable<I> const() const noexcept
        {
            return { (void*)this };
        }
    };

    template <typename D, typename...T>
    struct producers_base<D, std::tuple<T...>> : producer_convert<D, T>... {};

    template <typename D, typename...T>
    using producers = producers_base<D, tuple_if<is_interface, std::tuple<uncloak<T>...>>>;

    template <typename D, typename... I>
    struct root_implements;

    template <typename T, typename = std::void_t<>>
    struct unwrap_implements
    {
        using type = T;
    };

    template <typename T>
    struct unwrap_implements<T, std::void_t<typename T::implements_type>>
    {
        using type = typename T::implements_type;
    };

    template <typename T>
    using unwrap_implements_t = typename unwrap_implements<T>::type;

    template <typename...>
    struct nested_implements
    {};

    template <typename First, typename... Rest>
    struct nested_implements<First, Rest...>
        : std::conditional_t<is_implements_v<First>,
        impl::identity<First>, nested_implements<Rest...>>
    {
        static_assert(!is_implements_v<First> || !std::disjunction_v<is_implements<Rest>...>,
            "Duplicate nested implements found");
    };

    template <typename D, typename Dummy = std::void_t<>, typename... I>
    struct base_implements_impl
        : impl::identity<root_implements<D, I...>> {};

    template <typename D, typename... I>
    struct base_implements_impl<D, std::void_t<typename nested_implements<I...>::type>, I...>
        : nested_implements<I...> {};

    template <typename D, typename... I>
    using base_implements = base_implements_impl<D, void, I...>;

    template <typename T, typename = std::void_t<>>
    struct has_composable : std::false_type {};

    template <typename T>
    struct has_composable<T, std::void_t<typename T::composable>> : std::true_type {};

    template <typename T, typename = std::void_t<>>
    struct has_class_type : std::false_type {};

    template <typename T>
    struct has_class_type<T, std::void_t<typename T::class_type>> : std::true_type {};

    template <typename>
    struct has_static_lifetime : std::false_type {};

    template <typename D, typename...I>
    struct has_static_lifetime<implements<D, I...>> : std::disjunction<std::is_same<static_lifetime, I>...> {};

    template <typename D>
    inline constexpr bool has_static_lifetime_v = has_static_lifetime<typename D::implements_type>::value;

    template <typename T>
    void clear_abi(T*) noexcept
    {}

    template <typename T>
    void clear_abi(T** value) noexcept
    {
        *value = nullptr;
    }

    template <typename T>
    void zero_abi([[maybe_unused]] void* ptr, [[maybe_unused]] uint32_t const capacity) noexcept
    {
        if constexpr (!std::is_trivially_destructible_v<T>)
        {
            memset(ptr, 0, sizeof(T) * capacity);
        }
    }

    template <typename T>
    void zero_abi([[maybe_unused]] void* ptr) noexcept
    {
        if constexpr (!std::is_trivially_destructible_v<T>)
        {
            memset(ptr, 0, sizeof(T));
        }
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename D, typename I>
    D* get_self(I const& from) noexcept
    {
        return &static_cast<impl::produce<D, default_interface<I>>*>(get_abi(from))->shim();
    }

    template <typename D, typename I>
    [[deprecated]] D* from_abi(I const& from) noexcept
    {
        return get_self<D>(from);
    }

    template <typename I, typename D>
    impl::abi_t<I>* to_abi(impl::producer<D, I> const* from) noexcept
    {
        return reinterpret_cast<impl::abi_t<I>*>(const_cast<impl::producer<D, I>*>(from));
    }

    template <typename I, typename D>
    impl::abi_t<I>* to_abi(impl::producer_convert<D, I> const* from) noexcept
    {
        return reinterpret_cast<impl::abi_t<I>*>((impl::producer<D, default_interface<I>>*)from);
    }
}

namespace winrt::impl
{
    template <typename...> struct interface_list;

    template <>
    struct interface_list<>
    {
        template <typename T, typename Predicate>
        static constexpr void* find(const T*, const Predicate&) noexcept
        {
            return nullptr;
        }
    };

    template <typename First, typename ... Rest>
    struct interface_list<First, Rest...>
    {
        template <typename T, typename Predicate>
        static constexpr void* find(const T* obj, const Predicate& pred) noexcept
        {
            if (pred.template test<First>())
            {
                return to_abi<First>(obj);
            }
            return interface_list<Rest...>::find(obj, pred);
        }
        using first_interface = First;
    };

    template <typename, typename> struct interface_list_append_impl;

    template <typename... T, typename... U>
    struct interface_list_append_impl<interface_list<T...>, interface_list<U...>>
    {
        using type = interface_list<T..., U...>;
    };

    template <template <typename> class, typename...>
    struct filter_impl;

    template <template <typename> class Predicate, typename... T>
    using filter = typename filter_impl<Predicate, unwrap_implements_t<T>...>::type;

    template <template <typename> class Predicate>
    struct filter_impl<Predicate>
    {
        using type = interface_list<>;
    };

    template <template <typename> class Predicate, typename T, typename... Rest>
    struct filter_impl<Predicate, T, Rest...>
    {
        using type = typename interface_list_append_impl<
            std::conditional_t<
            Predicate<T>::value,
            interface_list<winrt::impl::uncloak<T>>,
            interface_list<>
            >,
            typename filter_impl<Predicate, Rest...>::type
        >::type;
    };

    template <template <typename> class Predicate, typename ... T, typename ... Rest>
    struct filter_impl<Predicate, interface_list<T...>, Rest...>
    {
        using type = typename interface_list_append_impl<
            filter<Predicate, T...>,
            filter<Predicate, Rest...>
        >::type;
    };

    template <template <typename> class Predicate, typename D, typename ... I, typename ... Rest>
    struct filter_impl<Predicate, winrt::implements<D, I...>, Rest...>
    {
        using type = typename interface_list_append_impl<
            filter<Predicate, I...>,
            filter<Predicate, Rest...>
        >::type;
    };

    template <typename T>
    using implemented_interfaces = filter<is_interface, typename T::implements_type>;

    template <typename T>
    struct is_uncloaked_interface : std::conjunction<is_interface<T>, std::negation<winrt::impl::is_cloaked<T>>> {};
    template <typename T>
    using uncloaked_interfaces = filter<is_uncloaked_interface, typename T::implements_type>;

    template <typename T>
    struct uncloaked_iids;

    template <typename ... T>
    struct uncloaked_iids<interface_list<T...>>
    {
#pragma warning(suppress: 4307)
        static constexpr std::array<guid, sizeof...(T)> value{ winrt::guid_of<T>() ... };
    };

    template <typename T, typename = void>
    struct implements_default_interface
    {
        using type = typename default_interface<typename implemented_interfaces<T>::first_interface>::type;
    };

    template <typename T>
    struct implements_default_interface<T, std::void_t<typename T::class_type>>
    {
        using type = winrt::default_interface<typename T::class_type>;
    };

    template <typename T>
    struct default_interface<T, std::void_t<typename T::implements_type>>
    {
        using type = typename implements_default_interface<T>::type;
    };

    struct iid_finder
    {
        const guid& m_guid;

        template <typename I>
        constexpr bool test() const noexcept
        {
            return is_guid_of<typename default_interface<I>::type>(m_guid);
        }
    };

    template <typename T>
    auto find_iid(const T* obj, const guid& iid) noexcept
    {
        return static_cast<unknown_abi*>(implemented_interfaces<T>::find(obj, iid_finder{ iid }));
    }

    struct inspectable_finder
    {
        template <typename I>
        static constexpr bool test() noexcept
        {
            return std::is_base_of_v<inspectable_abi, abi_t<I>>;
        }
    };

    template <typename T>
    inspectable_abi* find_inspectable(const T* obj) noexcept
    {
        using default_interface = typename implements_default_interface<T>::type;

        if constexpr (std::is_base_of_v<inspectable_abi, abi_t<default_interface>>)
        {
            return to_abi<default_interface>(obj);
        }
        else
        {
            return static_cast<inspectable_abi*>(implemented_interfaces<T>::find(obj, inspectable_finder{}));
        }
    }

    template <typename I, typename = std::void_t<>>
    struct runtime_class_name
    {
        static hstring get()
        {
            throw hresult_not_implemented{};
        }
    };

    template <typename I>
    struct runtime_class_name<I, std::void_t<decltype(name_v<I>)>>
    {
        static hstring get()
        {
            return hstring{ name_of<I>() };
        }
    };

    template <>
    struct runtime_class_name<Windows::Foundation::IInspectable>
    {
        static hstring get()
        {
            return {};
        }
    };

    template <typename D, typename I, typename Enable>
    struct producer
    {
    private:
        produce<D, I> vtable;
    };

    template <typename D, typename I, typename Enable>
    struct produce_base : abi_t<I>
    {
        D& shim() noexcept
        {
            return*static_cast<D*>(reinterpret_cast<producer<D, I>*>(this));
        }

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept override
        {
            return shim().QueryInterface(id, object);
        }

        uint32_t __stdcall AddRef() noexcept override
        {
            return shim().AddRef();
        }

        uint32_t __stdcall Release() noexcept override
        {
            return shim().Release();
        }

        int32_t __stdcall GetIids(uint32_t* count, guid** array) noexcept override
        {
            return shim().GetIids(reinterpret_cast<count_type*>(count), reinterpret_cast<guid_type**>(array));
        }

        int32_t __stdcall GetRuntimeClassName(void** name) noexcept override
        {
            return shim().abi_GetRuntimeClassName(name);
        }

        int32_t __stdcall GetTrustLevel(Windows::Foundation::TrustLevel* trustLevel) noexcept final
        {
            return shim().abi_GetTrustLevel(trustLevel);
        }
    };

    template <typename D, typename I>
    struct producer<D, I, std::enable_if_t<is_classic_com_interface<I>::value>> : I
    {
#ifndef WINRT_IMPL_IUNKNOWN_DEFINED
        static_assert(std::is_void_v<I> /* dependent_false */, "To implement classic COM interfaces, you must #include <unknwn.h> before including C++/WinRT headers.");
#endif
    };

    template <typename D, typename I>
    struct producer_convert<D, I, std::enable_if_t<is_classic_com_interface<I>::value>> : producer<D, I>
    {
    };

    struct INonDelegatingInspectable : Windows::Foundation::IUnknown
    {
        INonDelegatingInspectable(std::nullptr_t = nullptr) noexcept {}
    };

    template <> struct abi<INonDelegatingInspectable>
    {
        using type = inspectable_abi;
    };

    template <typename D>
    struct produce<D, INonDelegatingInspectable> : produce_base<D, INonDelegatingInspectable>
    {
        int32_t __stdcall QueryInterface(const guid& id, void** object) noexcept final
        {
            return this->shim().NonDelegatingQueryInterface(id, object);
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return this->shim().NonDelegatingAddRef();
        }

        uint32_t __stdcall Release() noexcept final
        {
            return this->shim().NonDelegatingRelease();
        }

        int32_t __stdcall GetIids(uint32_t* count, guid** array) noexcept final
        {
            return this->shim().NonDelegatingGetIids(count, array);
        }

        int32_t __stdcall GetRuntimeClassName(void** name) noexcept final
        {
            return this->shim().NonDelegatingGetRuntimeClassName(name);
        }
    };

    template <bool Agile, bool UseModuleLock>
    struct weak_ref;

    template <bool Agile, bool UseModuleLock>
    struct weak_source_producer;

    template <bool Agile, bool UseModuleLock>
    struct weak_source final : IWeakReferenceSource, module_lock_updater<UseModuleLock>
    {
        weak_ref<Agile, UseModuleLock>* that() noexcept
        {
            return static_cast<weak_ref<Agile, UseModuleLock>*>(reinterpret_cast<weak_source_producer<Agile, UseModuleLock>*>(this));
        }

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept final
        {
            if (is_guid_of<IWeakReferenceSource>(id))
            {
                *object = static_cast<IWeakReferenceSource*>(this);
                that()->increment_strong();
                return 0;
            }

            return that()->m_object->QueryInterface(id, object);
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return that()->increment_strong();
        }

        uint32_t __stdcall Release() noexcept final
        {
            return that()->m_object->Release();
        }

        int32_t __stdcall GetWeakReference(IWeakReference** weakReference) noexcept final
        {
            *weakReference = that();
            that()->AddRef();
            return 0;
        }
    };

    template <bool Agile, bool UseModuleLock>
    struct weak_source_producer
    {
    protected:
        weak_source<Agile, UseModuleLock> m_source;
    };

    template <bool Agile, bool UseModuleLock>
    struct weak_ref final : IWeakReference, weak_source_producer<Agile, UseModuleLock>
    {
        weak_ref(unknown_abi* object, uint32_t const strong) noexcept :
            m_object(object),
            m_strong(strong)
        {
            WINRT_ASSERT(object);
        }

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept final
        {
            if (is_guid_of<IWeakReference>(id) || is_guid_of<Windows::Foundation::IUnknown>(id))
            {
                *object = static_cast<IWeakReference*>(this);
                AddRef();
                return 0;
            }

            if constexpr (Agile)
            {
                if (is_guid_of<IAgileObject>(id))
                {
                    *object = static_cast<unknown_abi*>(this);
                    AddRef();
                    return 0;
                }

                if (is_guid_of<IMarshal>(id))
                {
                    return make_marshaler(this, object);
                }
            }

            *object = nullptr;
            return error_no_interface;
        }

        uint32_t __stdcall AddRef() noexcept final
        {
            return 1 + m_weak.fetch_add(1, std::memory_order_relaxed);
        }

        uint32_t __stdcall Release() noexcept final
        {
            uint32_t const target = m_weak.fetch_sub(1, std::memory_order_relaxed) - 1;

            if (target == 0)
            {
                delete this;
            }

            return target;
        }

        int32_t __stdcall Resolve(guid const& id, void** objectReference) noexcept final
        {
            uint32_t target = m_strong.load(std::memory_order_relaxed);

            while (true)
            {
                if (target == 0)
                {
                    *objectReference = nullptr;
                    return 0;
                }

                if (m_strong.compare_exchange_weak(target, target + 1, std::memory_order_acquire, std::memory_order_relaxed))
                {
                    int32_t hr = m_object->QueryInterface(id, objectReference);
                    m_strong.fetch_sub(1, std::memory_order_relaxed);
                    return hr;
                }
            }
        }

        void set_strong(uint32_t const count) noexcept
        {
            m_strong = count;
        }

        uint32_t increment_strong() noexcept
        {
            return 1 + m_strong.fetch_add(1, std::memory_order_relaxed);
        }

        uint32_t decrement_strong() noexcept
        {
            uint32_t const target = m_strong.fetch_sub(1, std::memory_order_release) - 1;

            if (target == 0)
            {
                Release();
            }

            return target;
        }

        IWeakReferenceSource* get_source() noexcept
        {
            increment_strong();
            return &this->m_source;
        }

    private:
        template <bool T, bool U>
        friend struct weak_source;

        static_assert(sizeof(weak_source_producer<Agile, UseModuleLock>) == sizeof(weak_source<Agile, UseModuleLock>));

        unknown_abi* m_object{};
        std::atomic<uint32_t> m_strong{ 1 };
        std::atomic<uint32_t> m_weak{ 1 };
    };

    template <bool>
    struct __declspec(empty_bases) root_implements_composing_outer
    {
    protected:
        static constexpr bool is_composing = false;
        static constexpr inspectable_abi* m_inner = nullptr;
    };

    template <>
    struct __declspec(empty_bases) root_implements_composing_outer<true>
    {
        template <typename Qi>
        auto try_as() const noexcept
        {
            return m_inner.try_as<Qi>();
        }

        explicit operator bool() const noexcept
        {
            return m_inner.operator bool();
        }
    protected:
        static constexpr bool is_composing = true;
        Windows::Foundation::IInspectable m_inner;
    };

    template <typename D, bool>
    struct __declspec(empty_bases) root_implements_composable_inner
    {
    protected:
        static constexpr inspectable_abi* outer() noexcept { return nullptr; }

        template <typename, typename, typename>
        friend class produce_dispatch_to_overridable_base;
    };

    template <typename D>
    struct __declspec(empty_bases) root_implements_composable_inner<D, true> : producer<D, INonDelegatingInspectable>
    {
    protected:
        inspectable_abi* outer() noexcept { return m_outer; }
    private:
        inspectable_abi* m_outer = nullptr;

        template <typename, typename, typename>
        friend class produce_dispatch_to_overridable_base;

        template <typename>
        friend struct composable_factory;
    };

    template <typename D, typename... I>
    struct __declspec(novtable) root_implements
        : root_implements_composing_outer<std::disjunction_v<std::is_same<composing, I>...>>
        , root_implements_composable_inner<D, std::disjunction_v<std::is_same<composable, I>...>>
        , module_lock_updater<!std::disjunction_v<std::is_same<no_module_lock, I>...>>
    {
        using IInspectable = Windows::Foundation::IInspectable;
        using root_implements_type = root_implements;

        int32_t __stdcall QueryInterface(guid const& id, void** object) noexcept
        {
            if (this->outer())
            {
                return this->outer()->QueryInterface(id, object);
            }

            int32_t result = query_interface(id, object);

            if (result == error_no_interface && this->m_inner)
            {
                result = static_cast<unknown_abi*>(get_abi(this->m_inner))->QueryInterface(id, object);
            }

            return result;
        }

        uint32_t __stdcall AddRef() noexcept
        {
            if (this->outer())
            {
                return this->outer()->AddRef();
            }

            return NonDelegatingAddRef();
        }

        uint32_t __stdcall Release() noexcept
        {
            if (this->outer())
            {
                return this->outer()->Release();
            }

            return NonDelegatingRelease();
        }

        struct abi_guard
        {
            abi_guard(D& derived) :
                m_derived(derived)
            {
                m_derived.abi_enter();
            }

            ~abi_guard()
            {
                m_derived.abi_exit();
            }

        private:

            D& m_derived;
        };

        void abi_enter() const noexcept {}
        void abi_exit() const noexcept {}

#if defined(_DEBUG) && !defined(WINRT_NO_MAKE_DETECTION)
        // Please use winrt::make<T>(args...) to avoid allocating a C++/WinRT implementation type on the stack.
        virtual void use_make_function_to_create_this_object() = 0;
#endif

    protected:

        virtual int32_t query_interface_tearoff(guid const&, void**) const noexcept
        {
            return error_no_interface;
        }

        root_implements() noexcept
        {
        }

        virtual ~root_implements() noexcept
        {
            // If a weak reference is created during destruction, this ensures that it is also destroyed.
            subtract_reference();
        }

        int32_t __stdcall GetIids(uint32_t* count, guid** array) noexcept
        {
            if (this->outer())
            {
                return this->outer()->GetIids(count, array);
            }

            return NonDelegatingGetIids(count, array);
        }

        int32_t __stdcall abi_GetRuntimeClassName(void** name) noexcept
        {
            if (this->outer())
            {
                return this->outer()->GetRuntimeClassName(name);
            }

            return NonDelegatingGetRuntimeClassName(name);
        }

        int32_t __stdcall abi_GetTrustLevel(Windows::Foundation::TrustLevel* trustLevel) noexcept
        {
            if (this->outer())
            {
                return this->outer()->GetTrustLevel(trustLevel);
            }

            return NonDelegatingGetTrustLevel(trustLevel);
        }

        uint32_t __stdcall NonDelegatingAddRef() noexcept
        {
            if constexpr (is_weak_ref_source::value)
            {
                uintptr_t count_or_pointer = m_references.load(std::memory_order_relaxed);

                while (true)
                {
                    if (is_weak_ref(count_or_pointer))
                    {
                        return decode_weak_ref(count_or_pointer)->increment_strong();
                    }

                    uintptr_t const target = count_or_pointer + 1;

                    if (m_references.compare_exchange_weak(count_or_pointer, target, std::memory_order_relaxed))
                    {
                        return static_cast<uint32_t>(target);
                    }
                }
            }
            else
            {
                return 1 + m_references.fetch_add(1, std::memory_order_relaxed);
            }
        }

        uint32_t __stdcall NonDelegatingRelease() noexcept
        {
            uint32_t const target = subtract_reference();

            if (target == 0)
            {
                // If a weak reference was previously created, the m_references value will not be stable value (won't be zero).
                // This ensures destruction has a stable value during destruction.
                m_references = 1;

                if constexpr (has_final_release::value)
                {
                    D::final_release(std::unique_ptr<D>(static_cast<D*>(this)));
                }
                else
                {
                    delete this;
                }
            }

            return target;
        }

        int32_t __stdcall NonDelegatingQueryInterface(const guid& id, void** object) noexcept
        {
            if (is_guid_of<Windows::Foundation::IInspectable>(id) || is_guid_of<Windows::Foundation::IUnknown>(id))
            {
                auto result = to_abi<INonDelegatingInspectable>(this);
                NonDelegatingAddRef();
                *object = result;
                return 0;
            }

            int32_t result = query_interface(id, object);

            if (result == error_no_interface && this->m_inner)
            {
                result = static_cast<unknown_abi*>(get_abi(this->m_inner))->QueryInterface(id, object);
            }

            return result;
        }

        int32_t __stdcall NonDelegatingGetIids(uint32_t* count, guid** array) noexcept
        {
            const auto& local_iids = static_cast<D*>(this)->get_local_iids();
            const uint32_t& local_count = local_iids.first;
            if constexpr (root_implements_type::is_composing)
            {
                if (local_count > 0)
                {
                    const com_array<guid>& inner_iids = get_interfaces(root_implements_type::m_inner);
                    *count = local_count + inner_iids.size();
                    *array = static_cast<guid*>(WINRT_IMPL_CoTaskMemAlloc(sizeof(guid)*(*count)));
                    if (*array == nullptr)
                    {
                        return error_bad_alloc;
                    }
                    *array = std::copy(local_iids.second, local_iids.second + local_count, *array);
                    std::copy(inner_iids.cbegin(), inner_iids.cend(), *array);
                }
                else
                {
                    return static_cast<inspectable_abi*>(get_abi(root_implements_type::m_inner))->GetIids(count, array);
                }
            }
            else
            {
                if (local_count > 0)
                {
                    *count = local_count;
                    *array = static_cast<guid*>(WINRT_IMPL_CoTaskMemAlloc(sizeof(guid)*(*count)));
                    if (*array == nullptr)
                    {
                        return error_bad_alloc;
                    }
                    std::copy(local_iids.second, local_iids.second + local_count, *array);
                }
                else
                {
                    *count = 0;
                    *array = nullptr;
                }
            }
            return 0;
        }

        int32_t __stdcall NonDelegatingGetRuntimeClassName(void** name) noexcept try
        {
            *name = detach_abi(static_cast<D*>(this)->GetRuntimeClassName());
            return 0;
        }
        catch (...) { return to_hresult(); }

        int32_t __stdcall NonDelegatingGetTrustLevel(Windows::Foundation::TrustLevel* trustLevel) noexcept try
        {
            *trustLevel = static_cast<D*>(this)->GetTrustLevel();
            return 0;
        }
        catch (...) { return to_hresult(); }

        uint32_t subtract_reference() noexcept
        {
            if constexpr (is_weak_ref_source::value)
            {
                uintptr_t count_or_pointer = m_references.load(std::memory_order_relaxed);

                while (true)
                {
                    if (is_weak_ref(count_or_pointer))
                    {
                        return decode_weak_ref(count_or_pointer)->decrement_strong();
                    }

                    uintptr_t const target = count_or_pointer - 1;

                    if (m_references.compare_exchange_weak(count_or_pointer, target, std::memory_order_release, std::memory_order_relaxed))
                    {
                        return static_cast<uint32_t>(target);
                    }
                }
            }
            else
            {
                return m_references.fetch_sub(1, std::memory_order_release) - 1;
            }
        }

        template <typename T>
        winrt::weak_ref<T> get_weak()
        {
            impl::IWeakReferenceSource* weak_ref = make_weak_ref();
            if (!weak_ref)
            {
                throw std::bad_alloc{};
            }
            com_ptr<impl::IWeakReferenceSource> source;
            attach_abi(source, weak_ref);

            winrt::weak_ref<T> result;
            check_hresult(source->GetWeakReference(result.put()));
            return result;
        }

        virtual Windows::Foundation::TrustLevel GetTrustLevel() const noexcept
        {
            return Windows::Foundation::TrustLevel::BaseTrust;
        }

    private:

        class has_final_release
        {
            template <typename U, typename = decltype(std::declval<U>().final_release(0))> static constexpr bool get_value(int) { return true; }
            template <typename> static constexpr bool get_value(...) { return false; }

        public:

            static constexpr bool value = get_value<D>(0);
        };

        using is_agile = std::negation<std::disjunction<std::is_same<non_agile, I>...>>;
        using is_inspectable = std::disjunction<std::is_base_of<Windows::Foundation::IInspectable, I>...>;
        using is_weak_ref_source = std::conjunction<is_inspectable, std::negation<std::disjunction<std::is_same<no_weak_ref, I>...>>>;
        using use_module_lock = std::negation<std::disjunction<std::is_same<no_module_lock, I>...>>;
        using weak_ref_t = impl::weak_ref<is_agile::value, use_module_lock::value>;

        std::atomic<std::conditional_t<is_weak_ref_source::value, uintptr_t, uint32_t>> m_references{ 1 };

        int32_t query_interface(guid const& id, void** object) noexcept
        {
            *object = static_cast<D*>(this)->find_interface(id);

            if (*object != nullptr)
            {
                AddRef();
                return 0;
            }

            if constexpr (is_agile::value)
            {
                if (is_guid_of<IAgileObject>(id))
                {
                    *object = get_unknown();
                    AddRef();
                    return 0;
                }

                if (is_guid_of<IMarshal>(id))
                {
                    return make_marshaler(get_unknown(), object);
                }
            }

            if constexpr (is_inspectable::value)
            {
                if (is_guid_of<Windows::Foundation::IInspectable>(id))
                {
                    *object = find_inspectable();
                    AddRef();
                    return 0;
                }
            }

            if (is_guid_of<Windows::Foundation::IUnknown>(id))
            {
                *object = get_unknown();
                AddRef();
                return 0;
            }

            if constexpr (is_weak_ref_source::value)
            {
                if (is_guid_of<impl::IWeakReferenceSource>(id))
                {
                    *object = make_weak_ref();
                    return *object ? error_ok : error_bad_alloc;
                }
            }

            return query_interface_tearoff(id, object);
        }

        impl::IWeakReferenceSource* make_weak_ref() noexcept
        {
            static_assert(is_weak_ref_source::value, "This is only for weak ref support.");
            uintptr_t count_or_pointer = m_references.load(std::memory_order_relaxed);

            if (is_weak_ref(count_or_pointer))
            {
                return decode_weak_ref(count_or_pointer)->get_source();
            }

            com_ptr<weak_ref_t> weak_ref;
            *weak_ref.put() = new (std::nothrow) weak_ref_t(get_unknown(), static_cast<uint32_t>(count_or_pointer));

            if (!weak_ref)
            {
                return nullptr;
            }

            uintptr_t const encoding = encode_weak_ref(weak_ref.get());

            for (;;)
            {
                if (m_references.compare_exchange_weak(count_or_pointer, encoding, std::memory_order_acq_rel, std::memory_order_relaxed))
                {
                    impl::IWeakReferenceSource* result = weak_ref->get_source();
                    detach_abi(weak_ref);
                    return result;
                }

                if (is_weak_ref(count_or_pointer))
                {
                    return decode_weak_ref(count_or_pointer)->get_source();
                }

                weak_ref->set_strong(static_cast<uint32_t>(count_or_pointer));
            }
        }

        static bool is_weak_ref(intptr_t const value) noexcept
        {
            static_assert(is_weak_ref_source::value, "This is only for weak ref support.");
            return value < 0;
        }

        static weak_ref_t* decode_weak_ref(uintptr_t const value) noexcept
        {
            static_assert(is_weak_ref_source::value, "This is only for weak ref support.");
            return reinterpret_cast<weak_ref_t*>(value << 1);
        }

        static uintptr_t encode_weak_ref(weak_ref_t* value) noexcept
        {
            static_assert(is_weak_ref_source::value, "This is only for weak ref support.");
            constexpr uintptr_t pointer_flag = static_cast<uintptr_t>(1) << ((sizeof(uintptr_t) * 8) - 1);
            WINRT_ASSERT((reinterpret_cast<uintptr_t>(value) & 1) == 0);
            return (reinterpret_cast<uintptr_t>(value) >> 1) | pointer_flag;
        }

        virtual unknown_abi* get_unknown() const noexcept = 0;
        virtual std::pair<uint32_t, const guid*> get_local_iids() const noexcept = 0;
        virtual hstring GetRuntimeClassName() const = 0;
        virtual void* find_interface(guid const&) const noexcept = 0;
        virtual inspectable_abi* find_inspectable() const noexcept = 0;

        template <typename, typename, typename>
        friend struct impl::produce_base;

        template <typename, typename>
        friend struct impl::produce;
    };

#if defined(WINRT_NO_MAKE_DETECTION)
    template <typename T>
    using heap_implements = T;
#else
    template <typename T>
    struct heap_implements final : T
    {
        using T::T;

#if defined(_DEBUG)
        void use_make_function_to_create_this_object() final
        {
        }
#endif
    };
#endif

    inline com_ptr<IStaticLifetimeCollection> get_static_lifetime_map()
    {
        auto const lifetime_factory = get_activation_factory<impl::IStaticLifetime>(L"Windows.ApplicationModel.Core.CoreApplication");
        Windows::Foundation::IUnknown collection;
        check_hresult(lifetime_factory->GetCollection(put_abi(collection)));
        return collection.as<IStaticLifetimeCollection>();
    }

    template <typename D>
    auto make_factory() -> typename impl::implements_default_interface<D>::type
    {
        using result_type = typename impl::implements_default_interface<D>::type;

        if constexpr (!has_static_lifetime_v<D>)
        {
            return { to_abi<result_type>(new heap_implements<D>), take_ownership_from_abi };
        }
        else
        {
            auto const map = get_static_lifetime_map();
            param::hstring const name{ name_of<typename D::instance_type>() };
            void* result{};
            map->Lookup(get_abi(name), &result);

            if (result)
            {
                return { result, take_ownership_from_abi };
            }

            result_type object{ to_abi<result_type>(new heap_implements<D>), take_ownership_from_abi };

            static slim_mutex lock;
            slim_lock_guard const guard{ lock };
            map->Lookup(get_abi(name), &result);

            if (result)
            {
                return { result, take_ownership_from_abi };
            }
            else
            {
                bool found;
                check_hresult(map->Insert(get_abi(name), get_abi(object), &found));
                return object;
            }
        }
    }

    template <typename T>
    auto detach_from(T&& object) noexcept
    {
        return detach_abi(std::forward<T>(object));
    }
}

WINRT_EXPORT namespace winrt
{
    template <typename D, typename... Args>
    auto make(Args&&... args)
    {
#if !defined(WINRT_NO_MAKE_DETECTION)
        // Note: https://aka.ms/cppwinrt/detect_direct_allocations
        static_assert(std::is_destructible_v<D>, "C++/WinRT implementation types must have a public destructor");
        static_assert(!std::is_final_v<D>, "C++/WinRT implementation types must not be final");
#endif

        using I = typename impl::implements_default_interface<D>::type;

        if constexpr (std::is_same_v<I, Windows::Foundation::IActivationFactory>)
        {
            static_assert(sizeof...(args) == 0);
            return impl::make_factory<D>();
        }
        else if constexpr (impl::has_composable<D>::value)
        {
            impl::com_ref<I> result{ to_abi<I>(new impl::heap_implements<D>(std::forward<Args>(args)...)), take_ownership_from_abi };
            return result.template as<typename D::composable>();
        }
        else if constexpr (impl::has_class_type<D>::value)
        {
            static_assert(std::is_same_v<I, default_interface<typename D::class_type>>);
            return typename D::class_type{ to_abi<I>(new impl::heap_implements<D>(std::forward<Args>(args)...)), take_ownership_from_abi };
        }
        else
        {
            return impl::com_ref<I>{ to_abi<I>(new impl::heap_implements<D>(std::forward<Args>(args)...)), take_ownership_from_abi };
        }
    }

    template <typename D, typename... Args>
    com_ptr<D> make_self(Args&&... args)
    {
#if !defined(WINRT_NO_MAKE_DETECTION)
        // Note: https://aka.ms/cppwinrt/detect_direct_allocations
        static_assert(std::is_destructible_v<D>, "C++/WinRT implementation types must have a public destructor");
        static_assert(!std::is_final_v<D>, "C++/WinRT implementation types must not be final");
#endif
        if constexpr (std::is_same_v<typename impl::implements_default_interface<D>::type, Windows::Foundation::IActivationFactory>)
        {
            static_assert(sizeof...(args) == 0);
            auto temp = impl::make_factory<D>();
            void* result = get_self<D>(temp);
            detach_abi(temp);
            return { result, take_ownership_from_abi };
        }
        else
        {
            return { new impl::heap_implements<D>(std::forward<Args>(args)...), take_ownership_from_abi };
        }
    }

    template <typename... FactoryClasses>
    inline void clear_factory_static_lifetime()
    {
        auto unregister = [map = impl::get_static_lifetime_map()](param::hstring name)
        {
            map->Remove(get_abi(name));
        };
        ((unregister(name_of<typename FactoryClasses::instance_type>())), ...);
    }

    template <typename D, typename... I>
    struct implements : impl::producers<D, I...>, impl::base_implements<D, I...>::type
    {
    protected:

        using base_type = typename impl::base_implements<D, I...>::type;
        using root_implements_type = typename base_type::root_implements_type;

        using base_type::base_type;

    public:

        using implements_type = implements;
        using IInspectable = Windows::Foundation::IInspectable;

        weak_ref<D> get_weak()
        {
            return root_implements_type::template get_weak<D>();
        }

        com_ptr<D> get_strong() noexcept
        {
            com_ptr<D> result;
            result.copy_from(static_cast<D*>(this));
            return result;
        }

        template <typename T>
        auto get_abi(T const& value) const noexcept
        {
            return winrt::get_abi(value);
        }

        template <typename T>
        void* get_abi() const noexcept
        {
            return static_cast<impl::producer_vtable<T>>(*this).value;
        }

        operator IInspectable() const noexcept
        {
            IInspectable result;
            copy_from_abi(result, find_inspectable());
            return result;
        }

        impl::hresult_type __stdcall QueryInterface(impl::guid_type const& id, void** object) noexcept
        {
            return root_implements_type::QueryInterface(reinterpret_cast<guid const&>(id), object);
        }

        impl::count_type __stdcall AddRef() noexcept
        {
            return root_implements_type::AddRef();
        }

        impl::count_type __stdcall Release() noexcept
        {
            return root_implements_type::Release();
        }

        impl::hresult_type __stdcall GetIids(impl::count_type* count, impl::guid_type** iids) noexcept
        {
            return root_implements_type::GetIids(reinterpret_cast<uint32_t*>(count), reinterpret_cast<guid**>(iids));
        }

        impl::hresult_type __stdcall GetRuntimeClassName(impl::hstring_type* value) noexcept
        {
            return root_implements_type::abi_GetRuntimeClassName(reinterpret_cast<void**>(value));
        }

        using root_implements_type::GetTrustLevel;

        impl::hresult_type __stdcall GetTrustLevel(impl::trust_level_type* value) noexcept
        {
            return root_implements_type::abi_GetTrustLevel(reinterpret_cast<Windows::Foundation::TrustLevel*>(value));
        }

        void* find_interface(guid const& id) const noexcept override
        {
            return impl::find_iid(static_cast<const D*>(this), id);
        }

        impl::inspectable_abi* find_inspectable() const noexcept override
        {
            return impl::find_inspectable(static_cast<const D*>(this));
        }

        std::pair<uint32_t, const guid*> get_local_iids() const noexcept override
        {
            using interfaces = impl::uncloaked_interfaces<D>;
            using local_iids = impl::uncloaked_iids<interfaces>;
            return { static_cast<uint32_t>(local_iids::value.size()), local_iids::value.data() };
        }

    private:

        impl::unknown_abi* get_unknown() const noexcept override
        {
            return reinterpret_cast<impl::unknown_abi*>(to_abi<typename impl::implements_default_interface<D>::type>(this));
        }

        hstring GetRuntimeClassName() const override
        {
            static_assert(std::is_base_of_v<implements_type, D>, "Class must derive from implements<> or ClassT<> where the first template parameter is the derived class name, e.g. struct D : implements<D, ...>");
            return impl::runtime_class_name<typename impl::implements_default_interface<D>::type>::get();
        }

        template <typename, typename...>
        friend struct impl::root_implements;

        template <typename T>
        friend struct weak_ref;
    };
}

namespace winrt::impl
{
    template <typename D>
    struct composable_factory
    {
        template <typename I, typename... Args>
        static I CreateInstance(const Windows::Foundation::IInspectable& outer, Windows::Foundation::IInspectable& inner, Args&&... args)
        {
            static_assert(std::is_base_of_v<Windows::Foundation::IInspectable, I>, "Requested interface must derive from winrt::Windows::Foundation::IInspectable");
            inner = CreateInstanceImpl(outer, std::forward<Args>(args)...);
            return inner.as<I>();
        }

    private:
        template <typename... Args>
        static Windows::Foundation::IInspectable CreateInstanceImpl(const Windows::Foundation::IInspectable& outer, Args&&... args)
        {
            // Very specific dance here. The return value must have a ref on the outer, while inner must have a ref count of 1.
            // Be sure not to make a delegating QueryInterface call because the controlling outer is not fully constructed yet.
            com_ptr<D> instance = make_self<D>(std::forward<Args>(args)...);
            instance->m_outer = static_cast<inspectable_abi*>(get_abi(outer));
            Windows::Foundation::IInspectable inner;
            attach_abi(inner, to_abi<INonDelegatingInspectable>(detach_abi(instance)));
            return inner;
        }
    };

    template <typename T, typename D, typename I>
    class __declspec(empty_bases) produce_dispatch_to_overridable_base
    {
    protected:
        D& shim() noexcept
        {
            return static_cast<T&>(*this).instance;
        }

        I shim_overridable()
        {
            void* result{};

            if (shim().outer())
            {
                check_hresult(shim().QueryInterface(guid_of<I>(), &result));
            }

            return { result, take_ownership_from_abi };
        }
    };

    template <typename T, typename D, typename I>
    struct produce_dispatch_to_overridable;

    template <typename D, typename... I>
    class dispatch_to_overridable
    {
        class wrapper : public produce_dispatch_to_overridable<wrapper, D, I>...
        {
            D& instance;

            template <typename, typename, typename>
            friend class produce_dispatch_to_overridable_base;

            template <typename, typename...>
            friend class dispatch_to_overridable;

            explicit wrapper(D& d) : instance(d) {}

        public:
            wrapper(const wrapper&) = delete;
            wrapper(wrapper&&) = default;
        };

    public:
        static wrapper overridable(D& instance) noexcept
        {
            return wrapper{ instance };
        }
    };
}

WINRT_EXPORT namespace winrt::Windows::Foundation
{
    struct Point
    {
        float X;
        float Y;

        Point() noexcept = default;

        constexpr Point(float X, float Y) noexcept
            : X(X), Y(Y)
        {}

#ifdef WINRT_IMPL_NUMERICS

        constexpr Point(Numerics::float2 const& value) noexcept
            : X(value.x), Y(value.y)
        {}

        operator Numerics::float2() const noexcept
        {
            return { X, Y };
        }

#endif
    };

    constexpr bool operator==(Point const& left, Point const& right) noexcept
    {
        return left.X == right.X && left.Y == right.Y;
    }

    constexpr bool operator!=(Point const& left, Point const& right) noexcept
    {
        return !(left == right);
    }

    struct Size
    {
        float Width;
        float Height;

        Size() noexcept = default;

        constexpr Size(float Width, float Height) noexcept
            : Width(Width), Height(Height)
        {}

#ifdef WINRT_IMPL_NUMERICS

        constexpr Size(Numerics::float2 const& value) noexcept
            : Width(value.x), Height(value.y)
        {}

        operator Numerics::float2() const noexcept
        {
            return { Width, Height };
        }

#endif
    };

    constexpr bool operator==(Size const& left, Size const& right) noexcept
    {
        return left.Width == right.Width && left.Height == right.Height;
    }

    constexpr bool operator!=(Size const& left, Size const& right) noexcept
    {
        return !(left == right);
    }

    struct Rect
    {
        float X;
        float Y;
        float Width;
        float Height;

        Rect() noexcept = default;

        constexpr Rect(float X, float Y, float Width, float Height) noexcept :
            X(X), Y(Y), Width(Width), Height(Height)
        {}

        constexpr Rect(Point const& point, Size const& size)  noexcept :
            X(point.X), Y(point.Y), Width(size.Width), Height(size.Height)
        {}
    };

    constexpr bool operator==(Rect const& left, Rect const& right) noexcept
    {
        return left.X == right.X && left.Y == right.Y && left.Width == right.Width && left.Height == right.Height;
    }

    constexpr bool operator!=(Rect const& left, Rect const& right) noexcept
    {
        return !(left == right);
    }
}

namespace winrt::impl
{
    template <> inline constexpr auto& name_v<Windows::Foundation::Point> = L"Windows.Foundation.Point";
    template <> inline constexpr auto& name_v<Windows::Foundation::Size> = L"Windows.Foundation.Size";
    template <> inline constexpr auto& name_v<Windows::Foundation::Rect> = L"Windows.Foundation.Rect";

    template <> struct category<Windows::Foundation::Point>
    {
        using type = struct_category<float, float>;
    };

    template <> struct category<Windows::Foundation::Size>
    {
        using type = struct_category<float, float>;
    };
    
    template <> struct category<Windows::Foundation::Rect>
    {
        using type = struct_category<float, float, float, float>;
    };

#ifdef WINRT_IMPL_NUMERICS

    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::float2> = L"Windows.Foundation.Numerics.Vector2";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::float3> = L"Windows.Foundation.Numerics.Vector3";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::float4> = L"Windows.Foundation.Numerics.Vector4";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::float3x2> = L"Windows.Foundation.Numerics.Matrix3x2";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::float4x4> = L"Windows.Foundation.Numerics.Matrix4x4";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::quaternion> = L"Windows.Foundation.Numerics.Quaternion";
    template <> inline constexpr auto& name_v<Windows::Foundation::Numerics::plane> = L"Windows.Foundation.Numerics.Plane";

    template <> struct category<Windows::Foundation::Numerics::float2>
    {
        using type = struct_category<float, float>;
    };

    template <> struct category<Windows::Foundation::Numerics::float3>
    {
        using type = struct_category<float, float, float>;
    };

    template <> struct category<Windows::Foundation::Numerics::float4>
    {
        using type = struct_category<float, float, float, float>;
    };

    template <> struct category<Windows::Foundation::Numerics::float3x2>
    {
        using type = struct_category<float, float, float, float, float, float>;
    };

    template <> struct category<Windows::Foundation::Numerics::float4x4>
    {
        using type = struct_category<
            float, float, float, float,
            float, float, float, float,
            float, float, float, float,
            float, float, float, float
        >;
    };

    template <> struct category<Windows::Foundation::Numerics::quaternion>
    {
        using type = struct_category<float, float, float, float>;
    };

    template <> struct category<Windows::Foundation::Numerics::plane>
    {
        using type = struct_category<Windows::Foundation::Numerics::float3, float>;
    };

#endif
}

WINRT_EXPORT namespace winrt
{
    struct file_time
    {
        uint64_t value{};

        file_time() noexcept = default;

        constexpr explicit file_time(uint64_t const value) noexcept : value(value)
        {
        }

#ifdef _FILETIME_
        constexpr file_time(FILETIME const& value) noexcept
            : value(value.dwLowDateTime | (static_cast<uint64_t>(value.dwHighDateTime) << 32))
        {
        }

        operator FILETIME() const noexcept
        {
            return { static_cast<DWORD>(value & 0xFFFFFFFF), static_cast<DWORD>(value >> 32) };
        }
#endif
    };

    struct clock
    {
        using rep = int64_t;
        using period = impl::filetime_period;
        using duration = Windows::Foundation::TimeSpan;
        using time_point = Windows::Foundation::DateTime;

        static constexpr bool is_steady = false;

        static time_point now() noexcept
        {
            file_time ft;
            WINRT_IMPL_GetSystemTimePreciseAsFileTime(&ft);
            return from_file_time(ft);
        }

        static time_t to_time_t(time_point const& time) noexcept
        {
            return static_cast<time_t>(std::chrono::system_clock::to_time_t(to_sys(time)));
        }

        static time_point from_time_t(time_t time) noexcept
        {
            return from_sys(std::chrono::system_clock::from_time_t(time));
        }

        static file_time to_file_time(time_point const& time) noexcept
        {
            return file_time{ static_cast<uint64_t>(time.time_since_epoch().count()) };
        }

        static time_point from_file_time(file_time const& time) noexcept
        {
            return time_point{ duration{ time.value } };
        }

        static auto to_FILETIME(time_point const& time) noexcept
        {
            return to_file_time(time);
        }

        static time_point from_FILETIME(file_time const& time) noexcept
        {
            return from_file_time(time);
        }

        template <typename Duration>
        static std::chrono::time_point<std::chrono::system_clock, std::common_type_t<Duration, std::chrono::seconds>>
            to_sys(std::chrono::time_point<clock, Duration> const& tp)
        {
            return epoch + tp.time_since_epoch();
        }

        template <typename Duration>
        static std::chrono::time_point<clock, std::common_type_t<Duration, std::chrono::seconds>>
            from_sys(std::chrono::time_point<std::chrono::system_clock, Duration> const& tp)
        {
            using result_t = std::chrono::time_point<clock, std::common_type_t<Duration, std::chrono::seconds>>;
            return result_t{ tp - epoch };
        }

    private:

        // system_clock epoch is 00:00:00, Jan 1 1970.
        // This is 11644473600 seconds after Windows FILETIME epoch of 00:00:00, Jan 1 1601.
        static constexpr std::chrono::time_point<std::chrono::system_clock, std::chrono::seconds> epoch{ std::chrono::seconds{ -11644473600 } };
    };
}

WINRT_EXPORT namespace winrt
{
    struct access_token : handle
    {
        static access_token process()
        {
            access_token token;
            check_bool(WINRT_IMPL_OpenProcessToken(WINRT_IMPL_GetCurrentProcess(), 0x0002 /*TOKEN_DUPLICATE*/, token.put()));
            access_token duplicate;
            check_bool(WINRT_IMPL_DuplicateToken(token.get(), 2 /*SecurityImpersonation*/, duplicate.put()));
            return duplicate;
        }

        static access_token thread()
        {
            access_token token;

            if (!WINRT_IMPL_OpenThreadToken(WINRT_IMPL_GetCurrentThread(), 0x0004 /*TOKEN_IMPERSONATE*/, 1, token.put()))
            {
                uint32_t const error = WINRT_IMPL_GetLastError();

                if (error != 1008 /*ERROR_NO_TOKEN*/)
                {
                    throw_hresult(impl::hresult_from_win32(error));
                }
            }

            return token;
        }

        static access_token client()
        {
            struct impersonate_guard
            {
                impersonate_guard(com_ptr<impl::IServerSecurity> const& server) : m_server(server)
                {
                    check_hresult(m_server->ImpersonateClient());
                }

                ~impersonate_guard()
                {
                    check_hresult(m_server->RevertToSelf());
                }

            private:

                com_ptr<impl::IServerSecurity> const& m_server;
            };

            auto server = capture<impl::IServerSecurity>(WINRT_IMPL_CoGetCallContext);
            impersonate_guard impersonate(server);
            return thread();
        }

        access_token() = default;
        access_token(access_token&& other) = default;
        access_token& operator=(access_token&& other) = default;

        access_token impersonate() const
        {
            auto previous = thread();
            check_bool(WINRT_IMPL_SetThreadToken(nullptr, get()));
            return previous;
        }

        void revert() const
        {
            check_bool(WINRT_IMPL_SetThreadToken(nullptr, get()));
        }

        auto operator()() const
        {
            struct guard
            {
                guard(access_token&& previous) noexcept : m_previous(std::move(previous))
                {
                }

                ~guard()
                {
                    m_previous.revert();
                }

                guard(guard const&)
                {
                    // A Visual C++ compiler bug (550631) requires the copy constructor even though it is never called.
                    WINRT_ASSERT(false);
                }

            private:

                access_token const m_previous;
            };

            return guard(impersonate());
        }
    };
}

namespace winrt::impl
{
    inline size_t hash_data(void const* ptr, size_t const bytes) noexcept
    {
#ifdef _WIN64
        constexpr size_t fnv_offset_basis = 14695981039346656037ULL;
        constexpr size_t fnv_prime = 1099511628211ULL;
#else
        constexpr size_t fnv_offset_basis = 2166136261U;
        constexpr size_t fnv_prime = 16777619U;
#endif
        size_t result = fnv_offset_basis;
        uint8_t const* const buffer = static_cast<uint8_t const*>(ptr);

        for (size_t next = 0; next < bytes; ++next)
        {
            result ^= buffer[next];
            result *= fnv_prime;
        }

        return result;
    }

    struct hash_base
    {
        size_t operator()(Windows::Foundation::IUnknown const& value) const noexcept
        {
            void* const abi_value = get_abi(value.try_as<Windows::Foundation::IUnknown>());
            return std::hash<void*>{}(abi_value);
        }
    };
}

namespace std
{
    template<> struct hash<winrt::hstring>
    {
        size_t operator()(winrt::hstring const& value) const noexcept
        {
            return std::hash<std::wstring_view>{}(value);
        }
    };

    template<> struct hash<winrt::Windows::Foundation::IUnknown> : winrt::impl::hash_base {};
    template<> struct hash<winrt::Windows::Foundation::IInspectable> : winrt::impl::hash_base {};
    template<> struct hash<winrt::Windows::Foundation::IActivationFactory> : winrt::impl::hash_base {};
    
    template<> struct hash<winrt::guid>
    {
        size_t operator()(winrt::guid const& value) const noexcept
        {
            return winrt::impl::hash_data(&value, sizeof(value));
        }
    };
}

namespace winrt::impl
{
    template <typename T>
    struct fast_iterator
    {
        using iterator_concept = std::random_access_iterator_tag;
        using iterator_category = std::input_iterator_tag;
        using value_type = decltype(std::declval<T>().GetAt(0));
        using difference_type = ptrdiff_t;
        using pointer = void;
        using reference = value_type;

        fast_iterator() noexcept = default;

        fast_iterator(T const& collection, uint32_t const index) noexcept :
            m_collection(&collection),
            m_index(index)
        {}

        fast_iterator& operator++() noexcept
        {
            ++m_index;
            return *this;
        }

        fast_iterator operator++(int) noexcept
        {
            auto previous = *this;
            ++m_index;
            return previous;
        }

        fast_iterator& operator--() noexcept
        {
            --m_index;
            return *this;
        }

        fast_iterator operator--(int) noexcept
        {
            auto previous = *this;
            --m_index;
            return previous;
        }

        fast_iterator& operator+=(difference_type n) noexcept
        {
            m_index += static_cast<uint32_t>(n);
            return *this;
        }

        fast_iterator operator+(difference_type n) const noexcept
        {
            return fast_iterator(*this) += n;
        }

        fast_iterator& operator-=(difference_type n) noexcept
        {
            return *this += -n;
        }

        fast_iterator operator-(difference_type n) const noexcept
        {
            return *this + -n;
        }

        difference_type operator-(fast_iterator const& other) const noexcept
        {
            WINRT_ASSERT(m_collection == other.m_collection);
            return static_cast<difference_type>(m_index) - static_cast<difference_type>(other.m_index);
        }

        reference operator*() const
        {
            return m_collection->GetAt(m_index);
        }

        reference operator[](difference_type n) const
        {
            return m_collection->GetAt(m_index + static_cast<uint32_t>(n));
        }

        bool operator==(fast_iterator const& other) const noexcept
        {
            WINRT_ASSERT(m_collection == other.m_collection);
            return m_index == other.m_index;
        }

        bool operator<(fast_iterator const& other) const noexcept
        {
            WINRT_ASSERT(m_collection == other.m_collection);
            return m_index < other.m_index;
        }

        bool operator>(fast_iterator const& other) const noexcept
        {
            WINRT_ASSERT(m_collection == other.m_collection);
            return m_index > other.m_index;
        }

        bool operator!=(fast_iterator const& other) const noexcept
        {
            return !(*this == other);
        }

        bool operator<=(fast_iterator const& other) const noexcept
        {
            return !(*this > other);
        }

        bool operator>=(fast_iterator const& other) const noexcept
        {
            return !(*this < other);
        }

        friend fast_iterator operator+(difference_type n, fast_iterator it) noexcept
        {
            return it + n;
        }

        friend fast_iterator operator-(difference_type n, fast_iterator it) noexcept
        {
            return it - n;
        }

    private:

        T const* m_collection = nullptr;
        uint32_t m_index = 0;
    };

    template <typename T>
    class has_GetAt
    {
        template <typename U, typename = decltype(std::declval<U>().GetAt(0))> static constexpr bool get_value(int) { return true; }
        template <typename> static constexpr bool get_value(...) { return false; }

    public:

        static constexpr bool value = get_value<T>(0);
    };

    template <typename T, std::enable_if_t<!has_GetAt<T>::value, int> = 0>
    auto get_begin_iterator(T const& collection) -> decltype(collection.First())
    {
        auto result = collection.First();

        if (!result.HasCurrent())
        {
            return {};
        }

        return result;
    }

    template <typename T, std::enable_if_t<!has_GetAt<T>::value, int> = 0>
    auto get_end_iterator([[maybe_unused]] T const& collection) noexcept -> decltype(collection.First())
    {
        return {};
    }

    template <typename T, std::enable_if_t<has_GetAt<T>::value, int> = 0>
    fast_iterator<T> get_begin_iterator(T const& collection) noexcept
    {
        return { collection, 0 };
    }

    template <typename T, std::enable_if_t<has_GetAt<T>::value, int> = 0>
    fast_iterator<T> get_end_iterator(T const& collection)
    {
        return { collection, collection.Size() };
    }

    template <typename T, std::enable_if_t<has_GetAt<T>::value, int> = 0>
    auto rbegin(T const& collection)
    {
        return std::make_reverse_iterator(get_end_iterator(collection));
    }

    template <typename T, std::enable_if_t<has_GetAt<T>::value, int> = 0>
    auto rend(T const& collection)
    {
        return std::make_reverse_iterator(get_begin_iterator(collection));
    }

    using std::begin;
    using std::end;
}

namespace winrt::impl
{
    inline auto submit_threadpool_callback(void(__stdcall* callback)(void*, void* context), void* context)
    {
        if (!WINRT_IMPL_TrySubmitThreadpoolCallback(callback, context, nullptr))
        {
            throw_last_error();
        }
    }

    inline void __stdcall resume_background_callback(void*, void* context) noexcept
    {
        coroutine_handle<>::from_address(context)();
    };

    inline auto resume_background(coroutine_handle<> handle)
    {
        submit_threadpool_callback(resume_background_callback, handle.address());
    }

    inline std::pair<int32_t, int32_t> get_apartment_type() noexcept
    {
        int32_t aptType;
        int32_t aptTypeQualifier;
        if (0 == WINRT_IMPL_CoGetApartmentType(&aptType, &aptTypeQualifier))
        {
            return { aptType, aptTypeQualifier };
        }
        else
        {
            return { 1 /* APTTYPE_MTA */, 1 /* APTTYPEQUALIFIER_IMPLICIT_MTA */ };
        }
    }

    inline bool is_sta_thread() noexcept
    {
        auto type = get_apartment_type();
        switch (type.first)
        {
        case 0: /* APTTYPE_STA */
        case 3: /* APTTYPE_MAINSTA */
            return true;
        case 2: /* APTTYPE_NA */
            return type.second == 3 /* APTTYPEQUALIFIER_NA_ON_STA */ ||
                type.second == 5 /* APTTYPEQUALIFIER_NA_ON_MAINSTA */;
        }
        return false;
    }

    struct resume_apartment_context
    {
        resume_apartment_context() = default;
        resume_apartment_context(std::nullptr_t) : m_context(nullptr), m_context_type(-1) {}
        resume_apartment_context(resume_apartment_context const&) = default;
        resume_apartment_context(resume_apartment_context&& other) noexcept :
            m_context(std::move(other.m_context)), m_context_type(std::exchange(other.m_context_type, -1)) {}
        resume_apartment_context& operator=(resume_apartment_context const&) = default;
        resume_apartment_context& operator=(resume_apartment_context&& other) noexcept
        {
            m_context = std::move(other.m_context);
            m_context_type = std::exchange(other.m_context_type, -1);
            return *this;
        }
        bool valid() const noexcept
        {
            return m_context_type >= 0;
        }

        com_ptr<IContextCallback> m_context = try_capture<IContextCallback>(WINRT_IMPL_CoGetObjectContext);
        int32_t m_context_type = get_apartment_type().first;
    };

    inline int32_t __stdcall resume_apartment_callback(com_callback_args* args) noexcept
    {
        coroutine_handle<>::from_address(args->data)();
        return 0;
    };

    inline void resume_apartment_sync(com_ptr<IContextCallback> const& context, coroutine_handle<> handle, int32_t* failure)
    {
        com_callback_args args{};
        args.data = handle.address();

        auto result = context->ContextCallback(resume_apartment_callback, &args, guid_of<ICallbackWithNoReentrancyToApplicationSTA>(), 5, nullptr);
        if (result < 0)
        {
            // Resume the coroutine on the wrong apartment, but tell it why.
            *failure = result;
            handle();
        }
    }

    struct threadpool_resume
    {
        threadpool_resume(com_ptr<IContextCallback> const& context, coroutine_handle<> handle, int32_t* failure) :
            m_context(context), m_handle(handle), m_failure(failure) { }
        com_ptr<IContextCallback> m_context;
        coroutine_handle<> m_handle;
        int32_t* m_failure;
    };

    inline void __stdcall fallback_submit_threadpool_callback(void*, void* p) noexcept
    {
        std::unique_ptr<threadpool_resume> state{ static_cast<threadpool_resume*>(p) };
        resume_apartment_sync(state->m_context, state->m_handle, state->m_failure);
    }

    inline void resume_apartment_on_threadpool(com_ptr<IContextCallback> const& context, coroutine_handle<> handle, int32_t* failure)
    {
        auto state = std::make_unique<threadpool_resume>(context, handle, failure);
        submit_threadpool_callback(fallback_submit_threadpool_callback, state.get());
        state.release();
    }

    inline auto resume_apartment(resume_apartment_context const& context, coroutine_handle<> handle, int32_t* failure)
    {
        WINRT_ASSERT(context.valid());
        if ((context.m_context == nullptr) || (context.m_context == try_capture<IContextCallback>(WINRT_IMPL_CoGetObjectContext)))
        {
            handle();
        }
        else if (context.m_context_type == 1 /* APTTYPE_MTA */)
        {
            resume_background(handle);
        }
        else if (is_sta_thread())
        {
            resume_apartment_on_threadpool(context.m_context, handle, failure);
        }
        else
        {
            resume_apartment_sync(context.m_context, handle, failure);
        }
    }

    template <typename T>
    class awaiter_finder
    {
        template <typename> static constexpr bool find_awaitable_member(...) { return false; }
        template <typename> static constexpr bool find_co_await_member(...) { return false; }
        template <typename> static constexpr bool find_co_await_free(...) { return false; }

#ifdef WINRT_IMPL_COROUTINES
        template <typename U, typename = decltype(std::declval<U>().await_ready())> static constexpr bool find_awaitable_member(int) { return true; }
        template <typename U, typename = decltype(std::declval<U>().operator co_await())> static constexpr bool find_co_await_member(int) { return true; }
        template <typename U, typename = decltype(operator co_await(std::declval<U>()))> static constexpr bool find_co_await_free(int) { return true; }
#endif

    public:

        static constexpr bool has_awaitable_member = find_awaitable_member<T>(0);
        static constexpr bool has_co_await_member = find_co_await_member<T&&>(0);
        static constexpr bool has_co_await_free = find_co_await_free<T&&>(0);
    };
}

WINRT_EXPORT namespace winrt
{
    struct cancellable_promise
    {
        using canceller_t = void(*)(void*);

        void set_canceller(canceller_t canceller, void* context)
        {
            m_context = context;
            m_canceller.store(canceller, std::memory_order_release);
        }

        void revoke_canceller()
        {
            while (m_canceller.exchange(nullptr, std::memory_order_acquire) == cancelling_ptr)
            {
                std::this_thread::yield();
            }
        }

        void cancel()
        {
            auto canceller = m_canceller.exchange(cancelling_ptr, std::memory_order_acquire);
            struct unique_cancellation_lock
            {
                cancellable_promise* promise;
                ~unique_cancellation_lock()
                {
                    promise->m_canceller.store(nullptr, std::memory_order_release);
                }
            } lock{ this };

            if ((canceller != nullptr) && (canceller != cancelling_ptr))
            {
                canceller(m_context);
            }
        }

    private:
        static inline auto const cancelling_ptr = reinterpret_cast<canceller_t>(1);

        std::atomic<canceller_t> m_canceller{ nullptr };
        void* m_context{ nullptr };
    };

    struct enable_await_cancellation
    {
        enable_await_cancellation() noexcept = default;
        enable_await_cancellation(enable_await_cancellation const&) = default;

        ~enable_await_cancellation()
        {
            if (m_promise)
            {
                m_promise->revoke_canceller();
            }
        }

        void operator=(enable_await_cancellation const&) = delete;

        void set_cancellable_promise(cancellable_promise* promise) noexcept
        {
            m_promise = promise;
        }

    private:

        cancellable_promise* m_promise = nullptr;
    };
}

namespace winrt::impl
{
    template <typename T>
    decltype(auto) get_awaiter(T&& value) noexcept
    {
#ifdef WINRT_IMPL_COROUTINES
        if constexpr (awaiter_finder<T>::has_co_await_member)
        {
            static_assert(!awaiter_finder<T>::has_co_await_free, "Ambiguous operator co_await (as both member and free function).");
            return static_cast<T&&>(value).operator co_await();
        }
        else if constexpr (awaiter_finder<T>::has_co_await_free)
        {
            return operator co_await(static_cast<T&&>(value));
        }
        else
        {
            static_assert(awaiter_finder<T>::has_awaitable_member, "Not an awaitable type");
            return static_cast<T&&>(value);
        }
#else
        return static_cast<T&&>(value);
#endif
    }

    template <typename T>
    struct notify_awaiter
    {
        decltype(get_awaiter(std::declval<T&&>())) awaitable;

        notify_awaiter(T&& awaitable_arg, [[maybe_unused]] cancellable_promise* promise = nullptr) : awaitable(get_awaiter(static_cast<T&&>(awaitable_arg)))
        {
            if constexpr (std::is_convertible_v<std::remove_reference_t<decltype(awaitable)>&, enable_await_cancellation&>)
            {
                if (promise)
                {
                    static_cast<enable_await_cancellation&>(awaitable).set_cancellable_promise(promise);
                    awaitable.enable_cancellation(promise);
                }
            }
        }

        bool await_ready()
        {
            if (winrt_suspend_handler)
            {
                winrt_suspend_handler(this);
            }

            return awaitable.await_ready();
        }

        template <typename U>
        auto await_suspend(coroutine_handle<U> handle)
        {
            return awaitable.await_suspend(handle);
        }

        decltype(auto) await_resume()
        {
            if (winrt_resume_handler)
            {
                winrt_resume_handler(this);
            }

            return awaitable.await_resume();
        }
    };
}

WINRT_EXPORT namespace winrt
{
    [[nodiscard]] inline auto resume_background() noexcept
    {
        struct awaitable
        {
            bool await_ready() const noexcept
            {
                return false;
            }

            void await_resume() const noexcept
            {
            }

            void await_suspend(impl::coroutine_handle<> handle) const
            {
                impl::resume_background(handle);
            }
        };

        return awaitable{};
    }

    template <typename T>
    [[nodiscard]] auto resume_background(T const& context) noexcept
    {
        struct awaitable
        {
            awaitable(T const& context) : m_context(context)
            {
            }

            bool await_ready() const noexcept
            {
                return false;
            }

            void await_resume() const noexcept
            {
            }

            void await_suspend(impl::coroutine_handle<> resume)
            {
                m_resume = resume;

                if (!WINRT_IMPL_TrySubmitThreadpoolCallback(callback, this, nullptr))
                {
                    throw_last_error();
                }
            }

        private:

            static void __stdcall callback(void*, void* context) noexcept
            {
                auto that = static_cast<awaitable*>(context);
                auto guard = that->m_context();
                that->m_resume();
            }

            T const& m_context;
            impl::coroutine_handle<> m_resume{ nullptr };
        };

        return awaitable{ context };
    }

    struct apartment_context
    {
        apartment_context() = default;
        apartment_context(std::nullptr_t) : context(nullptr) { }

        operator bool() const noexcept { return context.valid(); }
        bool operator!() const noexcept { return !context.valid(); }

        impl::resume_apartment_context context;
    };
}

namespace winrt::impl
{
    struct apartment_awaiter
    {
        apartment_context context; // make a copy because resuming may destruct the original
        int32_t failure = 0;

        bool await_ready() const noexcept
        {
            return false;
        }

        void await_resume() const
        {
            check_hresult(failure);
        }

        void await_suspend(impl::coroutine_handle<> handle)
        {
            impl::resume_apartment(context.context, handle, &failure);
        }
    };
}

WINRT_EXPORT namespace winrt
{
#ifdef WINRT_IMPL_COROUTINES
    inline impl::apartment_awaiter operator co_await(apartment_context const& context)
    {
        return{ context };
    }
#endif

    [[nodiscard]] inline auto resume_after(Windows::Foundation::TimeSpan duration) noexcept
    {
        struct awaitable : enable_await_cancellation
        {
            explicit awaitable(Windows::Foundation::TimeSpan duration) noexcept :
                m_duration(duration)
            {
            }

            void enable_cancellation(cancellable_promise* promise)
            {
                promise->set_canceller([](void* context)
                {
                    auto that = static_cast<awaitable*>(context);
                    if (that->m_state.exchange(state::canceled, std::memory_order_acquire) == state::pending)
                    {
                        that->fire_immediately();
                    }
                }, this);
            }

            bool await_ready() const noexcept
            {
                return m_duration.count() <= 0;
            }

            void await_suspend(impl::coroutine_handle<> handle)
            {
                m_handle = handle;
                m_timer.attach(check_pointer(WINRT_IMPL_CreateThreadpoolTimer(callback, this, nullptr)));
                int64_t relative_count = -m_duration.count();
                WINRT_IMPL_SetThreadpoolTimer(m_timer.get(), &relative_count, 0, 0);

                state expected = state::idle;
                if (!m_state.compare_exchange_strong(expected, state::pending, std::memory_order_release))
                {
                    fire_immediately();
                }
            }

            void await_resume()
            {
                if (m_state.exchange(state::idle, std::memory_order_relaxed) == state::canceled)
                {
                    throw hresult_canceled();
                }
            }

        private:

            static int32_t __stdcall fallback_SetThreadpoolTimerEx(winrt::impl::ptp_timer, void*, uint32_t, uint32_t) noexcept
            {
                return 0; // pretend timer has already triggered and a callback is on its way
            }

            void fire_immediately() noexcept
            {
                static int32_t(__stdcall* handler)(winrt::impl::ptp_timer, void*, uint32_t, uint32_t) noexcept;
                impl::load_runtime_function(L"kernel32.dll", "SetThreadpoolTimerEx", handler, fallback_SetThreadpoolTimerEx);

                if (handler(m_timer.get(), nullptr, 0, 0))
                {
                    int64_t now = 0;
                    WINRT_IMPL_SetThreadpoolTimer(m_timer.get(), &now, 0, 0);
                }
            }

            static void __stdcall callback(void*, void* context, void*) noexcept
            {
                auto that = reinterpret_cast<awaitable*>(context);
                that->m_handle();
            }

            struct timer_traits
            {
                using type = impl::ptp_timer;

                static void close(type value) noexcept
                {
                    WINRT_IMPL_CloseThreadpoolTimer(value);
                }

                static constexpr type invalid() noexcept
                {
                    return nullptr;
                }
            };

            enum class state { idle, pending, canceled };

            handle_type<timer_traits> m_timer;
            Windows::Foundation::TimeSpan m_duration;
            impl::coroutine_handle<> m_handle;
            std::atomic<state> m_state{ state::idle };
        };

        return awaitable{ duration };
    }

#ifdef WINRT_IMPL_COROUTINES
    inline auto operator co_await(Windows::Foundation::TimeSpan duration)
    {
        return resume_after(duration);
    }
#endif

    [[nodiscard]] inline auto resume_on_signal(void* handle, Windows::Foundation::TimeSpan timeout = {}) noexcept
    {
        struct awaitable : enable_await_cancellation
        {
            awaitable(void* handle, Windows::Foundation::TimeSpan timeout) noexcept :
                m_timeout(timeout),
                m_handle(handle)
            {}

            void enable_cancellation(cancellable_promise* promise)
            {
                promise->set_canceller([](void* context)
                {
                    auto that = static_cast<awaitable*>(context);
                    if (that->m_state.exchange(state::canceled, std::memory_order_acquire) == state::pending)
                    {
                        that->fire_immediately();
                    }
                }, this);
            }

            bool await_ready() const noexcept
            {
                return WINRT_IMPL_WaitForSingleObject(m_handle, 0) == 0;
            }

            void await_suspend(impl::coroutine_handle<> resume)
            {
                m_resume = resume;
                m_wait.attach(check_pointer(WINRT_IMPL_CreateThreadpoolWait(callback, this, nullptr)));
                int64_t relative_count = -m_timeout.count();
                int64_t* file_time = relative_count != 0 ? &relative_count : nullptr;
                WINRT_IMPL_SetThreadpoolWait(m_wait.get(), m_handle, file_time);

                state expected = state::idle;
                if (!m_state.compare_exchange_strong(expected, state::pending, std::memory_order_release))
                {
                    fire_immediately();
                }
            }

            bool await_resume()
            {
                if (m_state.exchange(state::idle, std::memory_order_relaxed) == state::canceled)
                {
                    throw hresult_canceled();
                }
                return m_result == 0;
            }

        private:
            static int32_t __stdcall fallback_SetThreadpoolWaitEx(winrt::impl::ptp_wait, void*, void*, void*) noexcept
            {
                return 0; // pretend wait has already triggered and a callback is on its way
            }

            void fire_immediately() noexcept
            {
                static int32_t(__stdcall* handler)(winrt::impl::ptp_wait, void*, void*, void*) noexcept;
                impl::load_runtime_function(L"kernel32.dll", "SetThreadpoolWaitEx", handler, fallback_SetThreadpoolWaitEx);

                if (handler(m_wait.get(), nullptr, nullptr, nullptr))
                {
                    int64_t now = 0;
                    WINRT_IMPL_SetThreadpoolWait(m_wait.get(), WINRT_IMPL_GetCurrentProcess(), &now);
                }
            }

            static void __stdcall callback(void*, void* context, void*, uint32_t result) noexcept
            {
                auto that = static_cast<awaitable*>(context);
                that->m_result = result;
                that->m_resume();
            }

            struct wait_traits
            {
                using type = impl::ptp_wait;

                static void close(type value) noexcept
                {
                    WINRT_IMPL_CloseThreadpoolWait(value);
                }

                static constexpr type invalid() noexcept
                {
                    return nullptr;
                }
            };

            enum class state { idle, pending, canceled };

            handle_type<wait_traits> m_wait;
            Windows::Foundation::TimeSpan m_timeout;
            void* m_handle;
            uint32_t m_result{};
            impl::coroutine_handle<> m_resume{ nullptr };
            std::atomic<state> m_state{ state::idle };
        };

        return awaitable{ handle, timeout };
    }

    struct thread_pool
    {
        thread_pool() :
            m_pool(check_pointer(WINRT_IMPL_CreateThreadpool(nullptr)))
        {
            m_environment.Pool = m_pool.get();
        }

        void thread_limits(uint32_t const high, uint32_t const low)
        {
            WINRT_IMPL_SetThreadpoolThreadMaximum(m_pool.get(), high);
            check_bool(WINRT_IMPL_SetThreadpoolThreadMinimum(m_pool.get(), low));
        }

        bool await_ready() const noexcept
        {
            return false;
        }

        void await_resume() const noexcept
        {
        }

        void await_suspend(impl::coroutine_handle<> handle)
        {
            if (!WINRT_IMPL_TrySubmitThreadpoolCallback(callback, handle.address(), &m_environment))
            {
                throw_last_error();
            }
        }

    private:

        static void __stdcall callback(void*, void* context) noexcept
        {
            impl::coroutine_handle<>::from_address(context)();
        }

        struct pool_traits
        {
            using type = impl::ptp_pool;

            static void close(type value) noexcept
            {
                WINRT_IMPL_CloseThreadpool(value);
            }

            static constexpr type invalid() noexcept
            {
                return nullptr;
            }
        };

        struct environment // TP_CALLBACK_ENVIRON
        {
            uint32_t Version{ 3 };
            void* Pool{};
            void* CleanupGroup{};
            void* CleanupGroupCancelCallback{};
            void* RaceDll{};
            void* ActivationContext{};
            void* FinalizationCallback{};
            union
            {
                uint32_t Flags{};
                struct
                {
                    uint32_t LongFunction : 1;
                    uint32_t Persistent : 1;
                    uint32_t Private : 30;
                } s;
            } u;
            int32_t CallbackPriority{ 1 };
            uint32_t Size{ sizeof(environment) };
        };

        handle_type<pool_traits> m_pool;
        environment m_environment;
    };

    struct fire_and_forget {};
}

#ifdef __cpp_lib_coroutine
namespace std
#else
namespace std::experimental
#endif
{
    template <typename... Args>
    struct coroutine_traits<winrt::fire_and_forget, Args...>
    {
        struct promise_type
        {
            winrt::fire_and_forget get_return_object() const noexcept
            {
                return{};
            }

            void return_void() const noexcept
            {
            }

            suspend_never initial_suspend() const noexcept
            {
                return{};
            }

            suspend_never final_suspend() const noexcept
            {
                if (winrt_suspend_handler)
                {
                    winrt_suspend_handler(this);
                }

                return{};
            }

            void unhandled_exception() const noexcept
            {
                winrt::terminate();
            }

            template <typename Expression>
            auto await_transform(Expression&& expression)
            {
                return winrt::impl::notify_awaiter<Expression>{ static_cast<Expression&&>(expression) };
            }
        };
    };
}

#if defined(_DEBUG) && !defined(WINRT_NATVIS)
#define WINRT_NATVIS
#endif

#ifdef WINRT_NATVIS

namespace winrt::impl
{
    struct natvis
    {
        static auto __stdcall abi_val(void* object, wchar_t const * iid_str, int method)
        {
            union variant
            {
                bool b;
                wchar_t c;
                int8_t i1;
                int16_t i2;
                int32_t i4;
                int64_t i8;
                uint8_t u1;
                uint16_t u2;
                uint32_t u4;
                uint64_t u8;
                float r4;
                double r8;
                guid g;
                void* s;
                uint8_t v[1024];
            }
            value;
            value.s = 0;
            guid iid;
            if (WINRT_IMPL_IIDFromString(iid_str, &iid) == 0)
            {
                struct memory_basic_information
                {
                    void* base_address;
                    void* allocation_base;
                    uint32_t allocation_protect;
#ifdef _WIN64
                    uint32_t __alignment1;
#endif
                    uintptr_t region_size;
                    uint32_t state;
                    uint32_t protect;
                    uint32_t type;
#ifdef _WIN64
                    uint32_t __alignment2;
#endif
                };
                memory_basic_information info;
                // validate object pointer is readable
                if ((WINRT_IMPL_VirtualQuery(object, &info, sizeof(info)) != 0) && ((info.protect & 0xEE) != 0))
                {
                    inspectable_abi* pinsp;
                    if (((unknown_abi*)object)->QueryInterface(iid, reinterpret_cast<void**>(&pinsp)) == 0)
                    {
                        static const int IInspectable_vtbl_size = 6;
                        auto vtbl = *(void***)pinsp;
                        // validate vtbl pointer is readable
                        if ((WINRT_IMPL_VirtualQuery(vtbl, &info, sizeof(info)) != 0) && ((info.protect & 0xEE) != 0))
                        {
                            auto vfunc = vtbl[method + IInspectable_vtbl_size];
                            // validate method pointer is executable
                            if ((WINRT_IMPL_VirtualQuery(vfunc, &info, sizeof(info)) != 0) && ((info.protect & 0xF0) != 0))
                            {
                                typedef int32_t(__stdcall inspectable_abi:: * PropertyAccessor)(void*);
                                (pinsp->**(PropertyAccessor*)&vfunc)(&value);
                                pinsp->Release();
                            }
                        }
                    }
                }
            }
            return value;
        }

        static auto __stdcall get_val(winrt::Windows::Foundation::IInspectable* object, wchar_t const* iid_str, int method)
        {
            return abi_val(static_cast<unknown_abi*>(get_abi(*object)), iid_str, method);
        }
    };
}

extern "C"
__declspec(selectany)
decltype(winrt::impl::natvis::abi_val) & WINRT_abi_val = winrt::impl::natvis::abi_val;

extern "C"
__declspec(selectany)
decltype(winrt::impl::natvis::get_val) & WINRT_get_val = winrt::impl::natvis::get_val;

#ifdef _M_IX86
#pragma comment(linker, "/include:_WINRT_abi_val")
#pragma comment(linker, "/include:_WINRT_get_val")
#else
#pragma comment(linker, "/include:WINRT_abi_val")
#pragma comment(linker, "/include:WINRT_get_val")
#endif

#endif

// WINRT_version is used by Microsoft to analyze C++/WinRT library adoption and inform future product decisions.
extern "C"
__declspec(selectany)
char const * const WINRT_version = "C++/WinRT version:" CPPWINRT_VERSION;

#ifdef _M_IX86
#pragma comment(linker, "/include:_WINRT_version")
#else
#pragma comment(linker, "/include:WINRT_version")
#endif

#if defined(_MSC_VER)
#pragma detect_mismatch("C++/WinRT version", CPPWINRT_VERSION)
#endif

WINRT_EXPORT namespace winrt
{
    template <size_t BaseSize, size_t ComponentSize>
    constexpr bool check_version(char const(&base)[BaseSize], char const(&component)[ComponentSize]) noexcept
    {
        if constexpr (BaseSize != ComponentSize)
        {
            return false;
        }

        for (size_t i = 0; i != BaseSize - 1; ++i)
        {
            if (base[i] != component[i])
            {
                return false;
            }
        }

        return true;
    }
}
#endif
