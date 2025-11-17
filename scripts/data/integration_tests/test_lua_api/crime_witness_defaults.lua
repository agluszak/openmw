local types = require('openmw.types')

local OffenseType = types.Player.OFFENSE_TYPE

local function truncateToInt(value)
    local integer = select(1, math.modf(value or 0))
    return integer
end

local responseFields = {
    'reportCrime',
    'sayTrespassWarning',
    'startPursuit',
    'setAlarmed',
    'startCombat',
    'assignCrimeId',
    'applyDisposition',
    'dispositionIsPermanent',
    'dispositionOnlyIfHostile',
    'dispositionModifier',
    'fightModifier',
}

local function createResponse()
    local response = {}
    for _, field in ipairs(responseFields) do
        response[field] = false
    end
    response.dispositionModifier = 0
    response.fightModifier = 0
    return response
end

local function build(data)
    local response = createResponse()
    local typeId = data.typeId or OffenseType.Theft
    local alarm = data.alarm or 0
    local isGuard = data.isWitnessGuard or false
    local isVictim = data.isWitnessVictim or false
    local dispositionTerm = data.dispositionTerm or 0
    local witnessInPursuit = data.witnessInPursuit or false
    local allowFightResponse = data.allowFightResponse or false
    local fightTerm = data.fightTerm or 0
    local observerFightRating = data.observerFightRating or 0

    local guardHandlingPursuit = isGuard and alarm >= 100
    response.reportCrime = alarm >= 100
    if response.reportCrime and typeId == OffenseType.Trespassing then
        response.sayTrespassWarning = true
    end

    local alarmTerm = 0.01 * alarm
    local applyOnlyIfHostile = false
    local permanent = false
    local dispositionModifier = 0

    if typeId == OffenseType.Theft then
        dispositionModifier = truncateToInt(dispositionTerm * alarmTerm)
    elseif typeId == OffenseType.Pickpocket then
        if alarm >= 100 and isGuard then
            dispositionModifier = truncateToInt(dispositionTerm)
        elseif isVictim and isGuard then
            permanent = true
            dispositionModifier = truncateToInt(dispositionTerm * alarmTerm)
        elseif isVictim then
            permanent = true
            dispositionModifier = truncateToInt(dispositionTerm)
        end
    elseif typeId == OffenseType.Assault then
        if isVictim and not isGuard then
            permanent = true
            dispositionModifier = truncateToInt(dispositionTerm)
        elseif alarm >= 100 then
            dispositionModifier = truncateToInt(dispositionTerm)
        elseif isVictim and isGuard then
            permanent = true
            dispositionModifier = truncateToInt(dispositionTerm * alarmTerm)
        else
            applyOnlyIfHostile = true
            dispositionModifier = truncateToInt(dispositionTerm * alarmTerm)
        end
    end

    if dispositionModifier ~= 0 then
        response.dispositionModifier = dispositionModifier
        response.dispositionIsPermanent = permanent
        if applyOnlyIfHostile then
            response.dispositionOnlyIfHostile = true
        else
            response.applyDisposition = true
        end
    end

    if guardHandlingPursuit then
        response.setAlarmed = true
        if not witnessInPursuit then
            response.startPursuit = true
        end
    elseif allowFightResponse then
        if observerFightRating + fightTerm > 100 then
            fightTerm = 100 - observerFightRating
        end
        if fightTerm < 0 then
            fightTerm = 0
        end

        if observerFightRating + fightTerm >= 100 then
            response.startCombat = true
            response.fightModifier = truncateToInt(fightTerm)
            response.setAlarmed = true
        end
    end

    return response
end

return {
    build = build,
    fields = responseFields,
}
