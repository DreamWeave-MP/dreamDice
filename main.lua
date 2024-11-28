-- Roll = require('roll')
-- Roll = require('custom.dreamDice.roll')
local lastRolls = {}

Roll:addSkills {
  lb = 'Longblade',
  sb = 'Shortblade',
}

local function sendMessageToVisitors(cellDescription, message)
  assert(logicHandler.IsCellLoaded(cellDescription), 'A player is in this cell, why wouldn\'t it be loaded?')

  for _, visitorPid in pairs(LoadedCells[cellDescription].visitors) do
    tes3mp.SendMessage(visitorPid, message, false)
  end
end

local function roll(pid, cmd)
  local player = Players[pid]
  if not player or not player:IsLoggedIn() then return end

  local thisRoll = cmd[2]

  if thisRoll and thisRoll ~= '' then

    local rollInput
    local statName, statRoll = Roll:fromStatId(pid, thisRoll)
    if not statRoll then rollInput = thisRoll else rollInput = statRoll end

    ---@type RollObject
    local currentRoll = Roll(rollInput)

    currentRoll:log(pid)

    lastRolls[pid] = currentRoll

    thisRoll = currentRoll:getResultMessage {
      playerId = pid,
      forStat = statName,
    }
  else
    thisRoll = 'Invalid roll command.\nExample: /roll 2d2-4\n'
  end

  sendMessageToVisitors(player.data.location.cell, thisRoll)
end

local function reroll(pid, _)
  local player = Players[pid]
  assert(player and player:IsLoggedIn()
         , 'Player must be logged in to reroll!')

  local message = player.accountName .. " does not have a previous roll to retry!\n"

  if lastRolls[pid] then message = lastRolls[pid]:getResultMessage{ playerId = pid } end

  sendMessageToVisitors(player.data.location.cell, message)
end

customCommandHooks.registerCommand("roll", roll)
customCommandHooks.registerCommand("reroll", reroll)
