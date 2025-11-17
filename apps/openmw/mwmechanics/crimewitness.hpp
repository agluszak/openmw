#ifndef GAME_MWMECHANICS_CRIMEWITNESS_H
#define GAME_MWMECHANICS_CRIMEWITNESS_H

#include "../mwbase/mechanicsmanager.hpp"
#include "../mwbase/luamanager.hpp"

namespace MWMechanics
{
    using OffenseType = MWBase::MechanicsManager::OffenseType;

    struct CrimeWitnessContext
    {
        OffenseType mCrimeType = MWBase::MechanicsManager::OT_Theft;
        bool mWitnessIsGuard = false;
        bool mWitnessIsVictim = false;
        bool mWitnessInPursuit = false;
        int mAlarm = 0;
        float mDispTerm = 0.f;
        int mObserverFightRating = 0;
        float mFightTerm = 0.f;
        bool mAllowFightResponse = false;
    };

    MWBase::CrimeWitnessResponse buildCrimeWitnessResponse(const CrimeWitnessContext& context);
}

#endif
