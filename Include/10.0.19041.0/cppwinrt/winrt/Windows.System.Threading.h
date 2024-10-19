// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_System_Threading_H
#define WINRT_Windows_System_Threading_H
#include "winrt/base.h"
static_assert(winrt::check_version(CPPWINRT_VERSION, "2.0.190620.2"), "Mismatched C++/WinRT headers.");
#include "winrt/Windows.System.h"
#include "winrt/impl/Windows.Foundation.2.h"
#include "winrt/impl/Windows.System.Threading.2.h"
namespace winrt::impl
{
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolStatics<D>::RunAsync(Windows::System::Threading::WorkItemHandler const& handler) const
    {
        void* operation{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolStatics)->RunAsync(*(void**)(&handler), &operation));
        return Windows::Foundation::IAsyncAction{ operation, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolStatics<D>::RunAsync(Windows::System::Threading::WorkItemHandler const& handler, Windows::System::Threading::WorkItemPriority const& priority) const
    {
        void* operation{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolStatics)->RunWithPriorityAsync(*(void**)(&handler), static_cast<int32_t>(priority), &operation));
        return Windows::Foundation::IAsyncAction{ operation, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolStatics<D>::RunAsync(Windows::System::Threading::WorkItemHandler const& handler, Windows::System::Threading::WorkItemPriority const& priority, Windows::System::Threading::WorkItemOptions const& options) const
    {
        void* operation{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolStatics)->RunWithPriorityAndOptionsAsync(*(void**)(&handler), static_cast<int32_t>(priority), static_cast<uint32_t>(options), &operation));
        return Windows::Foundation::IAsyncAction{ operation, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimer<D>::Period() const
    {
        Windows::Foundation::TimeSpan value;
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimer)->get_Period(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimer<D>::Delay() const
    {
        Windows::Foundation::TimeSpan value;
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimer)->get_Delay(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimer<D>::Cancel() const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimer)->Cancel());
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimerStatics<D>::CreatePeriodicTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& period) const
    {
        void* timer{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimerStatics)->CreatePeriodicTimer(*(void**)(&handler), impl::bind_in(period), &timer));
        return Windows::System::Threading::ThreadPoolTimer{ timer, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimerStatics<D>::CreateTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& delay) const
    {
        void* timer{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimerStatics)->CreateTimer(*(void**)(&handler), impl::bind_in(delay), &timer));
        return Windows::System::Threading::ThreadPoolTimer{ timer, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimerStatics<D>::CreatePeriodicTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& period, Windows::System::Threading::TimerDestroyedHandler const& destroyed) const
    {
        void* timer{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimerStatics)->CreatePeriodicTimerWithCompletion(*(void**)(&handler), impl::bind_in(period), *(void**)(&destroyed), &timer));
        return Windows::System::Threading::ThreadPoolTimer{ timer, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_System_Threading_IThreadPoolTimerStatics<D>::CreateTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& delay, Windows::System::Threading::TimerDestroyedHandler const& destroyed) const
    {
        void* timer{};
        check_hresult(WINRT_IMPL_SHIM(Windows::System::Threading::IThreadPoolTimerStatics)->CreateTimerWithCompletion(*(void**)(&handler), impl::bind_in(delay), *(void**)(&destroyed), &timer));
        return Windows::System::Threading::ThreadPoolTimer{ timer, take_ownership_from_abi };
    }
    template <typename H> struct delegate<Windows::System::Threading::TimerDestroyedHandler, H> : implements_delegate<Windows::System::Threading::TimerDestroyedHandler, H>
    {
        delegate(H&& handler) : implements_delegate<Windows::System::Threading::TimerDestroyedHandler, H>(std::forward<H>(handler)) {}

        int32_t __stdcall Invoke(void* timer) noexcept final try
        {
            (*this)(*reinterpret_cast<Windows::System::Threading::ThreadPoolTimer const*>(&timer));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename H> struct delegate<Windows::System::Threading::TimerElapsedHandler, H> : implements_delegate<Windows::System::Threading::TimerElapsedHandler, H>
    {
        delegate(H&& handler) : implements_delegate<Windows::System::Threading::TimerElapsedHandler, H>(std::forward<H>(handler)) {}

        int32_t __stdcall Invoke(void* timer) noexcept final try
        {
            (*this)(*reinterpret_cast<Windows::System::Threading::ThreadPoolTimer const*>(&timer));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename H> struct delegate<Windows::System::Threading::WorkItemHandler, H> : implements_delegate<Windows::System::Threading::WorkItemHandler, H>
    {
        delegate(H&& handler) : implements_delegate<Windows::System::Threading::WorkItemHandler, H>(std::forward<H>(handler)) {}

        int32_t __stdcall Invoke(void* operation) noexcept final try
        {
            (*this)(*reinterpret_cast<Windows::Foundation::IAsyncAction const*>(&operation));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::System::Threading::IThreadPoolStatics> : produce_base<D, Windows::System::Threading::IThreadPoolStatics>
    {
        int32_t __stdcall RunAsync(void* handler, void** operation) noexcept final try
        {
            clear_abi(operation);
            typename D::abi_guard guard(this->shim());
            *operation = detach_from<Windows::Foundation::IAsyncAction>(this->shim().RunAsync(*reinterpret_cast<Windows::System::Threading::WorkItemHandler const*>(&handler)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RunWithPriorityAsync(void* handler, int32_t priority, void** operation) noexcept final try
        {
            clear_abi(operation);
            typename D::abi_guard guard(this->shim());
            *operation = detach_from<Windows::Foundation::IAsyncAction>(this->shim().RunAsync(*reinterpret_cast<Windows::System::Threading::WorkItemHandler const*>(&handler), *reinterpret_cast<Windows::System::Threading::WorkItemPriority const*>(&priority)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RunWithPriorityAndOptionsAsync(void* handler, int32_t priority, uint32_t options, void** operation) noexcept final try
        {
            clear_abi(operation);
            typename D::abi_guard guard(this->shim());
            *operation = detach_from<Windows::Foundation::IAsyncAction>(this->shim().RunAsync(*reinterpret_cast<Windows::System::Threading::WorkItemHandler const*>(&handler), *reinterpret_cast<Windows::System::Threading::WorkItemPriority const*>(&priority), *reinterpret_cast<Windows::System::Threading::WorkItemOptions const*>(&options)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::System::Threading::IThreadPoolTimer> : produce_base<D, Windows::System::Threading::IThreadPoolTimer>
    {
        int32_t __stdcall get_Period(int64_t* value) noexcept final try
        {
            zero_abi<Windows::Foundation::TimeSpan>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::TimeSpan>(this->shim().Period());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Delay(int64_t* value) noexcept final try
        {
            zero_abi<Windows::Foundation::TimeSpan>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::TimeSpan>(this->shim().Delay());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall Cancel() noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Cancel();
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::System::Threading::IThreadPoolTimerStatics> : produce_base<D, Windows::System::Threading::IThreadPoolTimerStatics>
    {
        int32_t __stdcall CreatePeriodicTimer(void* handler, int64_t period, void** timer) noexcept final try
        {
            clear_abi(timer);
            typename D::abi_guard guard(this->shim());
            *timer = detach_from<Windows::System::Threading::ThreadPoolTimer>(this->shim().CreatePeriodicTimer(*reinterpret_cast<Windows::System::Threading::TimerElapsedHandler const*>(&handler), *reinterpret_cast<Windows::Foundation::TimeSpan const*>(&period)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateTimer(void* handler, int64_t delay, void** timer) noexcept final try
        {
            clear_abi(timer);
            typename D::abi_guard guard(this->shim());
            *timer = detach_from<Windows::System::Threading::ThreadPoolTimer>(this->shim().CreateTimer(*reinterpret_cast<Windows::System::Threading::TimerElapsedHandler const*>(&handler), *reinterpret_cast<Windows::Foundation::TimeSpan const*>(&delay)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreatePeriodicTimerWithCompletion(void* handler, int64_t period, void* destroyed, void** timer) noexcept final try
        {
            clear_abi(timer);
            typename D::abi_guard guard(this->shim());
            *timer = detach_from<Windows::System::Threading::ThreadPoolTimer>(this->shim().CreatePeriodicTimer(*reinterpret_cast<Windows::System::Threading::TimerElapsedHandler const*>(&handler), *reinterpret_cast<Windows::Foundation::TimeSpan const*>(&period), *reinterpret_cast<Windows::System::Threading::TimerDestroyedHandler const*>(&destroyed)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateTimerWithCompletion(void* handler, int64_t delay, void* destroyed, void** timer) noexcept final try
        {
            clear_abi(timer);
            typename D::abi_guard guard(this->shim());
            *timer = detach_from<Windows::System::Threading::ThreadPoolTimer>(this->shim().CreateTimer(*reinterpret_cast<Windows::System::Threading::TimerElapsedHandler const*>(&handler), *reinterpret_cast<Windows::Foundation::TimeSpan const*>(&delay), *reinterpret_cast<Windows::System::Threading::TimerDestroyedHandler const*>(&destroyed)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
}
namespace winrt::Windows::System::Threading
{
    constexpr auto operator|(WorkItemOptions const left, WorkItemOptions const right) noexcept
    {
        return static_cast<WorkItemOptions>(impl::to_underlying_type(left) | impl::to_underlying_type(right));
    }
    constexpr auto operator|=(WorkItemOptions& left, WorkItemOptions const right) noexcept
    {
        left = left | right;
        return left;
    }
    constexpr auto operator&(WorkItemOptions const left, WorkItemOptions const right) noexcept
    {
        return static_cast<WorkItemOptions>(impl::to_underlying_type(left) & impl::to_underlying_type(right));
    }
    constexpr auto operator&=(WorkItemOptions& left, WorkItemOptions const right) noexcept
    {
        left = left & right;
        return left;
    }
    constexpr auto operator~(WorkItemOptions const value) noexcept
    {
        return static_cast<WorkItemOptions>(~impl::to_underlying_type(value));
    }
    constexpr auto operator^(WorkItemOptions const left, WorkItemOptions const right) noexcept
    {
        return static_cast<WorkItemOptions>(impl::to_underlying_type(left) ^ impl::to_underlying_type(right));
    }
    constexpr auto operator^=(WorkItemOptions& left, WorkItemOptions const right) noexcept
    {
        left = left ^ right;
        return left;
    }
    inline auto ThreadPool::RunAsync(Windows::System::Threading::WorkItemHandler const& handler)
    {
        return impl::call_factory<ThreadPool, Windows::System::Threading::IThreadPoolStatics>([&](auto&& f) { return f.RunAsync(handler); });
    }
    inline auto ThreadPool::RunAsync(Windows::System::Threading::WorkItemHandler const& handler, Windows::System::Threading::WorkItemPriority const& priority)
    {
        return impl::call_factory<ThreadPool, Windows::System::Threading::IThreadPoolStatics>([&](auto&& f) { return f.RunAsync(handler, priority); });
    }
    inline auto ThreadPool::RunAsync(Windows::System::Threading::WorkItemHandler const& handler, Windows::System::Threading::WorkItemPriority const& priority, Windows::System::Threading::WorkItemOptions const& options)
    {
        return impl::call_factory<ThreadPool, Windows::System::Threading::IThreadPoolStatics>([&](auto&& f) { return f.RunAsync(handler, priority, options); });
    }
    inline auto ThreadPoolTimer::CreatePeriodicTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& period)
    {
        return impl::call_factory<ThreadPoolTimer, Windows::System::Threading::IThreadPoolTimerStatics>([&](auto&& f) { return f.CreatePeriodicTimer(handler, period); });
    }
    inline auto ThreadPoolTimer::CreateTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& delay)
    {
        return impl::call_factory<ThreadPoolTimer, Windows::System::Threading::IThreadPoolTimerStatics>([&](auto&& f) { return f.CreateTimer(handler, delay); });
    }
    inline auto ThreadPoolTimer::CreatePeriodicTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& period, Windows::System::Threading::TimerDestroyedHandler const& destroyed)
    {
        return impl::call_factory<ThreadPoolTimer, Windows::System::Threading::IThreadPoolTimerStatics>([&](auto&& f) { return f.CreatePeriodicTimer(handler, period, destroyed); });
    }
    inline auto ThreadPoolTimer::CreateTimer(Windows::System::Threading::TimerElapsedHandler const& handler, Windows::Foundation::TimeSpan const& delay, Windows::System::Threading::TimerDestroyedHandler const& destroyed)
    {
        return impl::call_factory<ThreadPoolTimer, Windows::System::Threading::IThreadPoolTimerStatics>([&](auto&& f) { return f.CreateTimer(handler, delay, destroyed); });
    }
    template <typename L> TimerDestroyedHandler::TimerDestroyedHandler(L handler) :
        TimerDestroyedHandler(impl::make_delegate<TimerDestroyedHandler>(std::forward<L>(handler)))
    {
    }
    template <typename F> TimerDestroyedHandler::TimerDestroyedHandler(F* handler) :
        TimerDestroyedHandler([=](auto&&... args) { return handler(args...); })
    {
    }
    template <typename O, typename M> TimerDestroyedHandler::TimerDestroyedHandler(O* object, M method) :
        TimerDestroyedHandler([=](auto&&... args) { return ((*object).*(method))(args...); })
    {
    }
    template <typename O, typename M> TimerDestroyedHandler::TimerDestroyedHandler(com_ptr<O>&& object, M method) :
        TimerDestroyedHandler([o = std::move(object), method](auto&&... args) { return ((*o).*(method))(args...); })
    {
    }
    template <typename O, typename M> TimerDestroyedHandler::TimerDestroyedHandler(weak_ref<O>&& object, M method) :
        TimerDestroyedHandler([o = std::move(object), method](auto&&... args) { if (auto s = o.get()) { ((*s).*(method))(args...); } })
    {
    }
    inline auto TimerDestroyedHandler::operator()(Windows::System::Threading::ThreadPoolTimer const& timer) const
    {
        check_hresult((*(impl::abi_t<TimerDestroyedHandler>**)this)->Invoke(*(void**)(&timer)));
    }
    template <typename L> TimerElapsedHandler::TimerElapsedHandler(L handler) :
        TimerElapsedHandler(impl::make_delegate<TimerElapsedHandler>(std::forward<L>(handler)))
    {
    }
    template <typename F> TimerElapsedHandler::TimerElapsedHandler(F* handler) :
        TimerElapsedHandler([=](auto&&... args) { return handler(args...); })
    {
    }
    template <typename O, typename M> TimerElapsedHandler::TimerElapsedHandler(O* object, M method) :
        TimerElapsedHandler([=](auto&&... args) { return ((*object).*(method))(args...); })
    {
    }
    template <typename O, typename M> TimerElapsedHandler::TimerElapsedHandler(com_ptr<O>&& object, M method) :
        TimerElapsedHandler([o = std::move(object), method](auto&&... args) { return ((*o).*(method))(args...); })
    {
    }
    template <typename O, typename M> TimerElapsedHandler::TimerElapsedHandler(weak_ref<O>&& object, M method) :
        TimerElapsedHandler([o = std::move(object), method](auto&&... args) { if (auto s = o.get()) { ((*s).*(method))(args...); } })
    {
    }
    inline auto TimerElapsedHandler::operator()(Windows::System::Threading::ThreadPoolTimer const& timer) const
    {
        check_hresult((*(impl::abi_t<TimerElapsedHandler>**)this)->Invoke(*(void**)(&timer)));
    }
    template <typename L> WorkItemHandler::WorkItemHandler(L handler) :
        WorkItemHandler(impl::make_delegate<WorkItemHandler>(std::forward<L>(handler)))
    {
    }
    template <typename F> WorkItemHandler::WorkItemHandler(F* handler) :
        WorkItemHandler([=](auto&&... args) { return handler(args...); })
    {
    }
    template <typename O, typename M> WorkItemHandler::WorkItemHandler(O* object, M method) :
        WorkItemHandler([=](auto&&... args) { return ((*object).*(method))(args...); })
    {
    }
    template <typename O, typename M> WorkItemHandler::WorkItemHandler(com_ptr<O>&& object, M method) :
        WorkItemHandler([o = std::move(object), method](auto&&... args) { return ((*o).*(method))(args...); })
    {
    }
    template <typename O, typename M> WorkItemHandler::WorkItemHandler(weak_ref<O>&& object, M method) :
        WorkItemHandler([o = std::move(object), method](auto&&... args) { if (auto s = o.get()) { ((*s).*(method))(args...); } })
    {
    }
    inline auto WorkItemHandler::operator()(Windows::Foundation::IAsyncAction const& operation) const
    {
        check_hresult((*(impl::abi_t<WorkItemHandler>**)this)->Invoke(*(void**)(&operation)));
    }
}
namespace std
{
    template<> struct hash<winrt::Windows::System::Threading::IThreadPoolStatics> : winrt::impl::hash_base<winrt::Windows::System::Threading::IThreadPoolStatics> {};
    template<> struct hash<winrt::Windows::System::Threading::IThreadPoolTimer> : winrt::impl::hash_base<winrt::Windows::System::Threading::IThreadPoolTimer> {};
    template<> struct hash<winrt::Windows::System::Threading::IThreadPoolTimerStatics> : winrt::impl::hash_base<winrt::Windows::System::Threading::IThreadPoolTimerStatics> {};
    template<> struct hash<winrt::Windows::System::Threading::ThreadPool> : winrt::impl::hash_base<winrt::Windows::System::Threading::ThreadPool> {};
    template<> struct hash<winrt::Windows::System::Threading::ThreadPoolTimer> : winrt::impl::hash_base<winrt::Windows::System::Threading::ThreadPoolTimer> {};
}
#endif
