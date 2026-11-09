-- Copy observations are saved by storage location; display summaries are transient.
-- No item or equipment APIs are called while binding recycled inventory rows.
local VERSION = 1;
local pending = {};
local summaries, owners = {}, {};
local refreshQueued = false;
local locations = {"bag", "bank", "mailbox", "equip"};

local function Text(key, fallback)
    return _G["UBI_BADGE_"..key] or fallback;
end;

local function Refresh()
    if ( refreshQueued ) then return; end;
    refreshQueued = true;
    C_Timer.After(0, function()
        refreshQueued = false;
        if ( UberInventoryFrame and UberInventoryFrame:IsVisible() ) then
            UberInventory_DisplayItems();
        end;
    end);
end;

local function Resolve(copy, record)
    local info = {C_Item.GetItemInfo(copy.link)};
    -- Shared banks do not use the character-item cache loader. Update the
    -- observed record too, without recreating records removed by later scans.
    if ( info[1] and record ) then
        record.name, record.quality, record.level = info[1], info[3], info[4];
        record.type, record.subtype = info[6], info[7];
    end;
    if ( not info[1] or info[9] == nil or info[14] == nil ) then return false; end;
    copy.gear = info[9] ~= "" and info[9] ~= "INVTYPE_BAG" and info[9] ~= "INVTYPE_QUIVER";
    copy.boe = info[14] == (Enum and Enum.ItemBind and Enum.ItemBind.OnEquip or 2);
    if ( copy.gear and C_Item.GetDetailedItemLevelInfo ) then
        local level = C_Item.GetDetailedItemLevelInfo(copy.link);
        if ( type(level) == "number" and level > 0 ) then copy.level = level; end;
    end;
    return not copy.gear or copy.level ~= nil;
end;

local function Recount(snapshot)
    snapshot.count, snapshot.boeCount = 0, 0;
    snapshot.minLevel, snapshot.maxLevel = nil, nil;
    snapshot.complete = true;
    for _, copy in ipairs(snapshot.copies) do
        snapshot.count = snapshot.count + copy.count;
        if ( copy.level ) then
            snapshot.minLevel = math.min(snapshot.minLevel or copy.level, copy.level);
            snapshot.maxLevel = math.max(snapshot.maxLevel or copy.level, copy.level);
        end;
        if ( copy.boe and copy.bound == false ) then
            snapshot.boeCount = snapshot.boeCount + copy.count;
        end;
        if ( copy.gear == nil or (copy.gear and not copy.level)
            or copy.boe == nil or (copy.boe and copy.bound == nil) ) then
            snapshot.complete = false;
        end;
    end;
end;

function UberInventory_Badges_Reset(record, location)
    if ( record.badges and record.badges.version == VERSION ) then
        record.badges.locations[location] = nil;
    end;
end;

function UberInventory_Badges_Observe(record, previous, location, link, count, bag, slot)
    if ( record.type == UBI_BATTLEPET_CLASS or not link or link:find("battlepet:", 1, true) ) then return; end;
    local metadata = previous and previous.badges or record.badges;
    if ( not metadata or metadata.version ~= VERSION ) then
        metadata = {version = VERSION, locations = {}};
    end;
    record.badges = metadata;
    local snapshot = metadata.locations[location];
    if ( not snapshot ) then
        snapshot = {copies = {}, scannedAt = time()};
        metadata.locations[location] = snapshot;
    end;
    local copy = {link = link, count = count or 1};
    -- Mail and guild-bank links have no supported ItemLocation binding query.
    local itemLocation;
    if ( ItemLocation and C_Item.IsBound ) then
        if ( location == "equip" ) then
            itemLocation = ItemLocation:CreateFromEquipmentSlot(slot);
        elseif ( location == "bag" or location == "bank" or location == "account" ) then
            itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot);
        end;
    end;
    if ( itemLocation ) then
        copy.bound = C_Item.IsBound(itemLocation);
    end;
    snapshot.copies[#snapshot.copies + 1] = copy;
    local resolved = Resolve(copy, record);
    if ( not record.name ) then
        record.name = previous and previous.name or UBI_ITEM_UNCACHED;
        record.quality = previous and previous.quality or 0;
        record.type = previous and previous.type or UBI_ITEM_UNCACHED;
        record.subtype = previous and previous.subtype or UBI_ITEM_UNCACHED;
    end;
    Recount(snapshot);
    if ( not resolved and C_Item.GetDetailedItemLevelInfo and C_Item.RequestLoadItemDataByID ) then
        local id = record.itemid;
        local request = pending[id];
        if ( not request ) then request = {}; pending[id] = request; end;
        request[#request + 1] = {copy = copy, snapshot = snapshot, record = record};
        -- Register before requesting: cached items can dispatch events immediately.
        if ( #request == 1 ) then C_Item.RequestLoadItemDataByID(id); end;
    end;
end;

function UberInventory_Badges_ItemInfoReceived(id, success)
    local request = pending[id];
    if ( not request ) then return; end;
    pending[id] = nil;
    if ( not success ) then return; end;
    for _, entry in ipairs(request) do
        Resolve(entry.copy, entry.record);
        Recount(entry.snapshot);
    end;
    Refresh();
end;

function UberInventory_Badges_SaveSets()
    local character = UBI_Data and UBI_Data[UBI_REALM] and UBI_Data[UBI_REALM][UBI_PLAYER];
    if ( not character or not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs ) then return; end;
    local snapshot = {version = VERSION, items = {}};
    for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local name = C_EquipmentSet.GetEquipmentSetInfo(id);
        local items = C_EquipmentSet.GetItemIDs(id);
        if ( not name or not items ) then return; end; -- Keep the last complete snapshot.
        for _, itemID in pairs(items) do
            if ( itemID > 0 ) then
                local names = snapshot.items[itemID] or {};
                names[name] = true;
                snapshot.items[itemID] = names;
            end;
        end;
    end;
    character.badgeEquipmentSets = snapshot;
end;

function UberInventory_Badges_Begin()
    summaries, owners = {}, {};
    for realm, characters in pairs(UBI_Data or {}) do
        for player, character in pairs(characters) do
            if ( player ~= "Guildbank" and type(character) == "table" and character.Items ) then
                owners[character.Items] = {character = character, name = player.."-"..realm};
            end;
        end;
    end;
end;

function UberInventory_Badges_Merge(record, items, cmdline)
    if ( record.type == UBI_BATTLEPET_CLASS ) then return; end;
    local summary = summaries[record.itemid];
    if ( not summary ) then
        summary = {boeCount = 0, sets = {}, seen = {}};
        summaries[record.itemid] = summary;
    end;
    if ( summary.seen[record] ) then return; end;
    summary.seen[record] = true;
    local owner = owners[items];
    local selected;
    if ( not cmdline ) then
        selected = locations[UBI_FILTER_LOCATIONS - UBI_FILTER_LOCATIONS_PLAYER];
        -- These indexes only select individual locations for the current character.
        if ( not UBI_LocationList or UBI_LocationList[UBI_FILTER_LOCATIONS].type ~= "current" ) then selected = nil; end;
    end;
    local metadata = record.badges;
    local contributed = false;
    local function MergeLocation(location, count)
        if ( count <= 0 ) then return; end;
        contributed = true;
        local snapshot = metadata and metadata.version == VERSION and metadata.locations[location];
        if ( not snapshot ) then summary.incomplete = true; return; end;
        if ( snapshot.minLevel ) then
            summary.minLevel = math.min(summary.minLevel or snapshot.minLevel, snapshot.minLevel);
            summary.maxLevel = math.max(summary.maxLevel or snapshot.maxLevel, snapshot.maxLevel);
        end;
        summary.boeCount = summary.boeCount + snapshot.boeCount;
        if ( not snapshot.complete or snapshot.count ~= count ) then summary.incomplete = true; end;
    end;
    if ( record.bag_count ~= nil ) then
        for _, location in ipairs(locations) do
            if ( not selected or selected == location ) then MergeLocation(location, record[location.."_count"] or 0); end;
        end;
    else
        local location = items == (UBI_Accountbank and UBI_Accountbank.Items) and "account" or "guild";
        MergeLocation(location, record.count or record.total or 0);
    end;
    if ( owner and contributed ) then
        local sets = owner.character.badgeEquipmentSets;
        if ( sets and sets.version == VERSION ) then
            for name in pairs(sets.items[record.itemid] or {}) do
                summary.sets[owner.name..": "..name] = true;
            end;
        else
            summary.incomplete = true;
        end;
    end;
end;

local function Parts(summary)
    local parts = {};
    if ( summary.minLevel ) then
        local level = tostring(summary.minLevel);
        if ( summary.maxLevel ~= summary.minLevel ) then level = level.."–"..summary.maxLevel; end;
        parts[#parts + 1] = Text("LEVEL", "iLvl").." "..level;
    end;
    if ( summary.boeCount > 0 ) then parts[#parts + 1] = Text("BOE", "BoE"); end;
    if ( next(summary.sets) ) then parts[#parts + 1] = Text("SET", "Set"); end;
    return parts;
end;

function UberInventory_Badges_Render(button, record)
    local name = button:GetName();
    local badge = _G[name.."ItemBadges"];
    if ( not badge ) then return; end;
    badge:SetText("");
    badge:Hide();
    local count = _G[name.."ItemCount"];
    local available = _G[name.."ItemName"]:GetWidth();
    count:SetWidth(available);
    if ( not record or record.type == UBI_BATTLEPET_CLASS ) then return; end;
    local summary = summaries[record.itemid];
    if ( not summary ) then return; end;
    local text = table.concat(Parts(summary), " · ");
    if ( text == "" ) then return; end;
    local countWidth = math.min(available, math.ceil(count:GetStringWidth()));
    count:SetWidth(countWidth);
    local badgeWidth = available - countWidth - 8;
    -- Zero-width FontStrings autosize in WoW; hide instead of overflowing.
    if ( badgeWidth <= 0 ) then return; end;
    badge:SetWidth(badgeWidth);
    badge:SetText("· "..text);
    badge:Show();
end;

function UberInventory_Badges_Tooltip(tooltip, record)
    if ( record.type == UBI_BATTLEPET_CLASS ) then return; end;
    local summary = summaries[record.itemid];
    if ( not summary ) then return; end;
    local parts = Parts(summary);
    if ( #parts == 0 and not summary.incomplete ) then return; end;
    tooltip:AddLine(" ");
    tooltip:AddDoubleLine(Text("TITLE", "Item Level Status"),
        summary.minLevel and parts[1] or "", 0.2, 1, 1, 0.2, 1, 1);
    if ( summary.boeCount > 0 ) then
        tooltip:AddLine(Text("BOE_HELP", "Confirmed unbound bind-on-equip copies: %d"):format(summary.boeCount), 1, 1, 1, true);
    end;
    if ( next(summary.sets) ) then
        tooltip:AddLine(Text("SET_HELP", "Equipment-set membership is by item ID, not a particular copy."), 0.8, 0.8, 0.8, true);
        local names = {};
        for name in pairs(summary.sets) do names[#names + 1] = name; end;
        table.sort(names);
        for _, name in ipairs(names) do tooltip:AddLine(name, 1, 1, 1, true); end;
    end;
    if ( summary.incomplete ) then
        tooltip:AddLine(Text("INCOMPLETE", "Some copy details are unknown. Visit the storage or log into its character to refresh."), 1, 0.82, 0, true);
    end;
end;

function UberInventory_Badges_InvalidateMail(record, previous)
    record.badges = previous and previous.badges or nil;
    UberInventory_Badges_Reset(record, "mailbox");
    local source = UBI_Items and UBI_Items[tostring(record.itemid)];
    if ( source ) then
        UberInventory_Badges_Reset(source, "bag");
        UberInventory_Badges_Reset(source, "mailbox");
    end;
end;
