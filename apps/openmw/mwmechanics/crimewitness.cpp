#include "crimewitness.hpp"

#include <algorithm>

namespace MWMechanics
{
    using MWBase::MechanicsManager;

    namespace
    {
        bool isTrespassing(OffenseType type)
        {
            return type == MechanicsManager::OT_Trespassing;
        }
    }

    MWBase::CrimeWitnessResponse buildCrimeWitnessResponse(const CrimeWitnessContext& context)
    {
        MWBase::CrimeWitnessResponse response;

        const bool guardHandlingPursuit = context.mWitnessIsGuard && context.mAlarm >= 100;
        response.mReportCrime = context.mAlarm >= 100;
        response.mSayTrespassWarning = response.mReportCrime && isTrespassing(context.mCrimeType);

        const float alarmTerm = 0.01f * static_cast<float>(context.mAlarm);
        bool applyOnlyIfHostile = false;
        bool permanent = false;
        int dispositionModifier = 0;

        switch (context.mCrimeType)
        {
            case MechanicsManager::OT_Theft:
                dispositionModifier = static_cast<int>(context.mDispTerm * alarmTerm);
                break;
            case MechanicsManager::OT_Pickpocket:
                if (context.mAlarm >= 100 && context.mWitnessIsGuard)
                    dispositionModifier = static_cast<int>(context.mDispTerm);
                else if (context.mWitnessIsVictim && context.mWitnessIsGuard)
                {
                    permanent = true;
                    dispositionModifier = static_cast<int>(context.mDispTerm * alarmTerm);
                }
                else if (context.mWitnessIsVictim)
                {
                    permanent = true;
                    dispositionModifier = static_cast<int>(context.mDispTerm);
                }
                break;
            case MechanicsManager::OT_Assault:
                if (context.mWitnessIsVictim && !context.mWitnessIsGuard)
                {
                    permanent = true;
                    dispositionModifier = static_cast<int>(context.mDispTerm);
                }
                else if (context.mAlarm >= 100)
                    dispositionModifier = static_cast<int>(context.mDispTerm);
                else if (context.mWitnessIsVictim && context.mWitnessIsGuard)
                {
                    permanent = true;
                    dispositionModifier = static_cast<int>(context.mDispTerm * alarmTerm);
                }
                else
                {
                    applyOnlyIfHostile = true;
                    dispositionModifier = static_cast<int>(context.mDispTerm * alarmTerm);
                }
                break;
            default:
                break;
        }

        if (dispositionModifier != 0)
        {
            response.mDispositionModifier = dispositionModifier;
            response.mDispositionIsPermanent = permanent;
            if (applyOnlyIfHostile)
                response.mDispositionOnlyIfHostile = true;
            else
                response.mApplyDisposition = true;
        }

        if (guardHandlingPursuit)
        {
            response.mSetAlarmed = true;
            if (!context.mWitnessInPursuit)
                response.mStartPursuit = true;
        }
        else if (context.mAllowFightResponse)
        {
            float fightTerm = context.mFightTerm;
            const int observerFightRating = context.mObserverFightRating;
            if (observerFightRating + fightTerm > 100.f)
                fightTerm = static_cast<float>(100 - observerFightRating);
            fightTerm = std::max(0.f, fightTerm);

            if (observerFightRating + fightTerm >= 100.f)
            {
                response.mStartCombat = true;
                response.mFightModifier = static_cast<int>(fightTerm);
                response.mSetAlarmed = true;
            }
        }

        return response;
    }
}
