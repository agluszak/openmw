#include "apps/openmw/mwmechanics/bartercontext.hpp"

#include <gtest/gtest.h>

namespace MWMechanics
{
    namespace
    {
        TEST(BarterContextTest, BarterTypeToStringMatchesExpectedNames)
        {
            EXPECT_EQ(barterTypeToString(BarterType::Trade), "trade");
            EXPECT_EQ(barterTypeToString(BarterType::Training), "training");
            EXPECT_EQ(barterTypeToString(BarterType::SpellPurchase), "spellPurchase");
            EXPECT_EQ(barterTypeToString(BarterType::SpellCreation), "spellCreation");
            EXPECT_EQ(barterTypeToString(BarterType::Enchanting), "enchanting");
            EXPECT_EQ(barterTypeToString(BarterType::Repair), "repair");
            EXPECT_EQ(barterTypeToString(BarterType::Travel), "travel");
        }

        TEST(BarterContextTest, DefaultContextIsTrade)
        {
            BarterContext context;
            EXPECT_EQ(context.getType(), BarterType::Trade);
            const auto* trade = context.tryGet<TradeContext>();
            ASSERT_NE(trade, nullptr);
            EXPECT_EQ(trade->mCount, 1);
        }

        TEST(BarterContextTest, TrainingContextStoresSkillInformation)
        {
            auto context = BarterContext::make<TrainingContext>();
            auto& training = context.get<TrainingContext>();
            training.mSkillId = ESM::RefId::stringRefId("alchemy");
            training.mSkillValue = 25;

            ASSERT_TRUE(context.holds<TrainingContext>());
            EXPECT_EQ(context.getType(), BarterType::Training);
            const auto* other = context.tryGet<TravelContext>();
            EXPECT_EQ(other, nullptr);
            EXPECT_EQ(training.mSkillValue, 25);
            EXPECT_EQ(training.mSkillId.serializeText(), "alchemy");
        }

        TEST(BarterContextTest, RepairContextCarriesItemAndDurability)
        {
            auto context = BarterContext::make<RepairContext>();
            auto& repair = context.get<RepairContext>();
            repair.mBaseValue = 100;
            repair.mCurrentCondition = 50;
            repair.mMaxCondition = 200;

            EXPECT_EQ(context.getType(), BarterType::Repair);
            const auto* repairPtr = context.tryGet<RepairContext>();
            ASSERT_NE(repairPtr, nullptr);
            EXPECT_EQ(repairPtr->mBaseValue, 100);
            EXPECT_EQ(repairPtr->mCurrentCondition, 50);
            EXPECT_EQ(repairPtr->mMaxCondition, 200);
        }
    }
}
