local types = require('openmw.types')
local I = require('openmw.interfaces')
local auxUtil = require('openmw_aux.util')

---
-- Table with information needed to commit crimes.
-- @type CommitCrimeInputs
-- @field openmw.core#GameObject victim The victim of the crime (optional)
-- @field openmw.types#OFFENSE_TYPE_IDS type The type of the crime to commit. See @{openmw.types#OFFENSE_TYPE_IDS} (required)
-- @field #string faction ID of the faction the crime is committed against (optional)
-- @field #number arg The amount to increase the player bounty by, if the crime type is theft. Ignored otherwise (optional, defaults to 0)
-- @field #boolean victimAware Whether the victim is aware of the crime (optional, defaults to false)

---
-- Table containing information returned by the engine after committing a crime
-- @type CommitCrimeOutputs
-- @field #boolean wasCrimeSeen Whether the crime was seen

---
-- Data describing a crime witness event.
-- @type CrimeWitnessData
-- @field openmw.core#GameObject criminal The actor committing the crime (always the player)
-- @field openmw.core#GameObject witness The actor that detected the crime
-- @field openmw.core#GameObject victim The crime victim, if any
-- @field #string type The type of crime (e.g. "theft", "attack", "killing", "pickpocket", "trespass")
-- @field #number value The numeric value associated with the crime (stolen value or bounty component)
-- @field openmw.util#vector3 position Position where the crime was detected
-- @field #string factionId The faction the crime was committed against, if any
-- @field #boolean victimAware True if the witness is the victim and already aware of the crime
-- @field #boolean isVictimWitness True if the witness is also the victim
-- @field #boolean hadLineOfSight True if the witness had line of sight to the player
-- @field #boolean awarenessPassed True if the witness passed the standard awareness check
-- @field #number realTimestamp Real time timestamp (same as `core.getRealTime()`)

local witnessHandlers = {}

return {
    interfaceName = 'Crimes',
    ---
    -- Allows to utilize built-in crime mechanics.
    -- @module Crimes
    -- @context global
    -- @usage require('openmw.interfaces').Crimes
    interface = {
        --- Interface version
        -- @field [parent=#Crimes] #number version
        version = 3,

        ---
        -- Commits a crime as if done through an in-game action. Can only be used in global context.
        -- @function [parent=#Crimes] commitCrime
        -- @param openmw.core#GameObject player The player committing the crime
        -- @param CommitCrimeInputs options A table of parameters describing the committed crime
        -- @return CommitCrimeOutputs A table containing information about the committed crime
        commitCrime = function(player, options)
            assert(types.Player.objectIsInstance(player), "commitCrime requires a player game object")

            local returnTable = {}
            local options = options or {}

            assert(type(options.faction) == "string" or options.faction == nil,
                "faction id passed to commitCrime must be a string or nil")
            assert(type(options.arg) == "number" or options.arg == nil,
                "arg value passed to commitCrime must be a number or nil")
            assert(type(options.victimAware) == "boolean" or options.victimAware == nil,
                "victimAware value passed to commitCrime must be a boolean or nil")

            assert(options.type ~= nil, "crime type passed to commitCrime cannot be nil")
            assert(type(options.type) == "number", "crime type passed to commitCrime must be a number")

            assert(options.victim == nil or types.NPC.objectIsInstance(options.victim),
                "victim passed to commitCrime must be an NPC or nil")

            returnTable.wasCrimeSeen = types.Player._runStandardCommitCrime(player, options.victim, options.type,
                options.faction or "",
                options.arg or 0, options.victimAware or false)
            return returnTable
        end,

        ---
        -- Registers a handler that runs whenever a crime is witnessed. Returning `false`
        -- from the handler prevents the default witness reaction and keeps the crime unseen.
        -- @function [parent=#Crimes] addWitnessHandler
        -- @param #function handler The handler to run. Receives @{CrimeWitnessData}.
        -- @return #function The handler reference that can be used with @{removeWitnessHandler}.
        addWitnessHandler = function(handler)
            assert(type(handler) == 'function', 'addWitnessHandler requires a function')
            witnessHandlers[#witnessHandlers + 1] = handler
            return handler
        end,

        ---
        -- Removes a handler previously added with @{addWitnessHandler}.
        -- @function [parent=#Crimes] removeWitnessHandler
        -- @param #function handler The handler to remove.
        removeWitnessHandler = function(handler)
            for i = #witnessHandlers, 1, -1 do
                if witnessHandlers[i] == handler then
                    table.remove(witnessHandlers, i)
                    break
                end
            end
        end,

        _onCrimeWitnessed = function(data)
            return not auxUtil.callEventHandlers(witnessHandlers, data)
        end,
    },
    eventHandlers = {
        CommitCrime = function(data) I.Crimes.commitCrime(data.player, data) end,
    }
}
