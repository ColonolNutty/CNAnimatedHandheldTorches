require "/scripts/util.lua"

-- Melee primary ability
CnsTorchSecondary = WeaponAbility:new()

function CnsTorchSecondary:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.energyUsage = self.energyUsage or 0

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self:cooldownTime()
  
  storage.isInPlaceMode = false
  self.consumeItemOnPlace = config.getParameter("consumeItemOnPlace")
  self.placeObject = config.getParameter("placeObject")
  self.placementBounds = config.getParameter("placementBounds")
  activeItem.setScriptedAnimationParameter("isInPlaceMode", false)
  activeItem.setScriptedAnimationParameter("previewImage", config.getParameter("previewImage"))
  self.aim = {0,0}
  self.visual = {0,0}
  self.aimAngle = 0.0
  self.facingDirection = 0
  animator.setAnimationState("flame", "off")
  animator.setAnimationState("body", "off")
  animator.setLightActive("light", false)

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function CnsTorchSecondary:update(dt, fireMode, shiftHeld)
  if animator.animationState("flame") == "off" then
    storage.isInPlaceMode = false
    activeItem.setScriptedAnimationParameter("isInPlaceMode", storage.isInPlaceMode)
    self.weapon:setStance(self.stances.idle)
    return
  end
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  activeItem.setScriptedAnimationParameter("isInPlaceMode", storage.isInPlaceMode)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
  
  if storage.isInPlaceMode then 
    local aimPosition = activeItem.ownerAimPosition()
    self.visual = {world.xwrap(math.floor(aimPosition[1])) + 0.5, math.floor(aimPosition[2], 0) + 1}
    self.aim = {self.visual[1], self.visual[2] - 1}
    self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(0, self.aim)
    
    activeItem.setScriptedAnimationParameter("previewPosition", self.visual)
    local isValid = world.tileIsOccupied(self.aim, false, false)
    activeItem.setScriptedAnimationParameter("previewValid", isValid)
    for i,vec in ipairs(self.placementBounds) do
      if isValid then
        checkVec = {vec[1] + self.aim[1], vec[2] + self.aim[2]}
        if world.tileIsOccupied(checkVec, true, false) then
          isValid = false
        end
      end
    end
    activeItem.setScriptedAnimationParameter("previewValid", isValid)
  end
end

-- State: windup
function CnsTorchSecondary:windup()
  if animator.animationState("flame") == "off" then
    storage.isInPlaceMode = false
    self.weapon:setStance(self.stances.idle)
    return
  end
  self.weapon:setStance(self.stances.windup)

  if self.stances.windup.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    util.wait(self.stances.windup.duration)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances.preslash then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: preslash
-- brief frame in between windup and fire
function CnsTorchSecondary:preslash()
  if animator.animationState("flame") == "off" then
    storage.isInPlaceMode = false
    self.weapon:setStance(self.stances.idle)
    return
  end
  self.weapon:setStance(self.stances.preslash)
  self.weapon:updateAim()

  util.wait(self.stances.preslash.duration)

  self:setState(self.fire)
end

-- State: fire
function CnsTorchSecondary:fire()
  if animator.animationState("flame") == "off" then
    self.weapon:setStance(self.stances.idle)
    return
  end
  self.weapon:setStance(self.stances.idle)
  self.weapon:updateAim()
  if storage.isInPlaceMode then
    if world.placeObject(self.placeObject, self.aim, self.facingDirection) then
      -- to cancel, they'll use the primary ability
      item.consume(1)
    end
  else
    if not storage.isInPlaceMode then
      storage.isInPlaceMode = true
    end
  end
end

function CnsTorchSecondary:cooldownTime()
  return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function CnsTorchSecondary:uninit()
  self.weapon:setDamage()
end

function math.round(num, idp)
	  local mult = 10^(idp or 0)
	  return math.floor(num * mult + 0.5) / mult
end
