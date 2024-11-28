-- Roll = require('roll')
-- Roll = require('custom.dreamDice.roll')
local lastRolls = {}

Roll:addSkills {
  lb = 'Longblade',
  sb = 'Shortblade',
}

local function sendMessageToVisitors(cellDescription, message)
  local cell = LoadedCells[cellDescription]
  assert(cell, 'A player is in this cell, why wouldn\'t it be loaded?' .. debug.traceback(3))

  for _, visitorPid in ipairs(cell.visitors) do
    tes3mp.SendMessage(visitorPid, message, false)
  end
end

 local function sendMessage(message, sendToAllOrCellDesc, playerId)
  if sendToAllOrCellDesc == true then
    tes3mp.SendMessage(playerId, message, true)
    return
  end
  assert(type(sendToAllOrCellDesc) == 'string', 'Cannot send a message to a non-string cell description!')
  sendMessageToVisitors(sendToAllOrCellDesc, message)
end

local function roll(pid, cmd, sendToAll)
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

  local sendToAllOrCellDesc = (sendToAll and sendToAll) or player.data.location.cell

  sendMessage(thisRoll, sendToAllOrCellDesc, pid)
end

local function reroll(pid, sendToAll)
  local player = Players[pid]
  assert(player and player:IsLoggedIn()
         , 'Player must be logged in to reroll!')

  local message = player.accountName .. " does not have a previous roll to retry!\n"

  if lastRolls[pid] then message = lastRolls[pid]:getResultMessage{ playerId = pid } end

  local sendToAllOrCellDesc = (sendToAll and sendToAll) or player.data.location.cell

  sendMessage(message, sendToAllOrCellDesc, pid)
end

customCommandHooks.registerCommand("roll", function(pid, cmd) roll(pid, cmd, false) end)
customCommandHooks.registerCommand("rollg", function(pid, cmd) roll(pid, cmd, true) end)
customCommandHooks.registerCommand("reroll", function(pid) reroll(pid, false) end)
customCommandHooks.registerCommand("rerollg", function(pid) reroll(pid, true) end)
