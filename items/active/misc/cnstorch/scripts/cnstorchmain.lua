require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  setupWeapon()
  storage.maxLiquidLevel = config.getParameter("maximumLiquidLevel", 0.2)
  storage.onState = "on"
  storage.offState = "off"
  if storage.state == nil then
    storage.state = config.getParameter("defaultLightState", "off")
  end
end

function setupWeapon()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  if mcontroller.liquidPercentage() >= storage.maxLiquidLevel then
    if storage.state == storage.onState or not animator.animationState("flame") == "off" then
      turnOff()
    end
  else
    if storage.state == storage.offState or animator.animationState("flame") == "off" then
      turnOn()
    end
  end
end

function turnOn()
  storage.state = storage.onState
  animator.playSound("idle", -1)
  setAnimState("idle", true)
end

function turnOff()
  storage.state = storage.offState
  animator.stopAllSounds("idle")
  setAnimState(storage.offState, false)
end

function setAnimState(anim, isOn)
  animator.playSound(storage.state)
  animator.setAnimationState("flame", anim)
  animator.setAnimationState("body", anim)
  animator.setLightActive("light", isOn)
end

function uninit()
  self.weapon:uninit()
end