local useBuffTracking = true -- Если true, то использует отслеживание баффов

local function AuraCheck(value, table)
  for i = 1, #table do
    if value == table[i] then
      return true
    end
  end
end

Mac_NamePlateAurasMixin = {}

function Mac_NamePlateAurasMixin:OnLoad()
  self:RegisterEvent("NAME_PLATE_CREATED")
  self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  self:RegisterEvent("UNIT_AURA")
end

function Mac_NamePlateAurasMixin:OnEvent(event, ...)
  if event == "NAME_PLATE_CREATED" then
    local nameplate = ...
    if nameplate.Mac_BuffFrame then
      --print(nameplate:GetName(), "уже создан!!!")
    else
      local frame = CreateFrame("Frame", "Mac_BuffFrame", nameplate, "Mac_BuffFrameTemplate") -- Создание Mac_BuffFrame в NamePlate
      --print(nameplate:GetName(), "создан")
    end
  end
  if event == "NAME_PLATE_UNIT_ADDED" then
    self:OnUnitAuraUpdate(...)
  end
  if event == "UNIT_AURA" then
    self:OnUnitAuraUpdate(...)
  end
end

function Mac_NamePlateAurasMixin:OnUnitAuraUpdate(unit)
  local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
  if nameplate then
    if nameplate.Mac_BuffFrame then
      nameplate.Mac_BuffFrame:UpdateBuffs(nameplate.namePlateUnitToken)
    end
  end
end

Mac_NameplateBuffContainerMixin = {}

function Mac_NameplateBuffContainerMixin:OnLoad()
  self.buffPool = CreateFramePool("Frame", self, "NameplateBuffButtonTemplate")
end

function Mac_NameplateBuffContainerMixin:ParseAllAuras() -- Создаю таблицу баффов
  if self.auras == nil then
    self.auras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable)
  else
    self.auras:Clear()
  end
  local function ForEachAura(filter)
    local auraFilterForEnemyPlayers
    local auraFilterForNonEnemyPlayers
    if filter == "HELPFUL" then
      auraFilterForEnemyPlayers = Mac_auraFilterForEnemyPlayers.buffs
      auraFilterForNonEnemyPlayers = Mac_auraFilterForNonEnemyPlayers.buffs
    elseif filter == "HARMFUL" then
      auraFilterForEnemyPlayers = Mac_auraFilterForEnemyPlayers.deBuffs
      auraFilterForNonEnemyPlayers = Mac_auraFilterForNonEnemyPlayers.deBuffs
    end
    local function HandleAura(aura)
      if useBuffTracking then -- Проверяет нужно ли использовать отслеживание баффов
        if UnitIsEnemy("player", self.unit) and UnitPlayerControlled(self.unit) then   -- Проверяет являеться ли unit вражеским игроком
          if AuraCheck(aura.spellId, auraFilterForEnemyPlayers) then   -- Проверяет находиться ли аура в таблице aurasForEnemyPlayer
            self.auras[aura.auraInstanceID] = aura
          end
        else
          if AuraCheck(aura.spellId, auraFilterForNonEnemyPlayers) then   -- Проверяет находиться ли аура в таблице aurasForANonEnemyPlayer
            self.auras[aura.auraInstanceID] = aura
          end
        end
      else
        self.auras[aura.auraInstanceID] = aura
      end
      return false
    end
    local batchCount = nil
    local usePackedAura = true
    AuraUtil.ForEachAura(self.unit, filter, batchCount, HandleAura, usePackedAura)
  end
  ForEachAura("HELPFUL")
  ForEachAura("HARMFUL")
end

function Mac_NameplateBuffContainerMixin:UpdateBuffs(unit)
  self.unit = unit
  self:ParseAllAuras()
  self.buffPool:ReleaseAll()
  local buffIndex = 1
  self.auras:Iterate(function(auraInstanceID, aura)
    local buff = self.buffPool:Acquire()
    buff.Icon:SetTexture(aura.icon)
    buff.auraInstanceID = auraInstanceID
    buff.layoutIndex = buffIndex
    if (aura.applications > 1) then
      buff.CountFrame.Count:SetText(aura.applications);
      buff.CountFrame.Count:Show()
    else
      buff.CountFrame.Count:Hide()
    end
    CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true)
    buff:Show()
    buffIndex = buffIndex + 1
    return buffIndex >= BUFF_MAX_DISPLAY
  end)
  self:Layout()
end