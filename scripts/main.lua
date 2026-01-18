
-- load all otui files, order doesn't matter
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/tools", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadScript(name)
  return dofile("/tools/" .. name .. ".lua")
end

-- here you can set manually order of scripts
-- libraries should be loaded first
local luaFiles = {
  "main",
  "vlib",
  "configs", -- do not change this and above
  "spy_level",
  "tools",
  "spyy_level"

}

for i, file in ipairs(luaFiles) do
  loadScript(file)
end

scriptFuncs = {};
comboSpellsWidget = {};
fugaSpellsWidgets = {};

scriptFuncs.readProfile = function(filePath, callback)
  if g_resources.fileExists(filePath) then
      local status, result = pcall(function()
          return json.decode(g_resources.readFileContents(filePath))
      end)
      if not status then
          return onError("Erro carregando arquivo (" .. filePath .. "). Para consertar o problema, exclua o arquivo. Detalhes: " .. result)
      end

      callback(result);
  end
end

scriptFuncs.saveProfile = function(configFile, content)
  local status, result = pcall(function()
      return json.encode(content, 2)
  end);

  if not status then
      return onError("Erro salvando configuração. Detalhes: " .. result);
  end

  if result:len() > 100 * 1024 * 1024 then
      return onError("Arquivo de configuração acima de 100MB, não será salvo.");
  end

  g_resources.writeFileContents(configFile, result);
end

storageProfiles = {
  comboSpells = {},
  fugaSpells = {},
  keySpells = {}
}

MAIN_DIRECTORY = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
STORAGE_DIRECTORY = "" .. MAIN_DIRECTORY .. g_game.getWorldName() .. '.json';


if not g_resources.directoryExists(MAIN_DIRECTORY) then
  g_resources.makeDir(MAIN_DIRECTORY);
end

scriptFuncs.readProfile(STORAGE_DIRECTORY, function(result)
  storageProfiles = result
  if (type(storageProfiles.comboSpells) ~= 'table') then
      storageProfiles.comboSpells = {};
  end
  if (type(storageProfiles.fugaSpells) ~= 'table') then
      storageProfiles.fugaSpells = {};
  end
  if (type(storageProfiles.keySpells) ~= 'table') then
      storageProfiles.keySpells = {};
  end
end);


scriptFuncs.reindexTable = function(t)
  if not t or type(t) ~= "table" then return end

  local i = 0
  for _, e in pairs(t) do
      i = i + 1
      e.index = i
  end
end

firstLetterUpper = function(str)
  return (str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end))
end

function formatTime(seconds)
  if seconds < 60 then
      return seconds .. 's'
  else
      local minutes = math.floor(seconds / 60)
      local remainingSeconds = seconds % 60
      return string.format("%dm %02ds", minutes, remainingSeconds)
  end
end


formatRemainingTime = function(time)
  local remainingTime = (time - now) / 1000;
  local timeText = '';
  timeText = string.format("%.0f", (time - now) / 1000).. "s";
  return timeText;
end


attachSpellWidgetCallbacks = function(widget, spellId, table)
  widget.onDragEnter = function(self, mousePos)
      if not modules.corelib.g_keyboard.isCtrlPressed() then
          return false
      end
      self:breakAnchors()
      self.movingReference = { x = mousePos.x - self:getX(), y = mousePos.y - self:getY() }
      return true
  end

  widget.onDragMove = function(self, mousePos, moved)
      local parentRect = self:getParent():getRect()
      local newX = math.min(math.max(parentRect.x, mousePos.x - self.movingReference.x), parentRect.x + parentRect.width - self:getWidth())
      local newY = math.min(math.max(parentRect.y - self:getParent():getMarginTop(), mousePos.y - self.movingReference.y), parentRect.y + parentRect.height - self:getHeight())
      self:move(newX, newY)
      if table[spellId] then
          table[spellId].widgetPos = {x = newX, y = newY}
          scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)
      end
      return true
  end

  widget.onDragLeave = function(self, pos)
      return true
  end
end
--[[
function toMoveUp(window, table)
  local action = window.spellList:getFocusedChild();
  if (not action) then return; end
  local index = window.spellList:getChildIndex(action);
  if (index < 2) then return; end
  window.spellList:moveChildToIndex(action, index - 1);
  window.spellList:ensureChildVisible(action);
  table[index].index = index - 1;
  table[index - 1].index = index;
  table.sort(table, function(a,b) return a.index < b.index end)
  scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

function toMoveDown(window, table)
  local action = window.spellList:getFocusedChild();
  if (not action) then return; end
  local index = window.spellList:getChildIndex(action);
  if (index < 2) then return; end
  window.spellList:moveChildToIndex(action, index - 1);
  window.spellList:ensureChildVisible(action);
  table[index].index = index - 1;
  table[index - 1].index = index;
  table.sort(table, function(a,b) return a.index < b.index end)
  scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end
]]--

function stopToCast()
  for index, value in ipairs(storageProfiles.fugaSpells) do
      if value.enabled and value.activeCooldown and value.activeCooldown >= now then return true; end
      if hppercent() <= calculatePercentage(value.selfHealth) + 5 then
          if (not value.totalCooldown or value.totalCooldown <= now) then
              return true;
          end
      end
  end
  return false;
end

function isAnySelectedKeyPressed()
  for index, value in ipairs(storageProfiles.keySpells) do
      if value.enabled and (modules.corelib.g_keyboard.isKeyPressed(value.keyPress)) then
          return true;
      end
  end
  return false;
end 

labelcc = UI.Label("Delay Macros")
labelcc:setFont("verdana-11px-rounded")
labelcc:setColor("orange")

DelayMacro = {}
DelayMacro.horizontalScrollBar = [[
Panel
  height: 15
  margin-top: 2

  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 3
    minimum: 0
    maximum: 10
    step: 1
    font: verdana-11px-rounded
]]
storage.scrollBars1 = storage.scrollBars1 or {}

local function addScrollBar(id, title, min, max, defaultValue)
	local widget = setupUI(DelayMacro.horizontalScrollBar, panel)

	widget.scroll:setRange(min, max)

	if max - min > 1000 then
		widget.scroll:setStep(100)
	elseif max - min > 100 then
		widget.scroll:setStep(10)
	end

	widget.scroll:setValue(storage.scrollBars1[id] or defaultValue)

	function widget.scroll.onValueChange(scroll, value)
		storage.scrollBars1[id] = value

		widget.scroll:setText(value .. "ms")
	end

	widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
end

addScrollBar("macroDelay", "", 10, 1000, 200);

UI.Separator()

labelcc = UI.Label("Filtro Battle")
labelcc:setFont("verdana-11px-rounded")
labelcc:setColor("orange")

local PainelName = "FiltroBattles"
FiltroIcon = setupUI([[
Panel
  height: 20
  margin-top: 3
  
  Panel
    id: inicio
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 0
    margin-top:
    image-border: 2
    text-align: center
    text-align: left
    width: 200
    height: 20
    image-source: 
    font: verdana-11px-rounded
    opacity: 0.80

  Panel
    id: buttons
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    height: 20
    width: 15 0
    layout:
      type: horizontalBox
      spacing: 20

  BattlePlayers
    id: players
    border: 1 #778899
    image-color: white
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 27
    image-source: /images/game/battle/battle_players
    !tooltip: tr('Filtrar players.')

  BattleNPCs
    id: npcs
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_npcs
    !tooltip: tr('Filtrar Npcs.')

  BattleMonsters
    id: mobs
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_monsters
    !tooltip: tr('Filtrar mobs.')
    opacity: 1.00

  BattleSkulls
    id: sempk
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_skulls
    !tooltip: tr('Filtrar Player sem PK.')
    opacity: 1.00

  BattleParty
    id: party
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_party
    !tooltip: tr('Filtrar Membros do Grupo.')
    opacity: 1.00
]], parent)

storage.FiltroPlayers = storage.FiltroPlayers or false
storage.FiltroNpcs = storage.FiltroNpcs or false
storage.FiltroMobs = storage.FiltroMobs or false
storage.FiltroSkull = storage.FiltroSkull or false
storage.FiltroParty = storage.FiltroParty or false

macro(100, function()
  if storage.FiltroPlayers then
    FiltroIcon.players:setImageColor('#696969')
  else
    FiltroIcon.players:setImageColor('#FFFFFF')
  end

  if storage.FiltroNpcs then
    FiltroIcon.npcs:setImageColor('#696969')
  else
    FiltroIcon.npcs:setImageColor('#FFFFFF')
  end

  if storage.FiltroMobs then
    FiltroIcon.mobs:setImageColor('#696969')
  else
    FiltroIcon.mobs:setImageColor('#FFFFFF')
  end

  if storage.FiltroSkull then
    FiltroIcon.sempk:setImageColor('#696969')
  else
    FiltroIcon.sempk:setImageColor('#FFFFFF')
  end

  if storage.FiltroParty then
    FiltroIcon.party:setImageColor('#696969')
  else
    FiltroIcon.party:setImageColor('#FFFFFF')
  end
end)

FiltroIcon.players.onClick = function(widget)
  storage.FiltroPlayers = not storage.FiltroPlayers
end

FiltroIcon.npcs.onClick = function(widget)
  storage.FiltroNpcs = not storage.FiltroNpcs
end

FiltroIcon.mobs.onClick = function(widget)
  storage.FiltroMobs = not storage.FiltroMobs
end

FiltroIcon.sempk.onClick = function(widget)
  storage.FiltroSkull = not storage.FiltroSkull
end

FiltroIcon.party.onClick = function(widget)
  storage.FiltroParty = not storage.FiltroParty
end

FiltrarBattle = macro(1, function() end)
modules.game_battle.doCreatureFitFilters = function(creature)
  if creature:isLocalPlayer() or creature:getHealthPercent() <= 0 then
    return false
  end
  local pos = creature:getPosition()
  if not pos or pos.z ~= posz() or not creature:canBeSeen() then return false end

  if creature:isMonster() and FiltrarBattle.isOn() and storage.FiltroMobs then
    return false
  elseif creature:isPlayer() and FiltrarBattle.isOn() and storage.FiltroPlayers then
    return false
  elseif creature:isNpc() and FiltrarBattle.isOn() and storage.FiltroNpcs then
    return false
  elseif creature:isPlayer() and (creature:getEmblem() == 1 or creature:getShield() == 3 or creature:getShield() == 4) and FiltrarBattle.isOn() and storage.FiltroParty then
    return false
  elseif creature:isPlayer() and creature:getSkull() == 0 and storage.FiltroSkull then
    return false
  end
  return true
end

mainTab:setImageSource("/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/img/fundocustom")
modules.game_bot.botWindow:setWidth(216)

local function updateButtonsBot()
  modules.game_bot.contentsPanel.config:setImageSource()
  modules.game_bot.contentsPanel.editConfig:setImageSource()
  modules.game_bot.contentsPanel.enableButton:setImageSource()
  modules.game_bot.contentsPanel.config:setBackgroundColor("#1C1C1C")
  modules.game_bot.contentsPanel.config:setOpacity(1.00)
  modules.game_bot.contentsPanel.config:setFont("verdana-11px-rounded")
  modules.game_bot.contentsPanel.config:setMarginLeft(-1)
  modules.game_bot.contentsPanel.editConfig:setBackgroundColor("#1C1C1C")
  modules.game_bot.contentsPanel.editConfig:setOpacity(1.00)
  modules.game_bot.contentsPanel.editConfig:setFont("verdana-11px-rounded")
  modules.game_bot.contentsPanel.enableButton:setBackgroundColor("#1C1C1C")
  modules.game_bot.contentsPanel.enableButton:setOpacity(1.00)
  modules.game_bot.contentsPanel.enableButton:setFont("verdana-11px-rounded")
  modules.game_bot.contentsPanel.enableButton:setMarginRight(-1)
  modules.game_bot.botWindow.closeButton:setImageColor("#363434")
  modules.game_bot.botWindow.minimizeButton:setImageColor("#363434")
  modules.game_bot.botWindow.lockButton:setImageColor("#363434")
  modules.game_bot.botWindow:setImageSource()
  modules.game_bot.botWindow:setBackgroundColor("black")
  modules.game_bot.botWindow:setBorderWidth(1)
  modules.game_bot.botWindow:setBorderColor("black")
  modules.game_bot.botWindow:setText("NTO Ultimate")
  modules.game_bot.botWindow:setFont("verdana-11px-rounded")
  modules.game_bot.botWindow:setColor("white")
end
updateButtonsBot()

local count = 0
local function removeSeparators()
  for _, i in pairs(modules.game_bot.botWindow.contentsPanel:getChildren()) do
    if count >= 2 then break end
      if i:getStyleName() == "HorizontalSeparator" then
        i:destroy()
        count = count + 1
      end
  end
end
removeSeparators()