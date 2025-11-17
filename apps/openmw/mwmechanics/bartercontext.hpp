#ifndef MWMECHANICS_BARTERCONTEXT_HPP
#define MWMECHANICS_BARTERCONTEXT_HPP

#include <cassert>
#include <optional>
#include <string_view>
#include <type_traits>
#include <utility>
#include <variant>

#include <components/esm3/refid.hpp>

#include "../mwworld/ptr.hpp"

namespace MWMechanics
{
    enum class BarterType
    {
        Trade,
        Training,
        SpellPurchase,
        SpellCreation,
        Enchanting,
        Repair,
        Travel,
    };

    struct ItemContext
    {
        std::optional<MWWorld::Ptr> mItem;
        std::optional<MWWorld::Ptr> mItemData;
    };

    struct TradeContext : ItemContext
    {
        int mCount = 1;
    };

    struct TrainingContext
    {
        ESM::RefId mSkillId;
        int mSkillValue = 0;
    };

    struct SpellPurchaseContext
    {
        float mSpellCost = 0.f;
    };

    struct SpellCreationContext
    {
        float mEffectCost = 0.f;
    };

    struct EnchantingContext
    {
        float mEffectCost = 0.f;
        int mItemCount = 1;
        float mTypeMultiplier = 1.f;
    };

    struct RepairContext : ItemContext
    {
        int mBaseValue = 0;
        int mCurrentCondition = 0;
        int mMaxCondition = 0;
    };

    struct TravelContext
    {
        float mDistance = 0.f;
        bool mMageGuild = false;
        int mFollowerCount = 0;
    };

    namespace Detail
    {
        template <class T>
        struct BarterContextType;

        template <>
        struct BarterContextType<TradeContext>
        {
            static constexpr BarterType value = BarterType::Trade;
        };

        template <>
        struct BarterContextType<TrainingContext>
        {
            static constexpr BarterType value = BarterType::Training;
        };

        template <>
        struct BarterContextType<SpellPurchaseContext>
        {
            static constexpr BarterType value = BarterType::SpellPurchase;
        };

        template <>
        struct BarterContextType<SpellCreationContext>
        {
            static constexpr BarterType value = BarterType::SpellCreation;
        };

        template <>
        struct BarterContextType<EnchantingContext>
        {
            static constexpr BarterType value = BarterType::Enchanting;
        };

        template <>
        struct BarterContextType<RepairContext>
        {
            static constexpr BarterType value = BarterType::Repair;
        };

        template <>
        struct BarterContextType<TravelContext>
        {
            static constexpr BarterType value = BarterType::Travel;
        };
    }

    class BarterContext
    {
    public:
        BarterContext();

        BarterType getType() const;

        template <class T>
        static BarterContext make()
        {
            BarterContext context;
            context.assign(T{});
            return context;
        }

        template <class T>
        static BarterContext make(T&& value)
        {
            BarterContext context;
            context.assign(std::move(value));
            return context;
        }

        template <class T>
        bool holds() const
        {
            return std::holds_alternative<T>(mData);
        }

        template <class T>
        T* tryGet()
        {
            if (!holds<T>())
                return nullptr;
            return &std::get<T>(mData);
        }

        template <class T>
        const T* tryGet() const
        {
            if (!holds<T>())
                return nullptr;
            return &std::get<T>(mData);
        }

        template <class T>
        T& get()
        {
            assert(holds<T>());
            return std::get<T>(mData);
        }

        template <class T>
        const T& get() const
        {
            assert(holds<T>());
            return std::get<T>(mData);
        }

    private:
        template <class T>
        void assign(T&& value)
        {
            mData = std::forward<T>(value);
        }

        using Data = std::variant<TradeContext, TrainingContext, SpellPurchaseContext, SpellCreationContext,
            EnchantingContext, RepairContext, TravelContext>;

        Data mData;
    };

    inline BarterContext::BarterContext() = default;

    inline BarterType BarterContext::getType() const
    {
        return std::visit(
            [](const auto& value) {
                using ValueType = std::decay_t<decltype(value)>;
                return Detail::BarterContextType<ValueType>::value;
            },
            mData);
    }

    std::string_view barterTypeToString(BarterType type);

}

#endif
