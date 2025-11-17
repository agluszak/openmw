#include "apps/openmw/mwmechanics/crimewitness.hpp"

#include <gtest/gtest.h>

namespace
{
    using namespace MWMechanics;

    CrimeWitnessContext makeBaseContext()
    {
        CrimeWitnessContext context;
        context.mCrimeType = MWBase::MechanicsManager::OT_Theft;
        context.mWitnessIsGuard = false;
        context.mWitnessIsVictim = false;
        context.mWitnessInPursuit = false;
        context.mAlarm = 0;
        context.mDispTerm = 0.f;
        context.mObserverFightRating = 30;
        context.mFightTerm = 0.f;
        context.mAllowFightResponse = true;
        return context;
    }

    TEST(MWMechanicsCrimeWitnessTest, guardWithHighAlarmReportsTrespass)
    {
        CrimeWitnessContext context = makeBaseContext();
        context.mCrimeType = MWBase::MechanicsManager::OT_Trespassing;
        context.mWitnessIsGuard = true;
        context.mAlarm = 100;
        context.mAllowFightResponse = false;

        auto response = buildCrimeWitnessResponse(context);
        EXPECT_TRUE(response.mReportCrime);
        EXPECT_TRUE(response.mSayTrespassWarning);
        EXPECT_TRUE(response.mAssignCrimeId);
        EXPECT_TRUE(response.mStartPursuit);
        EXPECT_TRUE(response.mSetAlarmed);
        EXPECT_FALSE(response.mStartCombat);
    }

    TEST(MWMechanicsCrimeWitnessTest, theftDispositionScalesWithAlarm)
    {
        CrimeWitnessContext context = makeBaseContext();
        context.mCrimeType = MWBase::MechanicsManager::OT_Theft;
        context.mAlarm = 50;
        context.mDispTerm = 20.f;

        auto response = buildCrimeWitnessResponse(context);
        EXPECT_TRUE(response.mApplyDisposition);
        EXPECT_FALSE(response.mDispositionIsPermanent);
        const int expected = static_cast<int>(context.mDispTerm * (context.mAlarm * 0.01f));
        EXPECT_EQ(response.mDispositionModifier, expected);
    }

    TEST(MWMechanicsCrimeWitnessTest, pickpocketVictimGuardGetsPermanentDisposition)
    {
        CrimeWitnessContext context = makeBaseContext();
        context.mCrimeType = MWBase::MechanicsManager::OT_Pickpocket;
        context.mAlarm = 40;
        context.mDispTerm = 15.f;
        context.mWitnessIsGuard = true;
        context.mWitnessIsVictim = true;

        auto response = buildCrimeWitnessResponse(context);
        EXPECT_TRUE(response.mDispositionIsPermanent);
        const int expected = static_cast<int>(context.mDispTerm * (context.mAlarm * 0.01f));
        EXPECT_EQ(response.mDispositionModifier, expected);
    }

    TEST(MWMechanicsCrimeWitnessTest, assaultWitnessRequiresHostility)
    {
        CrimeWitnessContext context = makeBaseContext();
        context.mCrimeType = MWBase::MechanicsManager::OT_Assault;
        context.mAlarm = 30;
        context.mDispTerm = 10.f;

        auto response = buildCrimeWitnessResponse(context);
        EXPECT_FALSE(response.mApplyDisposition);
        EXPECT_TRUE(response.mDispositionOnlyIfHostile);
        const int expected = static_cast<int>(context.mDispTerm * (context.mAlarm * 0.01f));
        EXPECT_EQ(response.mDispositionModifier, expected);
    }

    TEST(MWMechanicsCrimeWitnessTest, fightTermTriggersCombatAndClampsModifier)
    {
        CrimeWitnessContext context = makeBaseContext();
        context.mAlarm = 0;
        context.mObserverFightRating = 90;
        context.mFightTerm = 25.f;

        auto response = buildCrimeWitnessResponse(context);
        EXPECT_TRUE(response.mStartCombat);
        EXPECT_EQ(response.mFightModifier, 10);
        EXPECT_TRUE(response.mSetAlarmed);
    }
}
