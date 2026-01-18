-- /images/ui/window
 local hpui = setupUI([[

Panel 
  image-border: 8
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.top: parent.top
  height: 50
  width: 100
  visible: true
  margin-top: 250
  margin-left: -102


  Panel
    id: PlayerPainel
    image-border: 6
    anchors.top: parent.top
    anchors.left: parent.left
    image-color: red
    size: 30 30

  Panel
    id: PlayerPainel_Name
    image-border: 8
    image-color: #d9d9d9
    padding: 1
    height: 5
    margin-top: 0
    margin-right: 0
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.left: PlayerPainel.right

    Label
      id: LIFE PERCENT
      anchors.left: PlayerPainel.right
      text: LIFE PERCENT: 
      color: green	
      font: verdana-11px-rounded
      text-horizontal-auto-resize: true
      margin-left: 30
      margin-top: 10

    UIWidget
      id: skullUI
      height: 1
      size: 43 43
      anchors.left: PlayerPainel_Name.right
      anchors.right: parent.right
      image-border: 5

  Panel
    id: HPprogressPanel
    image-border: -10
    image-color: #BEBEBE
    padding: 0
    height: 20
    margin-top: 12
    margin-right: -10
    anchors.top: PlayerPainel_Name.bottom
    anchors.left: PlayerPainel.right
    anchors.right: parent.right
  
    ProgressBar
      id: Hppercent
      background-color: green
      height: 16
      anchors.left: parent.left
      text: 100%
      width: 240
      margin-right: 0

]], modules.game_interface.gameMapPanel)


local skull = {
  normal = "",
  white = "/images/game/skulls/skull_white",
  yellow = "/images/game/skulls/skull_yellow",
  green = "/images/game/skulls/skull_green",
  orange = "/images/game/skulls/skull_orange",
  red = "/images/game/skulls/skull_red",
  black = "/images/game/skulls/skull_black"
}


macro(50, function()
  hpui:show()

   local PlayerHP = player:getHealthPercent()
   hpui.HPprogressPanel.Hppercent:setText(PlayerHP.."%")
   hpui.HPprogressPanel.Hppercent:setPercent(PlayerHP)

  if PlayerHP > 75 then
    hpui.HPprogressPanel.Hppercent:setBackgroundColor("green")
   elseif PlayerHP > 50 then
    hpui.HPprogressPanel.Hppercent:setBackgroundColor("yellow")
   elseif PlayerHP > 25 then
    hpui.HPprogressPanel.Hppercent:setBackgroundColor("orange")
   elseif PlayerHP > 1 then
    hpui.HPprogressPanel.Hppercent:setBackgroundColor("red")
  end
  

 end)


