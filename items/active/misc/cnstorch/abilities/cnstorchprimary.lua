-- Melee primary ability
CnsTorchPrimary = WeaponAbility:new()

function CnsTorchPrimary:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.energyUsage = self.energyUsage or 0

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self:cooldownTime()
  animator.setAnimationState("flame", "off")
  animator.setAnimationState("body", "off")
  animator.setLightActive("light", false)

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function CnsTorchPrimary:update(dt, fireMode, shiftHeld)
  if animator.animationState("flame") == "off" then
    self.weapon:setStance(self.stances.idle)
    return
  end
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
end

-- State: windup
function CnsTorchPrimary:windup()
  if animator.animationState("flame") == "off" then
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
function CnsTorchPrimary:preslash()
  if animator.animationState("flame") == "off" then
    self.weapon:setStance(self.stances.idle)
    return
  end
  self.weapon:setStance(self.stances.preslash)
  self.weapon:updateAim()

  util.wait(self.stances.preslash.duration)

  self:setState(self.fire)
end

-- State: fire
function CnsTorchPrimary:fire()
  activeItem.setScriptedAnimationParameter("isInPlaceMode", false)
  if animator.animationState("flame") == "off" then
    self.weapon:setStance(self.stances.idle)
    return
  end
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "fire")
  animator.playSound(self.fireSound or "fire")
  animator.burstParticleEmitter((self.elementalType or self.weapon.elementalType) .. "swoosh")

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self:cooldownTime()
end

function CnsTorchPrimary:cooldownTime()
  return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function CnsTorchPrimary:uninit()
  self.weapon:setDamage()
end
