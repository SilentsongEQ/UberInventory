-- Inventory-only scrolling. Data refreshes stay in UberInventory_DisplayItems;
-- animation and scrollbar input only move/rebind this bounded row pool.
local scroll;
local hoveredItem;
local Render, Layout;

function UberInventory_InventoryItem_OnLeave(button)
    if ( hoveredItem ~= button ) then return; end;
    hoveredItem = nil;
    UberInventory_Highlighter(nil, "off");
    UBI_TooltipItem = nil;
    UBI_TooltipLocation = nil;
    GameTooltip:Hide();
    BattlePetTooltip:Hide();
    if ( not UBI_FILTER_TEXT or UBI_FILTER_TEXT == "" ) then
        button:UnlockHighlight();
    end;
end;

function UberInventory_InventoryItem_OnEnter(button)
    local record = button:GetAttribute("inventoryitem");
    if ( not record or not scroll or not scroll:IsMouseOver() ) then return; end;
    if ( hoveredItem == button ) then return; end;
    if ( hoveredItem ) then UberInventory_InventoryItem_OnLeave(hoveredItem); end;
    hoveredItem = button;
    UBI_TooltipItem = record;
    UBI_TooltipLocation = button:GetAttribute("location");
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
    if ( record.type == UBI_BATTLEPET_CLASS and record.itemid ~= UBI_ITEM_ID_PET_CAGE ) then
        local extra = record.extra or {};
        BattlePetToolTip_Show(record.itemid, record.level, record.quality,
            extra[1] or 0, extra[2] or 0, extra[3] or 0, record.name);
    else
        GameTooltip:SetHyperlink(UberInventory_GetLink(record.itemid, record));
        UberInventory_Badges_Tooltip(GameTooltip, record);
        GameTooltip:Show();
    end;
    UberInventory_Highlighter(record.itemid, "on");
end;

local function ClearHover()
    if ( hoveredItem ) then UberInventory_InventoryItem_OnLeave(hoveredItem); end;
end;

local function UpdateHover()
    if ( not scroll:IsVisible() or not scroll:IsMouseOver() ) then
        ClearHover();
        return;
    end;
    for _, entry in ipairs(scroll.entries) do
        local button = entry.button;
        if ( entry:IsShown() and button:IsMouseOver() ) then
            UberInventory_InventoryItem_OnEnter(button);
            return;
        end;
    end;
    ClearHover();
end;

local function Clamp(value)
    return math.max(0, math.min(scroll.maxOffset, value));
end;

local function Snap(value)
    return math.floor(value / scroll.pixel + 0.5) * scroll.pixel;
end;

local function Stop()
    scroll:SetScript("OnUpdate", nil);
    scroll.target = scroll.current;
end;

Render = function(force)
    -- The range is pixel aligned as well, so both ends remain reachable.
    local offset = Clamp(Snap(scroll.current));
    local firstRow = math.floor(offset / scroll.pitch);
    if ( force or firstRow ~= scroll.firstRow ) then
        ClearHover();
        scroll.firstRow = firstRow;
        for slot, entry in ipairs(scroll.entries) do
            local row = firstRow + math.floor((slot - 1) / 2);
            local column = (slot - 1) % 2;
            entry:ClearAllPoints();
            entry:SetPoint("TOPLEFT", scroll.content, "TOPLEFT",
                column * scroll.columnPitch, -row * scroll.pitch);
            local record = slot <= scroll.poolSize and UBI_Sorted[row * 2 + column + 1] or nil;
            UberInventory_UpdateButton(entry, record);
        end;
        -- Flush native cached bounds after pooled frames move or rebind.
        scroll:UpdateScrollChildRect();
    end;
    scroll:SetVerticalScroll(offset);
    -- SetValue invokes OnValueChanged synchronously. Never let the sync below
    -- cancel an animation, or recursively render the viewport.
    scroll.syncing = true;
    scroll.bar:SetValue(offset);
    scroll.syncing = false;
    UpdateHover();
end;

function UberInventory_InventoryScroll_SetOffset(value)
    if ( not scroll ) then return; end;
    Stop();
    scroll.current = Clamp(value);
    scroll.target = scroll.current;
    Render();
end;

function UberInventory_InventoryScroll_Wheel(delta)
    if ( not scroll or scroll.maxOffset == 0 or delta == 0 ) then return; end;
    scroll.target = Clamp(scroll.target - delta * scroll.pitch);
    scroll.start = scroll.current;
    scroll.elapsed = 0;
    if ( scroll.target == scroll.current ) then Stop(); return; end;
    scroll:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = math.min(0.12, self.elapsed + elapsed);
        local t = self.elapsed / 0.12;
        self.current = self.start + (self.target - self.start) * (1 - (1 - t)^3);
        Render();
        if ( t >= 1 ) then Stop(); end;
    end);
end;

Layout = function()
    ClearHover();
    Stop();
    scroll.pixel = PixelUtil.GetPixelToUIUnitFactor() / scroll:GetEffectiveScale();
    local width, height = Snap(280), Snap(36);
    scroll.pitch = height + Snap(8);
    scroll.columnPitch = width + Snap(15);
    scroll:SetSize(width + scroll.columnPitch, Snap(346));
    scroll:ClearAllPoints();
    -- Align the absolute viewport origin, including a fractionally positioned
    -- parent, rather than only rounding its local anchor offsets.
    local parent = scroll:GetParent();
    -- The black list background is a sibling, not the viewport's parent.
    -- Order the entire scroll subtree above it explicitly: a ScrollFrame's
    -- composited content must not rely on sibling creation order.
    local border = UberInventoryFrameBorder;
    local baseLevel = math.max(parent:GetFrameLevel(), border:GetFrameLevel()) + 1;
    local strata = parent:GetFrameStrata();
    scroll:SetFrameStrata(strata);
    scroll:SetFrameLevel(baseLevel);
    scroll.content:SetFrameStrata(strata);
    scroll.content:SetFrameLevel(baseLevel + 1);
    scroll.bar:SetFrameStrata(strata);
    scroll.bar:SetFrameLevel(baseLevel + 1);
    scroll.up:SetFrameStrata(strata);
    scroll.up:SetFrameLevel(baseLevel + 1);
    scroll.down:SetFrameStrata(strata);
    scroll.down:SetFrameLevel(baseLevel + 1);
    local left, top = parent:GetLeft(), parent:GetTop();
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT",
        left and Snap(left + 25) - left or Snap(25),
        top and Snap(top - 100) - top or -Snap(100));
    scroll.bar:SetSize(Snap(16), scroll:GetHeight() - 2 * Snap(16));
    scroll.bar:ClearAllPoints();
    scroll.bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", Snap(5), -Snap(16));
    scroll.up:SetSize(Snap(16), Snap(16));
    scroll.down:SetSize(Snap(16), Snap(16));
    local poolSize = (math.ceil(scroll:GetHeight() / scroll.pitch) + 1) * 2;
    for slot = 1, poolSize do
        local entry = scroll.entries[slot];
        if ( not entry ) then
            entry = CreateFrame("Frame", "UberInventoryFrameItem"..slot,
                scroll.content, "ItemButton_Template");
            entry.button = _G[entry:GetName().."ItemButton"];
            entry.button:EnableMouseWheel(true);
            entry.button:SetScript("OnMouseWheel", function(_, delta)
                UberInventory_InventoryScroll_Wheel(delta);
            end);
            scroll.entries[slot] = entry;
        end;
        entry:SetSize(width, height);
        entry:SetFrameStrata(strata);
        entry:SetFrameLevel(baseLevel + 2);
        entry.button:SetFrameStrata(strata);
        entry.button:SetFrameLevel(baseLevel + 3);
        entry.button:SetSize(height, height);
        local textWidth = width - height - Snap(5);
        _G[entry.button:GetName().."ItemName"]:SetWidth(textWidth);
        _G[entry.button:GetName().."ItemCount"]:SetWidth(textWidth);
        PixelUtil.SetRoundLayoutToNearestPixelRecursively(entry, true);
    end;
    -- The pool is normally 18 frames. Hide surplus entries if scale rounding
    -- ever changes the required count; never allocate per inventory item.
    scroll.poolSize = poolSize;
    local rows = math.ceil(#UBI_Sorted / 2);
    local contentHeight = rows == 0 and 0 or rows * scroll.pitch - Snap(8);
    scroll.content:SetSize(scroll:GetWidth(), math.max(scroll:GetHeight(), contentHeight));
    scroll.maxOffset = math.max(0, contentHeight - scroll:GetHeight());
    scroll.syncing = true;
    scroll.bar:SetMinMaxValues(0, scroll.maxOffset);
    scroll.bar:SetValueStep(scroll.pixel);
    scroll.bar:SetObeyStepOnDrag(false);
    scroll.bar:SetShown(scroll.maxOffset > 0);
    scroll.up:SetShown(scroll.maxOffset > 0);
    scroll.down:SetShown(scroll.maxOffset > 0);
    scroll.syncing = false;
    scroll.current = Clamp(scroll.current);
    scroll.target = scroll.current;
    Render(true);
end;

function UberInventory_InventoryScroll_Refresh()
    if ( not scroll ) then UberInventory_InventoryScroll_Init(); end;
    Layout();
end;

function UberInventory_InventoryScroll_Init()
    if ( scroll ) then return; end;
    scroll = UberInventoryFrameScroll;
    scroll.content = scroll:GetScrollChild();
    scroll.content:ClearAllPoints();
    scroll.content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0);
    scroll.bar = UberInventoryFrameScrollScrollBar;
    scroll.entries = {};
    scroll.current, scroll.target, scroll.maxOffset = 0, 0, 0;
    scroll:SetClipsChildren(true);
    scroll:EnableMouseWheel(true);
    scroll:SetScript("OnMouseWheel", function(_, delta)
        UberInventory_InventoryScroll_Wheel(delta);
    end);
    scroll.bar:SetScript("OnValueChanged", function(_, value)
        if ( not scroll.syncing ) then UberInventory_InventoryScroll_SetOffset(value); end;
    end);
    scroll.bar:SetScript("OnMouseDown", function()
        UberInventory_InventoryScroll_SetOffset(scroll.current);
    end);
    scroll.bar:EnableMouseWheel(true);
    scroll.bar:SetScript("OnMouseWheel", scroll:GetScript("OnMouseWheel"));
    local track = scroll.bar:CreateTexture(nil, "BACKGROUND");
    track:SetAllPoints();
    track:SetColorTexture(0.08, 0.08, 0.08, 0.8);
    for _, direction in ipairs({"up", "down"}) do
        local button = CreateFrame("Button", nil, scroll:GetParent(), "UIPanelButtonTemplate");
        button:SetSize(16, 16);
        button:SetText(direction == "up" and "^" or "v");
        if ( direction == "up" ) then
            button:SetPoint("BOTTOM", scroll.bar, "TOP");
            button:SetScript("OnClick", function() UberInventory_InventoryScroll_Wheel(1); end);
        else
            button:SetPoint("TOP", scroll.bar, "BOTTOM");
            button:SetScript("OnClick", function() UberInventory_InventoryScroll_Wheel(-1); end);
        end;
        scroll[direction] = button;
    end;
    scroll:HookScript("OnHide", function() Stop(); ClearHover(); end);
    scroll:HookScript("OnShow", function() Layout(); end);
    scroll:RegisterEvent("UI_SCALE_CHANGED");
    scroll:RegisterEvent("DISPLAY_SIZE_CHANGED");
    scroll:SetScript("OnEvent", function() Layout(); end);
    -- Moving the main window can change its physical pixel origin.
    scroll:GetParent():HookScript("OnDragStop", function() Layout(); end);
    scroll:GetParent():HookScript("OnMouseUp", function() Layout(); end);
    Layout();
end;
