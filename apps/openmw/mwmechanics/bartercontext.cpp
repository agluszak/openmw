#include "bartercontext.hpp"

#include <array>

namespace MWMechanics
{
    namespace
    {
        constexpr std::array<std::string_view, 7> sTypeNames = {
            "trade", "training", "spellPurchase", "spellCreation", "enchanting", "repair", "travel" };
    }

    std::string_view barterTypeToString(BarterType type)
    {
        const auto index = static_cast<std::size_t>(type);
        if (index >= sTypeNames.size())
            return sTypeNames[0];
        return sTypeNames[index];
    }
}
