local useBuffTracking = true -- Если true, то использует отслеживание баффов

local function AuraCheck(value, table)
  for i = 1, #table do
    if value == table[i] then
      return true
    end
  end
end

local aurasForEnemyPlayer =
{
  -- Воин 
  132169, -- Удар Громоверца
  385060, -- Ярость Одина
  397364, -- Громогласный рык
  184364, -- Безудержное восстановление
  97462, -- Ободряющий клич
  384100, -- Крик берсерка
  23920, -- Отражение заклинаний
  132168, -- Ударная волна
  5246, -- Устрашающий крик
  -- Другие 
  --DEBUFFS
  2139, -- Антимагия
  15487, -- Безмолвие
  25771, -- Воздержанность
  147362, -- Встречный выстрел
  64044, -- Глубинный ужас
  31589, -- Замедление
  187650, -- Замораживающая ловушка
  375901, -- Игры разума
  122, -- Кольцо льда
  5116, -- Контузящий выстрел
  383121, -- Массовое превращение
  8122, -- Ментальный крик
  853, -- Молот правосудия
  2094, -- Ослепление
  6770, -- Ошеломление
  213691, -- Ошеломляющий выстрел
  1776, -- Парализующий удар
  1766, -- Пинок
  1833, -- Подлый трюк
  118, -- Превращение
  115750, -- Слепящий свет
  187698, -- Смоляная ловушка
  408, -- Удар по почкам
  96231, -- Укор
  19577, -- Устрашение
  --BUFFS
  185311, -- Алый фиал
  48707, -- Антимагический панцирь
  1022, -- Благословение защиты
  1044, -- Благословенная свобода
  403876, -- Божественная защита
  221883, -- Божественный скакун
  642, -- Божественный щит
  264735, -- Выживает сильнейший
  22812, -- Дубовая кожа
  186257, -- Дух гепарда
  186265, -- Дух черепахи
  6940, -- Жерственное благословение
  122470, -- Закон кармы
  19574, -- Звериный гнев
  45438, -- Ледяная глыба
  11426, -- Ледяная преграда
  342245, -- Манипуляции со временем
  19236, -- Молитва отчаяния
  32612, -- Невидимость
  48792, -- Незыблемость льда
  47788, -- Оберегающий дух
  781, -- Отрыв
  31224, -- Плащ теней
  33206, -- Подавление боли
  272682, -- Приказ хозяина
  53480, -- Рев жертвенности
  47585, -- Слияние с Тьмой
  17, -- Слово силы: Щит
  2983, -- Спринт
  1966, -- Уловка
  5277, -- Ускользание
  184662, -- Щит возмездия
}

local aurasForANonEnemyPlayer =
{

}

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
  local function HandleAura(aura)
    if useBuffTracking then -- Проверяет нужно ли использовать отслеживание баффов
      if UnitIsEnemy("player", self.unit) and UnitPlayerControlled(self.unit) then   -- Проверяет являеться ли unit вражеским игроком
        if AuraCheck(aura.spellId, aurasForEnemyPlayer) then   -- Проверяет находиться ли аура в таблице aurasForEnemyPlayer
          self.auras[aura.auraInstanceID] = aura
        end
      else
        if AuraCheck(aura.spellId, aurasForANonEnemyPlayer) then   -- Проверяет находиться ли аура в таблице aurasForANonEnemyPlayer
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
  AuraUtil.ForEachAura(self.unit, "HELPFUL", batchCount, HandleAura, usePackedAura)
  AuraUtil.ForEachAura(self.unit, "HARMFUL", batchCount, HandleAura, usePackedAura)
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
