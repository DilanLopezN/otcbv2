ConfigName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local configFiles = g_resources.listDirectoryFiles("/bot/" .. ConfigName .. "/scripts", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadMainScript(name)
  return dofile("/scripts/" .. name .. ".lua")
end

local function loadScripts(name)
  return dofile("/scripts/" .. name .. ".lua")
end

local luaMainFiles = {
  "main",
  "playerlist",
  "home",
  "user",
  "htks",
  "cavebot"
  
}

schedule(100, function()
  for i, file in ipairs(luaMainFiles) do
    loadMainScript(file)
  end
end)
