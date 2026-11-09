-- Shared hyperlink parsing and deferred character-item metadata loading.
-- Counts are recorded immediately, even while the client's item cache is cold.
local pendingItems = {};
local refreshQueued = false;

function UberInventory_GetLinkID(link)
    if ( type(link) ~= "string" ) then return nil; end;
    -- Match the hyperlink payload, independently of its color-code prefix.
    return link:match("|Hitem:(%d+)") or link:match("^item:(%d+)")
        or link:match("|Hbattlepet:(%d+)") or link:match("^battlepet:(%d+)");
end;

function UberInventory_PreserveItemMetadata(record, previous)
    if ( record.name ) then return; end;
    previous = previous or {};
    record.name = previous.name or UBI_ITEM_UNCACHED;
    record.quality = previous.quality or 0;
    record.level = previous.level or 0;
    record.type = previous.type or UBI_ITEM_UNCACHED;
    record.subtype = previous.subtype or UBI_ITEM_UNCACHED;
    -- Pet species IDs are not item IDs and must not be sent to C_Item.
    if ( record.type == UBI_BATTLEPET_CLASS ) then return; end;
    local itemID = record.itemid;
    if ( itemID and not pendingItems[itemID] ) then
        pendingItems[itemID] = true;
        C_Item.RequestLoadItemDataByID(itemID);
    end;
end;

function UberInventory_ItemInfoReceived(itemID, success)
    if ( not pendingItems[itemID] ) then return; end;
    -- Clear before GetItemInfo: the client can dispatch cache events synchronously.
    -- A failed request can be retried by the next scan without losing counts.
    pendingItems[itemID] = nil;
    if ( not success or not UBI_Items ) then return; end;
    local record = UBI_Items[tostring(itemID)];
    if ( not record or record.type == UBI_BATTLEPET_CLASS ) then return; end;
    local name, _, quality, level, _, itemType, subtype = C_Item.GetItemInfo(itemID);
    if ( not name ) then return; end;
    record.name = name;
    record.quality = quality;
    record.level = level;
    record.type = itemType;
    record.subtype = subtype;
    UBI_SCAN_DATE = time();
    if ( not refreshQueued ) then
        refreshQueued = true;
        -- Coalesce cache events and let an in-progress inventory scan finish.
        C_Timer.After(0, function()
            refreshQueued = false;
            if ( UberInventoryFrame:IsVisible() ) then UberInventory_DisplayItems(); end;
        end);
    end;
end;
