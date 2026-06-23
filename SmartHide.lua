-- ============================================================
-- 							SMART HIDE
-- 			Hide your frames during combat.
-- 						https://github.com/WasabiMoe
-- ============================================================

SmartHideDB = SmartHideDB or {}

-- ============================================================
-- Frame Groups
-- Each group is a named set of global frame names to hide/show.
-- Add new groups or entries here -- no other code needs to change.
-- ============================================================

local groups = {
    {
        key = "unitframes",
        label = "Player / Target Frames",
        frames = { "PlayerFrame", "TargetFrame", "TargetFrameToT" },
    },
    {
        key = "actionbars",
        label = "Action Bars",
        frames = {
            "MainMenuBar",
            "MultiBarBottomLeft",
            "MultiBarBottomRight",
            "MultiBarRight",
            "MultiBarLeft",
        },
    },
    {
        key = "minimap",
        label = "Minimap",
        frames = { "MinimapCluster" },
    },
    {
        key = "partyframes",
        label = "Party Frames",
        frames = { "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4" },
    },
}


local function isEnabled(key)
    if SmartHideDB[key] == nil then
        return false
    end
    return SmartHideDB[key]
end

local function isInstanceOnly(key)
    return SmartHideDB[key .. "_instanceOnly"] == true
end

local function isPvpOnly(key)
    return SmartHideDB[key .. "_pvpOnly"] == true
end

local function isGlobalInstanceOnly()
    return SmartHideDB._globalInstanceOnly == true
end

local function isGlobalPvpOnly()
    return SmartHideDB._globalPvpOnly == true
end


local function isInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "party" or instanceType == "raid")
end

local function isInPvp()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp" or instanceType == "arena")
end


local function groupAppliesNow(group)
    local instanceOnly = isGlobalInstanceOnly() or isInstanceOnly(group.key)
    local pvpOnly = isGlobalPvpOnly() or isPvpOnly(group.key)

    if not instanceOnly and not pvpOnly then
        return true
    end

    if instanceOnly and isInInstance() then
        return true
    end
    if pvpOnly and isInPvp() then
        return true
    end
    return false
end

-- ============================================================
-- Core Hide / Show
-- ============================================================

local f = CreateFrame("Frame", "SmartHideEventFrame")
f:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
f:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
f:RegisterEvent("PLAYER_LOGIN")


local unitGatedFrames = {
    TargetFrame = "target",
    TargetFrameToT = "targettarget",
    PartyMemberFrame1 = "party1",
    PartyMemberFrame2 = "party2",
    PartyMemberFrame3 = "party3",
    PartyMemberFrame4 = "party4",
}

local function showFrame(frameName, frame)
    local unit = unitGatedFrames[frameName]
    if unit then
        if UnitExists(unit) then
            if frameName == "TargetFrame" and TargetFrame_Update then
                TargetFrame_Update(frame)
            elseif frameName == "TargetFrameToT" and TargetofTargetFrame_Update then
                TargetofTargetFrame_Update(frame)
            end
            frame:Show()
        else
            frame:Hide()
        end
    else
        frame:Show()
    end
end

local function applyToGroup(group, shouldShow)
    for _, frameName in ipairs(group.frames) do
        local frame = _G[frameName]
        if frame then
            if shouldShow then
                showFrame(frameName, frame)
            else
                frame:Hide()
            end
        end
    end
end

local function onEnterCombat()
    for _, group in ipairs(groups) do
        if isEnabled(group.key) and groupAppliesNow(group) then
            applyToGroup(group, false)
        end
    end
end

local function onLeaveCombat()
    for _, group in ipairs(groups) do
        if isEnabled(group.key) then
            applyToGroup(group, true)
        end
    end
end


local function reevaluateAllGroups()
    local inCombat = InCombatLockdown()
    for _, group in ipairs(groups) do
        if isEnabled(group.key) then
            if inCombat and groupAppliesNow(group) then
                applyToGroup(group, false)
            else
                applyToGroup(group, true)
            end
        end
    end
end

f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        onEnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        onLeaveCombat()
    elseif event == "PLAYER_LOGIN" then
        -- Safety net: if you reload while in combat, make sure nothing
        -- is left permanently hidden from a previous session.
        if not InCombatLockdown() then
            onLeaveCombat()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        reevaluateAllGroups()
    end
end)

-- ============================================================
-- Slash Command: /smarthide
-- ============================================================
-- Opens the options panel. All settings are managed there.

local function setGroupState(group, enabled)
    SmartHideDB[group.key] = enabled
    if not enabled and InCombatLockdown() then
        -- Safety net.
        applyToGroup(group, true)
    end
end

local function setGroupInstanceOnly(group, instanceOnly)
    SmartHideDB[group.key .. "_instanceOnly"] = instanceOnly
    reevaluateAllGroups()
end

local function setGlobalInstanceOnly(enabled)
    SmartHideDB._globalInstanceOnly = enabled
    reevaluateAllGroups()
end

local function setGroupPvpOnly(group, pvpOnly)
    SmartHideDB[group.key .. "_pvpOnly"] = pvpOnly
    reevaluateAllGroups()
end

local function setGlobalPvpOnly(enabled)
    SmartHideDB._globalPvpOnly = enabled
    reevaluateAllGroups()
end

SLASH_SMARTHIDE1 = "/smarthide"
SlashCmdList["SMARTHIDE"] = function(msg)
    if SmartHideOptionsPanel then
        InterfaceOptionsFrame_OpenToCategory(SmartHideOptionsPanel)
        InterfaceOptionsFrame_OpenToCategory(SmartHideOptionsPanel)
    end
end

-- ============================================================
-- Options Panel
-- ============================================================

local panel = CreateFrame("Frame", "SmartHideOptionsPanel", UIParent)
panel.name = "SmartHide"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("SmartHide")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetWidth(500)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Choose which UI elements SmartHide hides while you're in combat.")


local globalInstanceCB = CreateFrame("CheckButton", "SmartHideGlobalInstanceOnly", panel, "InterfaceOptionsCheckButtonTemplate")
globalInstanceCB:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
do
    local label = _G[globalInstanceCB:GetName() .. "Text"]
    if label then
        label:SetText("Only hide in Instance (applies to all groups below)")
    end
end

local globalPvpCB = CreateFrame("CheckButton", "SmartHideGlobalPvpOnly", panel, "InterfaceOptionsCheckButtonTemplate")
globalPvpCB:SetPoint("TOPLEFT", globalInstanceCB, "BOTTOMLEFT", 0, -4)
do
    local label = _G[globalPvpCB:GetName() .. "Text"]
    if label then
        label:SetText("Only hide in PvP / Arena (applies to all groups below)")
    end
end

panel.checkboxes = {}
panel.instanceCheckboxes = {}
panel.pvpCheckboxes = {}

local function refreshScopeCheckboxesEnabled()
    local globalInstanceOn = isGlobalInstanceOnly()
    local globalPvpOn = isGlobalPvpOnly()
    for _, cb in pairs(panel.instanceCheckboxes) do
        if globalInstanceOn then cb:Disable() else cb:Enable() end
    end
    for _, cb in pairs(panel.pvpCheckboxes) do
        if globalPvpOn then cb:Disable() else cb:Enable() end
    end
end

globalInstanceCB:SetScript("OnClick", function(self)
    local checked = self:GetChecked() and true or false
    setGlobalInstanceOnly(checked)
    refreshScopeCheckboxesEnabled()
end)

globalPvpCB:SetScript("OnClick", function(self)
    local checked = self:GetChecked() and true or false
    setGlobalPvpOnly(checked)
    refreshScopeCheckboxesEnabled()
end)

local function createCheckbox(group, anchorTo, index)
    local cb = CreateFrame("CheckButton", "SmartHideCheckbox_" .. group.key, panel, "InterfaceOptionsCheckButtonTemplate")
    if index == 1 then
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -28)
    else
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -44)
    end
    local label = _G[cb:GetName() .. "Text"]
    if label then
        label:SetText(group.label)
    end
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        setGroupState(group, checked)
    end)
    panel.checkboxes[group.key] = cb


    local instanceCB = CreateFrame("CheckButton", "SmartHideInstanceOnly_" .. group.key, panel, "InterfaceOptionsCheckButtonTemplate")
    instanceCB:SetScale(0.8)
    instanceCB:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, -2)
    local instanceLabel = _G[instanceCB:GetName() .. "Text"]
    if instanceLabel then
        instanceLabel:SetText("Instance only")
    end
    instanceCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        setGroupInstanceOnly(group, checked)
    end)
    panel.instanceCheckboxes[group.key] = instanceCB

    local pvpCB = CreateFrame("CheckButton", "SmartHidePvpOnly_" .. group.key, panel, "InterfaceOptionsCheckButtonTemplate")
    pvpCB:SetScale(0.8)
    pvpCB:SetPoint("TOPLEFT", instanceCB, "TOPRIGHT", 190, 0)
    local pvpLabel = _G[pvpCB:GetName() .. "Text"]
    if pvpLabel then
        pvpLabel:SetText("PvP / Arena only")
    end
    pvpCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        setGroupPvpOnly(group, checked)
    end)
    panel.pvpCheckboxes[group.key] = pvpCB

    return cb
end

local lastAnchor = globalPvpCB
for i, group in ipairs(groups) do
    lastAnchor = createCheckbox(group, lastAnchor, i)
end

function panel:RefreshCheckboxes()
    for key, cb in pairs(panel.checkboxes) do
        cb:SetChecked(isEnabled(key))
    end
    for key, cb in pairs(panel.instanceCheckboxes) do
        cb:SetChecked(isInstanceOnly(key))
    end
    for key, cb in pairs(panel.pvpCheckboxes) do
        cb:SetChecked(isPvpOnly(key))
    end
    globalInstanceCB:SetChecked(isGlobalInstanceOnly())
    globalPvpCB:SetChecked(isGlobalPvpOnly())
    refreshScopeCheckboxesEnabled()
end


function panel.refresh(self)
    -- Snapshot current saved values so cancel() has something to revert to.
    self.snapshot = { instanceOnly = {}, pvpOnly = {} }
    for _, group in ipairs(groups) do
        self.snapshot[group.key] = isEnabled(group.key)
        self.snapshot.instanceOnly[group.key] = isInstanceOnly(group.key)
        self.snapshot.pvpOnly[group.key] = isPvpOnly(group.key)
    end
    self.snapshot.globalInstance = isGlobalInstanceOnly()
    self.snapshot.globalPvp = isGlobalPvpOnly()
    self:RefreshCheckboxes()
end

function panel.okay(self)
    self.snapshot = nil
end

function panel.cancel(self)
    -- Revert to whatever was true when the panel was opened.
    if self.snapshot then
        for _, group in ipairs(groups) do
            if self.snapshot[group.key] ~= nil then
                setGroupState(group, self.snapshot[group.key])
            end
            if self.snapshot.instanceOnly[group.key] ~= nil then
                setGroupInstanceOnly(group, self.snapshot.instanceOnly[group.key])
            end
            if self.snapshot.pvpOnly[group.key] ~= nil then
                setGroupPvpOnly(group, self.snapshot.pvpOnly[group.key])
            end
        end
        if self.snapshot.globalInstance ~= nil then
            setGlobalInstanceOnly(self.snapshot.globalInstance)
        end
        if self.snapshot.globalPvp ~= nil then
            setGlobalPvpOnly(self.snapshot.globalPvp)
        end
    end
    self.snapshot = nil
    self:RefreshCheckboxes()
end

panel:SetScript("OnShow", function(self)
    self:RefreshCheckboxes()
end)

InterfaceOptions_AddCategory(panel)
