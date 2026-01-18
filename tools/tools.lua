function msgs(category, msg) 
  contentsPanel = modules.game_bot.botWindow.contentsPanel
  botMessages = contentsPanel.messages 
  local widget = g_ui.createWidget('BotLabel', botMessages)
  widget.added = modules.game_bot.g_clock.millis()
  if category == 'erro' then
    widget:setText(msg)
    widget:setColor("red")
    widget:setFont("verdana-11px-rounded")
    modules.game_bot.g_logger.error("[LUCKEZ]: " .. msg)
  elseif category == 'aviso' then
    widget:setText(msg)        
    widget:setColor("orange")
    widget:setFont("verdana-11px-rounded")
    modules.game_bot.g_logger.warning("[LUCKEZ]: " .. msg)
  elseif category == 'lm' then
    widget:setText(msg)
    widget:setFont("verdana-11px-rounded")      
    widget:setColor("green")
    modules.game_bot.g_logger.info("[LUCKEZ]: " .. msg)
  elseif category == 'infos' then
    widget:setText(msg)
    widget:setFont("verdana-11px-rounded")      
    widget:setColor("white")
    modules.game_bot.g_logger.info("[LUCKEZ]: " .. msg)
  end

  if botMessages:getChildCount() > 5 then
    botMessages:getFirstChild():destroy()
  end
end


lm = function(text) return msgs("lm", tostring(text)) end
aviso = function(text) return msgs("aviso", tostring(text)) end
erro = function(text) return msgs("erro", tostring(text)) end
infos = function(text) return msgs("infos", tostring(text)) end

local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;

if not g_resources.directoryExists("/bot/" .. configName .. "/Storage/") then
  modules.game_bot.g_resources.makeDir("/bot/" .. configName .. "/Storage/")
end

local customStorage = "/bot/" .. configName .. "/Storage/" .. name() .. ".json";

luckezArm = {}

if g_resources.fileExists(customStorage) then
  local status, result = pcall(function()
        return json.decode(modules.game_bot.g_resources.readFileContents(customStorage))
      end)
  if not status then
    return print("Erro carregando arquivo (" ..
    customStorage ..
        "). Para consertar o problema, exclua .json do seu personagem na pasta Armazenamento. Detalhes: " .. result)
  end
  luckezArm = result
end

function salvar()
  local configFile = customStorage;

  local status, result = pcall(function()
        return json.encode(luckezArm, 2)
      end);

  if not status then
    return print("Erro salvando configuracao. Detalhes: " .. result);
  end

  if result:len() > 100 * 1024 * 1024 then
    return print("Arquivo de configuracao acima de 100MB, nao sera salvo.");
  end

  modules.game_bot.g_resources.writeFileContents(customStorage, result);
end


function moveUI(WIDGET, UI)
  if WIDGET.movable ~= false then
    WIDGET.onDragEnter = function(widget, mousePos)
      if not modules.corelib.g_keyboard.isCtrlPressed() then
        return false
      end
      widget:breakAnchors()
      widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
      return true
    end
  
  --------------------------------------------------
  
    WIDGET.onDragMove = function(widget, mousePos, moved)
      local parentRect = widget:getParent():getRect()
      local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x),
              parentRect.x + parentRect.width - widget:getWidth())
      local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(),
              mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
      widget:move(x, y)
      return true
    end
  
    WIDGET.onDragLeave = function(widget, pos)
      luckezArm[UI].X = widget:getX();
      luckezArm[UI].Y = widget:getY();
  
      salvar()
      return true
    end
  end
end

local iconsWithoutPosition = 0

addIcone = function(id, options, callback)
local panel = modules.game_interface.gameMapPanel
if type(id) ~= "string" or id:len() < 1 then
  return erro("Invalid id for addIcon")
end
if options.switchable == false and type(callback) ~= 'function' then
  return erro("Invalid callback for addIcon")
end
if type(luckezArm._icons) ~= "table" then
  luckezArm._icons = {}
end
if type(luckezArm._icons[id]) ~= "table" then
  luckezArm._icons[id] = {}
end
local config = luckezArm._icons[id]
local widget = g_ui.createWidget("BotIcon", panel)
widget.botWidget = true
widget.botIcon = true

if type(config.x) ~= 'number' and type(config.y) ~= 'number' then
  if type(options.x) == 'number' and type(options.y) == 'number' then
    config.x = math.min(1.0, math.max(0.0, options.x))
    config.y = math.min(1.0, math.max(0.0, options.y))
  else
    config.x = 0.01 + math.floor(iconsWithoutPosition / 5) / 10
    config.y = 0.05 + (iconsWithoutPosition % 5) / 5
    iconsWithoutPosition = iconsWithoutPosition + 1
  end
end

if options.item then
  if type(options.item) == 'number' then
    widget.item:setImageSource("/bot/CloretoTibia/img/cloretoicon")
  else
    widget.item:setItemId(options.item.id)
    widget.item:setItemCount(options.item.count or 1)
    widget.item:setShowCount(false)
  end
end

if options.outfit then
  widget.creature:setOutfit(options.outfit)
end

if options.switchable == false then
  widget.status:hide()
  widget.status:setOn(true)
else
  if config.enabled ~= true then
    config.enabled = false
  end
  widget.status:setOn(config.enabled)
  salvar()
end

if options.text then
  if options.switchable ~= false then
    widget.status:hide()
    if widget.status:isOn() then
      widget.text:setColor('green')
    else
      widget.text:setColor('gray')
    end
  end
  widget.text:setText(options.text)
  widget.text:setMarginBottom("-10")
  widget.text:setFont("verdana-11px-rounded")
  salvar()
end

widget.setOn = function(val)
  widget.status:setOn(val)
  if widget.status:isOn() then
    widget.text:setColor('green')
  else
    widget.text:setColor('gray')
  end
  config.enabled = widget.status:isOn()
  salvar()
end

widget.onClick = function(widget)
  if options.switchable ~= false then
    widget.setOn(not widget.status:isOn())
    if type(callback) == 'table' then
      callback.setOn(config.enabled)
      return
    end
  end

  callback(widget, widget.status:isOn())
  salvar()
end

if options.hotkey then
  widget.hotkey:setText(options.hotkey)
  widget.hotkey:setSize("0 15")
  widget.hotkey:setFont("verdana-11px-rounded")
  widget.hotkey:setColor("orange")
  hotkey(options.hotkey, "", function()
    widget:onClick()
  end, nil, options.switchable ~= false)
else
  widget.hotkey:hide()
end

if options.movable ~= false then
  widget.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then
      return false
    end
    widget:breakAnchors()
    widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
    return true
  end


  widget.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x),
            parentRect.x + parentRect.width - widget:getWidth())
    local y = math.min(
            math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y),
            parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    return true
  end

  widget.onDragLeave = function(widget, pos)
    local parent = widget:getParent()
    local parentRect = parent:getRect()
    local x = widget:getX() - parentRect.x
    local y = widget:getY() - parentRect.y
    local width = parentRect.width - widget:getWidth()
    local height = parentRect.height - widget:getHeight()

    config.x = math.min(1, math.max(0, x / width))
    config.y = math.min(1, math.max(0, y / height))

    widget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    widget:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    widget:setMarginTop(math.max(height * ( -0.5) - parent:getMarginTop(), height * ( -0.5 + config.y)))
    widget:setMarginLeft(width * ( -0.5 + config.x))
    salvar()
    return true
  end
end

widget.onGeometryChange = function(widget)
  if widget:isDragging() then return end
  local parent = widget:getParent()
  local parentRect = parent:getRect()
  local width = parentRect.width - widget:getWidth()
  local height = parentRect.height - widget:getHeight()
  widget:setMarginTop(math.max(height * ( -0.5) - parent:getMarginTop(), height * ( -0.5 + config.y)))
  widget:setMarginLeft(width * ( -0.5 + config.x))
  salvar()
end

if options.phantom ~= true then
  widget.onMouseRelease = function()
    return true
  end
end

if options.switchable ~= false then
  if type(callback) == 'table' then
    callback.setOn(config.enabled)
    callback.icon = widget
  else
    callback(widget, widget.status:isOn())
  end
end
return widget
end

macro(100, "MACRO DE % ATTACK", function()   if g_game.isAttacking() and g_game.getAttackingCreature():isPlayer() and g_game.getAttackingCreature():getHealthPercent() < 85 then
        say("rinbo hengoku")
    end 
end)
