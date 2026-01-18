setDefaultTab("User")

UI.Separator()
BUFF = macro(1000, "Buffs", function()
  if (stopCombo and stopCombo >= now) then return; end
  if not hasPartyBuff() and not isInPz() and (hppercent() >= 80)  and (not storage.timesela.t or storage.timesela.t < now) then
    delay(2000)
    say('kekkei genkai')
    usewith(hall, player)
    schedule(1100, function() say(storage.buffer) end)
  end
end)

 
if type(storage.timesela) ~= 'tablesela' or (storage.timesela.t - now) > 26000 then
 storage.timesela = {t = 0, a = 0}
end
local labelz = UI.TextEdit(storage.buffer or "coloque o buff", function(widget, text)    
  storage.buffer = text
end)
labelz:setFont("verdana-11px-rounded")
labelz:setColor("white")
labelz:setTooltip("Insira apenas o buff do personagem, o kekkei genkai ja esta pre-programado para ser utilizado")

UI.Separator()

Regen ={

  Regeneration = { 
    {jutsu = 'big regeneration', cooldown = 100},
  },

  Bijuu = { 
    {outfit = '302', regen = 'bijuu regeneration', cooldown = 100},
  },

  JutsuBijuu= { 
    {special = 'bijuu yaiba', cooldown = 14000},
  }

}

local valuepercent = hppercent()

local bijuuOutfits = {
    [158] = true, [161] = true, [303] = true, [269] = true,
    [162] = true, [301] = true, [302] = true, [268] = true, [531] = true
}

macro(20, function()
    if bijuuOutfits[player:getOutfit().type] then return end
    if hppercent() <= 99 then
        for index, value in ipairs(Regen.Regeneration) do
            if (not value.regenCD or value.regenCD <= now) then
                say(value.jutsu)
            end
        end
    end
end)

macro(20, function()
    if bijuuOutfits[player:getOutfit().type] then
        if hppercent() <= 99 then
            for index, value in ipairs(Regen.Bijuu) do
                if (not value.BRegenCD or value.BRegenCD <= now) then
                    say(value.regen)
                    say(value.jutsu)
                end
            end
        end
    end
end)

macro(20, function()
if not isInPz() then
  if player:getOutfit().type == 302 then
    for index, value in ipairs(Regen.JutsuBijuu) do
      if (not value.YaibaCD or value.YaibaCD <= now) then
        say(value.special)
      end
    end
  end
end
end)

onTalk(function(name, _, _, text)
text = text:lower();
if name ~= player:getName() then return; end
  for index, value in ipairs(Regen.Regeneration) do
    if text == value.jutsu then
        value.regenCD = now + 100;
    end
  end
  for index, value in ipairs(Regen.Bijuu) do
    if text == value.regen then
      value.BRegenCD = now + 100;
    end
  end
  for index, value in ipairs(Regen.JutsuBijuu) do
    if text == value.special then
      value.YaibaCD = now + 14000;
    end
  end
end)

if type(storage.hpitem1) ~= "table" then
  storage.hpitem1 = {on=false, title="HP%", item=266, min=51, max=90}
end
if type(storage.hpitem2) ~= "table" then
  storage.hpitem2 = {on=false, title="HP%", item=3160, min=0, max=50}
end
if type(storage.manaitem1) ~= "table" then
  storage.manaitem1 = {on=false, title="MP%", item=268, min=51, max=90}
end

for i, healingInfo in ipairs({storage.hpitem1, storage.hpitem2, storage.manaitem1, storage.manaitem2}) do
  local healingmacro = macro(150, function()
    local hp = i <= 2 and player:getHealthPercent() or math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if (not userPotion or userPotion <= now) then
    if healingInfo.max >= hp and hp >= healingInfo.min then
      if TargetBot then 
        TargetBot.useItem(healingInfo.item, healingInfo.subType, player) -- sync spell with targetbot if available
      else
        local thing = g_things.getThingType(healingInfo.item)
        local subType = g_game.getClientVersion() >= 860 and 0 or 1
        if thing and thing:isFluidContainer() then
          subType = healingInfo.subType
        end
        g_game.useInventoryItemWith(healingInfo.item, player, subType)
      end
    end
  end
  end)
  healingmacro.setOn(healingInfo.on)

  UI.DualScrollItemPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on and healingInfo.item > 100)
  end, leftPanel)
end

onTalk(function(name, _, _, text)
  if name == player:getName() then
    if text == 'I feel better!' then
      userPotion = now + 450
    end
  end
end)

UI.Separator()

local configPots = {
  idPots =  11808,
  percentHp = 40,
  cooldownPots = 1800000, 
  possibleTexts = { 
      'perdera skills'
  },
}

potdeath = macro(100, "Potion DeathSkill", function()
  local selfHealth = hppercent();
  if selfHealth <= configPots.percentHp then
      if (not configPots.cooldownUse or configPots.cooldownUse <= now) then
          useWith(configPots.idPots, player)
      end
  end
end, rightPanel);

onTextMessage(function(mode, text)
  text = text:lower();
  for _, possibleText in ipairs(configPots.possibleTexts) do
      filterText = possibleText:trim():lower();
      if text:find(filterText) then
          configPots.cooldownUse = now + configPots.cooldownPots;
          break;
      end
  end
end);


potdeath = addIcon("PotDeath", {item=11808, text="Death", red},potdeath)

autpill = macro(500, 'Auto-Pill', function()
local target = g_game.getAttackingCreature();
local pillId = tonumber(storage.pillId)
if not g_game.isAttacking() then return; end
if not (pillId or isInPz() or target:isPlayer()) then return; end
  if not userPill or userPill < os.time() then
      useWith(11821, player)
  end
end, rightPanel)

onTalk(function(name, _, _, text)
  if name == player:getName() then
      if text == 'Crock Crock' then
          userPill = os.time() + 30
  else    
      if text == 'Nhack Nhack' then
          userPill = os.time() + 30
             end
      end
  end
end)

autopill = addIcon("autopill", {item=11821, text="Pill", red},autpill)


------------------------------UTILITES-----------------------------------------------------
local palavraChave = 'pt' -- palavra que quer invitar aqui
local autoParty = macro(10000, "Auto Invite PT", function() end)
onTalk(function(name, level, mode, text, channelId, pos)
    if autoParty:isOff() then return end
    if player:getShield() == 4 then 
        g_game.partyShareExperience(not player:isPartySharedExperienceActive())
    end
    if name == player:getName() then return end
    if mode ~= 1 then  return end
    if string.find(text, palavraChave) then
        local friend = getPlayerByName(name)
        g_game.partyInvite(friend:getId())
    end
end)

-------------------------------------------------------

AutoAccept = macro(1000, "Auto Aceitar PT", function()
  if player:getShield() > 2 then return end
  for _, spec in pairs(getSpectators(false)) do
      if spec:getShield() == 1 then
          g_game.partyJoin(spec:getId())
          delay(1000)
      end
  end
end)

UI.Separator()

addButton(200, "Equip Senju", function()
    -- Equip Senju Helmet
    schedule(0, function() 
        moveToSlot(12898, 1)  -- Senju Helmet
    end)

    -- Equip Senju Armor
    schedule(1500, function() 
        moveToSlot(12916, 4)  -- Senju Armor
    end)

----
    -- Equip Senju Legs
    schedule(4000, function() 
        moveToSlot(12934, 7)  -- Senju Legs
    end)

    -- Equip Senju Boots
    schedule(6000, function() 
        moveToSlot(12952, 8)  -- Senju Boots
    end)
end)

macro(50, function()
  if not Maker.target and g_game.isAttacking() and g_game.getAttackingCreature():isPlayer() then
      delay(200)
      Maker.target = g_game.getAttackingCreature:getId()
  end
end)

UI.Separator()


function fakeHoverChange(creature)
    if not creature then return end

    if not modules.game_battle or not modules.game_battle.onBattleButtonHoverChange then return end

    local fakeButton = {
        creature = creature,
        isHovered = false,
        update = function() end
    }

    modules.game_battle.onBattleButtonHoverChange(fakeButton, true)
    modules.game_battle.onBattleButtonHoverChange(fakeButton, false)
end

local foco
local switchState = false
Maker = { target = nil, buttons = {}, pendingRemoval = {} }
storage.leaders = storage.leaders or { "Lider 1", "Lider 2", "Lider 3" }

function isLeaderOnScreen()
    for _, spec in ipairs(getSpectators()) do
        for _, leader in ipairs(storage.leaders) do
            if spec:isPlayer() and spec:getName() == leader then
                return true
            end
        end
    end
    return false
end

function isTargetOnScreen(targetId)
    for _, spec in ipairs(getSpectators()) do
        if spec:isPlayer() and spec:getId() == targetId then
            return spec
        end
    end
    return nil
end

HOLDER = macro(1,  function()
	if g_game.isAttacking() and not isInPz() then
	if not (Maker.target == target():getId()) then
    if g_game.getAttackingCreature():isPlayer() and not target():isPartyMember()  and not isFriend(target():getName()) then

		delay(100)
        Maker.target = g_game.getAttackingCreature():getId()
	end
end
end


end)

onTextMessage(function(mode, text)
  local match = text:match("Seu jutsu foi selado por (%d+) segundos.")
  
  if match then
      storage.timesela.t = now + tonumber(match)*1000
      
  end
end)

macro(1,  function()
	if g_game.isAttacking() and not isInPz() then
	if not (Maker.target == target():getId()) then
    if (not g_game.getAttackingCreature():isPlayer()) then
      Maker.target = 0
	end
end
end


end)

-- Resetar alvo com tecla "2"
onKeyPress(function(pressedKey)
    if pressedKey == "2" or pressedKey == "Escape" then
        
        Maker.target = 0
        modules.game_battle.autoAtaqueTarget = nil
        g_game.cancelAttackAndFollow()
        
    end
end)


onTalk(function(name, level, mode, text, channelId, pos)
  if (player:getName() ~= name) then return; end
  if string.sub(text, 1, 1):lower() == 'x' then
      local checkMsg = string.sub(text, 2):trim()
      if checkMsg == '0' then
          storage.senseNames.lastName = false;
      else
          storage.senseNames.lastName = checkMsg;
      end
  end
end)

local senseMaintain = {
senseRegex = "([a-z A-Z]*) is ([a-z -A-Z]*)to the ([a-z -A-Z]*)."
};

local http = {"H", "T", "T", "P"};
http = modules.corelib[table.concat(http)];

gameMapPanel = "gameMapPanel = g_ui.getRootWidget():%s('gameMapPanel')";

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table.concat(rec_ch_by_id);
gameMapPanel = gameMapPanel:format(rec_ch_by_id);
loadstring(gameMapPanel)();

senseMaintain.widget = [[
Panel
  image-source: /images/ui/panel_flat
  size: 45 45
  anchors.centerIn: parent
]];

senseMaintain.setupPointer = function()
if (senseMaintain.pointer) then
  senseMaintain.pointer:destroy();
end
senseMaintain.pointer = setupUI(senseMaintain.widget, gameMapPanel);

senseMaintain.pointer:setImageSource("/bot/" .. ConfigName .. "/img/styleSense", function(image)
  senseMaintain.pointer:setImageSource(image);
end)

storage.senseNames = storage.senseNames or {};
senseMaintain.initialPosition = senseMaintain.pointer:getPosition();

senseMaintain.pointer:breakAnchors();
senseMaintain.pointer:hide();

local initialPos = senseMaintain.initialPosition;

senseMaintain.positions = {
  
  north = {x = initialPos.x, y = initialPos.y - 200, rotation = 0},
  
  south = {x = initialPos.x, y = initialPos.y + 200, rotation = 180},
  
  west = {x = initialPos.x - 200, y = initialPos.y, rotation = 270},

  east = {x = initialPos.x + 200, y = initialPos.y, rotation = 90},

  ["north-west"] = {x = initialPos.x - 200, y = initialPos.y - 200, rotation = 315},
  
  ["north-east"] = {x = initialPos.x + 200, y = initialPos.y - 200, rotation = 45},
  
  ["south-west"] = {x = initialPos.x - 200, y = initialPos.y + 200, rotation = 225},
  
  ["south-east"] = {x = initialPos.x + 200, y = initialPos.y + 200, rotation = 135}
}
end

senseMaintain.setupPointer();

gameMapPanel.onGeometryChange = senseMaintain.setupPointer;

local isKeyPressed = modules.corelib.g_keyboard.isKeyPressed;

function Creature:isNearby()
local creaturePos = self:getPosition();
local playerPos = player:getPosition();
return creaturePos and creaturePos.z == playerPos.z and getDistanceBetween(playerPos, creaturePos) <= 5;
end

senseMaintain.searchWithinVariables = function() -- forEach function that contains "getatt", will try to get the creature
for key, func in pairs(g_game) do
  key = key:lower();
  if (key:match("getatt") and type(func) == 'function') then
    local result = func();
    if (result) then
      if (result:isPlayer() or result:isMonster()) then
        return result;
      end
    end
  end
end
end

battlePanel = g_ui.getRootWidget():recursiveGetChildById("battlePanel");
local ATTACKING_COLORS = {'#FF8888', '#FF0000'};

senseMaintain.getAttackingCreature = function()
local pos = pos();
for _, child in ipairs(battlePanel:getChildren()) do
  local creature = child.creature;
  if (creature) then
    local creaturePos = creature:getPosition();
    if (creaturePos and creaturePos.z == pos.z) then
      if (table.find(ATTACKING_COLORS, child.color)) then
        return creature;
      end
    end
  end
end
return senseMaintain.searchWithinVariables();
end

if (not getPlayerByName(player:getName())) then
getPlayerByName = function(name)
  if (type(name) ~= 'string') then return; end
  name = name:trim():lower();
  
  for _, tile in ipairs(g_map.getTiles(posz())) do
    for _, creature in ipairs(tile:getCreatures()) do
      if (creature:isPlayer()) then
        if (creature:getName():lower() == name) then
          return creature;
        end
      end
    end
  end
end
end

macro(1, function()
  if stopToCast() or (stopCombo and stopCombo >= now) then return; end
local target = senseMaintain.getAttackingCreature();

if (target and target:isPlayer()) then
  local targetName = target:getName();
  if (not table.find(storage.senseNames, targetName, true)) then
    storage.senseNames.targetName = targetName;
  end
end



for _, value in ipairs({
  {
    key = storage.keySenseTarget,
    name = storage.senseNames.targetName;
  },
  
  {
    key = storage.keySenseX,
    name = storage.senseNames.lastName;
  }	
}) do 
  if (value.name) then
    if (isKeyPressed(value.key)) then
      local creature = getPlayerByName(value.name);
      if (not creature or not creature:isNearby()) then
        return say('sense "' .. value.name);
      end
    end
  end
end
end)

senseMaintain.getPositionByName = function(name)
name = name:trim();

return senseMaintain.positions[name];
end

onTextMessage(function(mode, text)
if (mode ~= 20) then return; end
local data = regexMatch(text, senseMaintain.senseRegex)[1];
if (not data or #data < 4) then return; end

local position = senseMaintain.getPositionByName(data[4]);
senseMaintain.pointer.timeLapse = now + 5000;
local senseName = data[2];
if (not table.find(storage.senseNames, senseName, true)) then
  storage.senseNames.lastName = senseName:trim();
end
senseMaintain.pointer:setPosition({x = position.x, y = position.y});
senseMaintain.pointer:setRotation(position.rotation);
senseMaintain.lastName = senseName;
end)


macro(1, function()
senseMaintain.pointer:hide();
local timer = senseMaintain.pointer.timeLapse;
if (not timer or timer < now) then return; end

local creature = getPlayerByName(senseMaintain.lastName);

if (creature and creature:isNearby()) then return; end

senseMaintain.pointer:show();
end)

UI.Separator()


local qqca = UI.Label("Atalhos SENSE")
qqca:setFont("verdana-11px-rounded")
qqca:setColor("orange")

local qqcoisa = UI.TextEdit(storage.keySenseTarget or "V", function(widget, text)
  storage.keySenseTarget = text
  end)
  qqcoisa:setFont("verdana-11px-rounded")
  qqcoisa:setColor("white")
  qqcoisa:setTooltip("Preencha com o atalho que deseja para utilizar o sense target")

local qqcoisa = UI.TextEdit(storage.keySenseX or "T", function(widget, text)
    storage.keySenseX = text
end)
qqcoisa:setFont("verdana-11px-rounded")
qqcoisa:setColor("white")
qqcoisa:setTooltip("Preencha com o atalho que deseja para utilizar o sense X")

