setDefaultTab("HTKS")

UI.Separator()

--[[Pz Time/Pk Time]]--

local storage = storage;

local pzTime = 15
	

os = os or modules.os

if type(storage.battleTracking) ~= "table" or storage.battleTracking[2] ~= player:getId() or (not os and storage.battleTracking[1] - now > pzTime * 60 * 1000) then
    storage.battleTracking = {0, player:getId(), {}}
end 

onTextMessage(function(mode, text)
	text = text:lower()
	if text:find("o assassinato de") or text:find("was not justified") or text:find("o assassinato do")then
		storage.battleTracking[1] = not os and now + (pzTime * 60 * 1000) or os.time() + (pzTime * 60)
		return
	end
	if not text:find("due to your") and not text:find("you deal") then return end
	local spectators = getSpecs or getSpectators;
	for _, spec in ipairs(spectators()) do
		local specName = spec:getName():lower()
		if spec:isPlayer() and text:find(specName) then
			storage.battleTracking[3][specName] = {timeBattle = not os and now + 60000 or os.time() + 60, playerId = spec:getId()}
			break
		end
	end
end)

math.mod = math.mod or function(base, modulus)
	return base % modulus
end

local function doFormatMin(v)
    v = v > 1000 and v / 1000 or v
    local mins = 00
    if v >= 60 then
        mins = string.format("%02.f", math.floor(v / 60))
    end
    local seconds = string.format("%02.f", math.abs(math.floor(math.mod(v, 60))))
    return mins .. ":" .. seconds
end




storage.widgetPos = storage.widgetPos or {}

local pkTimeWidget = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())


pkTimeWidget.onDragEnter = function(widget, mousePos)
	if not (modules.corelib.g_keyboard.isCtrlPressed()) then
		return false
	end
	widget:breakAnchors()
	widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
	return true
end

pkTimeWidget.onDragMove = function(widget, mousePos, moved)
	local parentRect = widget:getParent():getRect()
	local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
	local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())        
	widget:move(x, y)
	storage.widgetPos["pkTimeWidget"] = {x = x, y = y}
	return true
end

local name = "pkTimeWidget"
storage.widgetPos[name] = storage.widgetPos[name] or {}
pkTimeWidget:setPosition({x = storage.widgetPos[name].x or 50, y = storage.widgetPos[name].y or 50})



if g_game.getWorldName() == "Katon" then -- FIX NTO SPLIT
	function getSpecs()
		local specs = {}
		for _, tile in pairs(g_map.getTiles(posz())) do
			local creatures = tile:getCreatures();
			if (#creatures > 0) then
				for i = 1, #creatures do
					table.insert(specs, creatures[i]);
				end
			end
		end
		return specs
	end
	function getPlayerByName(name)
		name = name:lower():trim();
		for _, spec in ipairs(getSpecs()) do
			if spec:getName():lower() == name then
				return spec
			end
		end
	end
end

pkTimeMacro = macro(1, function()
	local time = os and os.time() or now
	if isInPz() then storage.battleTracking[1] = 0 end
	for specName, value in pairs(storage.battleTracking[3]) do
		if (os and value.timeBattle >= time) or (not os and value.timeBattle >= time and value.timeBattle - 60000 <= time) then
			local playerSearch = getPlayerByName(specName, true)
			if playerSearch then
				if playerSearch:getId() == value.playerId then
					if playerSearch:getHealthPercent() == 0 then
						storage.battleTracking[1] = not os and time + (pzTime * 60 * 1000) or time + (pzTime * 60)
						storage.battleTracking[3][specName] = nil
					end
				else
					storage.battleTracking[3][specName] = nil
				end
			end
		else
			storage.battleTracking[3][specName] = nil
		end
	end
	local timeWidget = pkTimeWidget
	if storage.battleTracking[1] < time then
		timeWidget:setText("PK Time is: 00:00")
		timeWidget:setColor("green")
	else
		timeWidget:setText("PK Time is: " .. doFormatMin(storage.battleTracking[1] - time))
		timeWidget:setColor("red")
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------
local toFollow = "nick" -- nome do jogador 
local toFollowPos = {nick}

local followMacro = macro(200, "follow target", function()
  local target = getCreatureByName(toFollow)
  if target then
    local tpos = target:getPosition()
    toFollowPos[tpos.z] = tpos
  end
  if player:isWalking() then return end
  local p = toFollowPos[posz()]
  if not p then return end
  if autoWalk(p, 20, {ignoreNonPathable=true, precision=1}) then
    delay(100)
  end
end)

onCreaturePositionChange(function(creature, oldPos, newPos)
  if creature:getName() == toFollow then
    toFollowPos[newPos.z] = newPos
  end
end)

addIcon("followMacro", {item =12953, text = "FollowATK"}, followMacro )


----------------------------------------------FIM - MACROS DE WALK----------------------------------------------------
TH = macro(100, "Esconder SpellName", function() end, rightPanel)
onStaticText(function(thing, text)
    if TH.isOff() then return end
    if not text:find('says:') then
        g_map.cleanTexts()
    end
end, rightPanel)

-----------------------------------------------------------------------------------------------------------------------
macro(1, 'virar target', function()
 if not g_game.isAttacking() then return end
 local tt = g_game.getAttackingCreature()
 local tx = tt:getPosition().x
 local ty = tt:getPosition().y
 local dir = player:getDirection()
 local tdx = math.abs(tx-pos().x)
 local tdy = math.abs(ty-pos().y)
 if (tdy >= 2 and tdx >= 2) or tdx > 7 or tdy > 7 then return end 
 if tdy >= tdx then
  if ty > pos().y then
   if dir ~= 2 then
    return turn(2)
   end
  else
   if dir ~= 0 then
    return turn(0)
   end
  end
 else
  if tx > pos().x then
   if dir ~= 1 then
    return turn(1)
   end
  else
   if dir ~= 3 then
    return turn(3)
   end
  end
 end
end)

----------------------------------------------------------------------------------------------------------

UI.Label('ID BIJUU:', leftPanel):setFont('cipsoftFont')

addTextEdit("outfitBijuu", storage.outfitBijuu or "302", function(widget, text)
	storage.outfitBijuu = tonumber(text)
end, leftPanel)

UI.Separator()

--[[Combos Bijuus]]--

local bijuuCombos = {
  [158] = function() -- Ichibi
      say("Bijuu Sabaku Kyu")
      say("Bijuu Sabaku Taisou")
      say("Bijuu Shudan")
  end,
  [161] = function() -- Nibi
      say("Bijuu Katon Ryuka")
      say("Bijuu Katon Endan")
      say("Bijuu Katon no Jutsu")
  end,
  [303] = function() -- Sanbi
      say("Bijuu Suigadan")
      say("Bijuu Goshokuzame")
      say("Bijuu Suisahan")
  end,
  [269] = function() -- Yonbi
      say("Bijuu Yokai Furie")
      say("Bijuu Yokai Youton")
      say("Bijuu Youton Shaku Karyu")
  end,
  [162] = function() -- Gobi
      say("Bijuu Yuugeton Koogeki")
      say("Bijuu Chinbou")
      say("Bijuu Suihei")
  end,
  [301] = function() -- Rokubi
      say("Bijuu Doku Chiri")
      say("Bijuu Suiton Homatsu")
  end,
  [302] = function() -- Nanabi
      say("Bijuu Fuujin")
      say("Bijuu Doton Kouka")
  end,
  [268] = function() -- Hachibi
      say("Bijuu Chikara")
      say("Bijuu Yoroi Sokudo")
      say("Bijuu Shokushu")
  end,
  [531] = function() -- Kyuubi
      say("Bijuu Dai Panchi")
      say("Bijuu Renzoku Dama")
      say("Bijuu Chakura Tenso")
  end
}

macro(200, "Combo Bijuu", function()
  if not g_game.isAttacking() then return end

  local player = g_game.getLocalPlayer()
  local outfitType = player:getOutfit().type
  local comboFunction = bijuuCombos[outfitType]

  if comboFunction then
      comboFunction()
  end
end, rightPanel)

-----------------------------------------------------------------------------------------------------------
local cIcon = addIcon("cI",{text="Cave\nBot",switchable=false,moveable=true}, function()
if CaveBot.isOff() then 
  CaveBot.setOn()
else 
  CaveBot.setOff()
end
end)
cIcon:setSize({height=30,width=50})
cIcon.text:setFont('verdana-11px-rounded')

local tIcon = addIcon("tI",{text="Target\nBot",switchable=false,moveable=true}, function()
if TargetBot.isOff() then 
  TargetBot.setOn()
else 
  TargetBot.setOff()
end
end)
tIcon:setSize({height=30,width=50})
tIcon.text:setFont('verdana-11px-rounded')

macro(50,function()
if CaveBot.isOn() then
  cIcon.text:setColoredText({"CaveBot\n","white","ON","green"})
else
  cIcon.text:setColoredText({"CaveBot\n","white","OFF","red"})
end
if TargetBot.isOn() then
  tIcon.text:setColoredText({"Target\n","white","ON","green"})
else
  tIcon.text:setColoredText({"Target\n","white","OFF","red"})
end
end)

-------------------------------------------------------------------------------------------
macro(100, "MACRO DE % ATTACK", function()   if g_game.isAttacking() and g_game.getAttackingCreature():isPlayer() and g_game.getAttackingCreature():getHealthPercent() < 85 then
        say("rinbo hengoku")
    end 
end)




