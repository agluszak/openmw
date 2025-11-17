local core = require('openmw.core')
local types = require('openmw.types')
local auxUtil = require('openmw_aux.util')

local NPC = types.NPC

local transactionTypes = {
    trade = 'trade',
    training = 'training',
    spellPurchase = 'spellPurchase',
    spellCreation = 'spellCreation',
    enchanting = 'enchanting',
    repair = 'repair',
    travel = 'travel',
}

local gmstCache = {}
local function getGMST(id)
    local value = gmstCache[id]
    if value == nil then
        value = core.getGMST(id)
        gmstCache[id] = value
    end
    return value
end

local function getFatigueTerm(actor)
    local fatigue = NPC.stats.dynamic.fatigue(actor)
    local maxFatigue = fatigue.modified
    local currentFatigue = fatigue.current
    local normalized = 1
    if math.floor(maxFatigue) ~= 0 then
        normalized = math.max(0, currentFatigue / maxFatigue)
    end
    return getGMST('fFatigueBase') - getGMST('fFatigueMult') * (1 - normalized)
end

local function clampDisposition(merchant, player)
    local disposition = NPC.getDisposition(merchant, player)
    if disposition < 0 then
        return 0
    elseif disposition > 100 then
        return 100
    end
    return disposition
end

local function shallowCopy(tableToCopy)
    local copy = {}
    if tableToCopy then
        for key, value in pairs(tableToCopy) do
            copy[key] = value
        end
    end
    return copy
end

local function buildContext(merchant, player, basePrice, buying, overrides)
    local context = shallowCopy(overrides)
    context.merchant = merchant or context.merchant
    context.player = player or context.player
    context.basePrice = basePrice or context.basePrice or 0
    context.price = context.price or context.basePrice
    context.buying = buying ~= nil and buying or context.buying or false
    context.count = context.count or 1
    context.type = context.type or transactionTypes.trade
    return context
end

local calcHandlers = {}

local function getTrainingBasePrice(context)
    if not context.training then
        return context.basePrice
    end
    local base = context.training.skillValue or 0
    return math.max(1, base * getGMST('iTrainingMod'))
end

local function getSpellPurchaseBasePrice(context)
    if not context.spellPurchase then
        return context.basePrice
    end
    return math.max(1, context.spellPurchase.spellCost * getGMST('fSpellValueMult'))
end

local function getSpellCreationBasePrice(context)
    if not context.spellCreation then
        return context.basePrice
    end
    return math.max(1, context.spellCreation.effectCost * getGMST('fSpellMakingValueMult'))
end

local function getEnchantingBasePrice(context)
    if not context.enchanting then
        return context.basePrice
    end
    local effectCost = context.enchanting.effectCost or 0
    return math.max(1, math.floor(effectCost * getGMST('fEnchantmentValueMult')))
end

local function getRepairBasePrice(context)
    if not context.repair then
        return context.basePrice
    end
    local maxDurability = context.repair.maxCondition or 0
    local currentDurability = context.repair.currentCondition or 0
    if maxDurability <= currentDurability or maxDurability == 0 then
        return 0
    end
    local baseValue = math.max(1, context.repair.baseValue or 0)
    local repairMult = getGMST('fRepairMult')
    local unit = math.max(1, math.floor(maxDurability / baseValue))
    local amount = math.floor((maxDurability - currentDurability) / unit)
    return math.max(1, math.floor(repairMult * amount))
end

local function getTravelBasePrice(context)
    if not context.travel then
        return context.basePrice
    end
    local mageGuild = context.travel.mageGuild
    local basePrice
    if mageGuild then
        basePrice = getGMST('fMagesGuildTravel')
    else
        local distance = context.travel.distance or 0
        local travelMult = getGMST('fTravelMult')
        if travelMult ~= 0 then
            basePrice = math.floor(distance / travelMult)
        else
            basePrice = math.floor(distance)
        end
    end
    basePrice = math.max(1, basePrice)
    local followers = context.travel.followers or 0
    return basePrice * (1 + math.max(0, followers))
end

local function applyBasePrice(context)
    local basePrice = context.basePrice
    if context.type == transactionTypes.training then
        basePrice = getTrainingBasePrice(context)
    elseif context.type == transactionTypes.spellPurchase then
        basePrice = getSpellPurchaseBasePrice(context)
    elseif context.type == transactionTypes.spellCreation then
        basePrice = getSpellCreationBasePrice(context)
    elseif context.type == transactionTypes.enchanting then
        basePrice = getEnchantingBasePrice(context)
    elseif context.type == transactionTypes.repair then
        basePrice = getRepairBasePrice(context)
    elseif context.type == transactionTypes.travel then
        basePrice = getTravelBasePrice(context)
    end
    context.basePrice = basePrice
    return basePrice
end

local function applyPostMultipliers(context, price)
    if context.type == transactionTypes.enchanting and context.enchanting then
        local count = context.enchanting.itemCount or 1
        local multiplier = context.enchanting.typeMultiplier or 1
        price = price * count * multiplier
    end
    return price
end

local function defaultPriceHandler(context)
    if not context.merchant or not context.player then
        return
    end
    if not NPC.objectIsInstance(context.merchant) or not NPC.objectIsInstance(context.player) then
        return
    end

    local basePrice = applyBasePrice(context)
    if basePrice <= 0 then
        context.price = basePrice
        return
    end

    local disposition = clampDisposition(context.merchant, context.player)
    local playerStats = NPC.stats
    local playerMercantile = math.min(playerStats.skills.mercantile(context.player).modified, 100)
    local playerLuck = math.min(0.1 * playerStats.attributes.luck(context.player).modified, 10)
    local playerPersonality = math.min(0.2 * playerStats.attributes.personality(context.player).modified, 10)

    local merchantStats = NPC.stats
    local merchantMercantile = math.min(merchantStats.skills.mercantile(context.merchant).modified, 100)
    local merchantLuck = math.min(0.1 * merchantStats.attributes.luck(context.merchant).modified, 10)
    local merchantPersonality = math.min(0.2 * merchantStats.attributes.personality(context.merchant).modified, 10)

    local pcTerm = (disposition - 50 + playerMercantile + playerLuck + playerPersonality)
        * getFatigueTerm(context.player)
    local npcTerm = (merchantMercantile + merchantLuck + merchantPersonality) * getFatigueTerm(context.merchant)
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))

    local factor = context.buying and buyTerm or sellTerm
    local price = math.floor(basePrice * factor)
    price = applyPostMultipliers(context, price)
    if price < 1 then
        price = 1
    end
    context.price = price
end

calcHandlers[#calcHandlers + 1] = defaultPriceHandler

local function calcBarterPrice(merchant, player, basePrice, buying, overrides)
    local context = buildContext(merchant, player, basePrice, buying, overrides)
    auxUtil.callEventHandlers(calcHandlers, context)
    local price = context.price or 0
    if context.basePrice and context.basePrice > 0 then
        price = math.max(1, price)
    end
    return math.floor(price)
end

---
-- Context data passed to @{#Barter.addCalcBarterPriceHandler} handlers.
-- @type BarterPriceContext
-- @field openmw.core#GameObject merchant The merchant taking part in the transaction.
-- @field openmw.core#GameObject player The player that is trading.
-- @field #boolean buying True when the player is buying items or services from the merchant.
-- @field #string type Transaction type. One of ``trade``, ``training``, ``spellPurchase``, ``spellCreation``, ``enchanting``, ``repair``, or ``travel``.
-- @field #number basePrice Base price before any modifiers are applied.
-- @field #number price The current calculated price. Handlers may modify this value.
-- @field #number count Number of items in the transaction. Defaults to 1 when not supplied.
-- @field #any item Optional item that is being traded.
-- @field #any itemData Optional item data being traded.
-- @field #table training Present for ``training`` transactions. Contains ``skillId`` and ``skillValue``.
-- @field #table spellPurchase Present for ``spellPurchase`` transactions. Contains ``spellCost``.
-- @field #table spellCreation Present for ``spellCreation`` transactions. Contains ``effectCost``.
-- @field #table enchanting Present for ``enchanting`` transactions. Contains ``effectCost``, ``itemCount``, and ``typeMultiplier``.
-- @field #table repair Present for ``repair`` transactions. Contains ``baseValue``, ``currentCondition``, and ``maxCondition``.
-- @field #table travel Present for ``travel`` transactions. Contains ``distance``, ``mageGuild``, and ``followers``.

return {
    interfaceName = 'Barter',
    ---
    -- Allows customizing barter price calculations.
    -- @module Barter
    -- @context global
    -- @usage local I = require('openmw.interfaces')
    -- I.Barter.addCalcBarterPriceHandler(function(context)
    --     if context.item and context.item.id == 'gold_001' then
    --         context.price = 1
    --         return false
    --     end
    -- end)
    interface = {
        --- Interface version.
        -- @field [parent=#Barter] #number version
        version = 2,

        --- Add a new price calculation handler.
        -- Handlers receive a @{#BarterPriceContext}. Returning ``false`` stops further handlers, including the default one.
        -- @function [parent=#Barter] addCalcBarterPriceHandler
        -- @param #function handler
        addCalcBarterPriceHandler = function(handler)
            calcHandlers[#calcHandlers + 1] = handler
        end,

        --- Calculate a barter price.
        -- @function [parent=#Barter] calcBarterPrice
        -- @param openmw.core#GameObject merchant
        -- @param openmw.core#GameObject player
        -- @param #number basePrice
        -- @param #boolean buying
        -- @param #table overrides Optional table merged into the context before handlers run.
        -- @return #number The calculated price.
        calcBarterPrice = calcBarterPrice,
    },
}
