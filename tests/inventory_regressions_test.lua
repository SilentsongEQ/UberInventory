-- Executed by run-tests.cjs against the real production functions.
strfind, strlower, tsort, tinsert = string.find, string.lower, table.sort, table.insert;
local noop = function() end;
local actualGetLink = UberInventory_GetLink;
function wipe(t) for key in pairs(t) do t[key] = nil; end; end;
function strsplit(separator, text)
    local parts = {};
    for part in (text..separator):gmatch("(.-)"..separator) do parts[#parts+1] = part; end;
    return table.unpack(parts);
end;
local requests, timers, refreshes = {}, {}, 0;
local cached = {};
function time() return 1000; end;
UBI_ITEM_UNCACHED = "Uncached";
UBI_BATTLEPET_CLASS = "Battle Pets";
UberInventoryFrame = { IsVisible = function() return true; end; };
UberInventory_DisplayItems = function() refreshes = refreshes + 1; end;
C_Timer = { After = function(_, callback) timers[#timers+1] = callback; end; };
C_Item = {
    GetItemInfo = function(id)
        local key = UberInventory_GetLinkID(id) or tostring(id);
        if ( cached[key] ) then return "Loaded "..key, nil, 2, 70, 1, "Armor", "Cloth"; end;
    end,
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1; end,
    GetItemIconByID = function() return 1; end,
};
dofile("UberInventory_items.lua");
local function link(id) return "|cnIQ1:|Hitem:"..id..":0|h[Item]|h|r"; end;
local bagID = 123;
C_Container = {
    GetContainerItemLink = function() return link(bagID); end,
    GetContainerItemQuestInfo = noop,
    GetContainerItemInfo = function() return {stackCount=1}; end,
};
UBI_Items = { ["123"] = {itemid=123, name="Known", quality=1, level=60,
    type="Armor", subtype="Leather", bag_count=0, bank_count=20, mailbox_count=3, equip_count=0} };
UberInventory_Item(0, 1, "bag");
UberInventory_Cleanup();
local record = UBI_Items["123"];
assert(record.name == "Known" and record.quality == 1 and record.level == 60);
assert(record.total == 24 and record.bank_count == 20 and record.mailbox_count == 3);
assert(requests[123] == 1);
-- A replacement scan must not duplicate the outstanding load request.
record.bag_count = 0;
UberInventory_Item(0, 1, "bag");
assert(requests[123] == 1 and UBI_Items["123"].total == 24);
bagID = 124;
UberInventory_Item(0, 2, "bag");
UberInventory_Cleanup();
assert(UBI_Items["124"].name == UBI_ITEM_UNCACHED and UBI_Items["124"].quality == 0);
assert(UBI_Items["124"].total == 1);
cached["123"], cached["124"] = true, true;
UberInventory_OnEvent(nil, "ITEM_DATA_LOAD_RESULT", 123, true);
UberInventory_OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 124, true);
assert(UBI_Items["123"].name == "Loaded 123" and UBI_Items["123"].quality == 2);
assert(UBI_Items["123"].total == 24 and UBI_Items["124"].total == 1);
assert(#timers == 1 and refreshes == 0, "metadata refreshes must coalesce after the scan");
timers[1](); assert(refreshes == 1);
UberInventory_OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 123, true);
assert(#timers == 1, "duplicate cache events must be ignored");
bagID = 125;
UberInventory_Item(0, 3, "bag");
UberInventory_OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 125, false);
assert(UBI_Items["125"].total == 1, "failed metadata loading must preserve counts");
UBI_Items["125"].bag_count = 0;
UberInventory_Item(0, 3, "bag");
assert(requests[125] == 2, "a later scan must retry failed loads");
UBI_Items["125"] = nil;
cached["125"] = true;
UberInventory_OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 125, true);
assert(UBI_Items["125"] == nil, "late cache events must not resurrect removed items");
UBI_Items["126"] = {itemid=126, bank_count=5};
UBI_Items["127"] = {itemid=127, bag_count=0};
UberInventory_Cleanup();
assert(UBI_Items["126"] and UBI_Items["126"].name == UBI_ITEM_UNCACHED);
assert(UBI_Items["127"] == nil);
local pet = {itemid=456, type=UBI_BATTLEPET_CLASS};
UberInventory_PreserveItemMetadata(pet, pet);
assert(requests[456] == nil, "species IDs must not request item metadata");
print("PASS: cold cache, saved counts, async metadata, coalescing, retry, late events, cleanup");

for _, value in ipairs({link(123), "|cffffffff|Hitem:123:0|h[Old link]|h|r", "item:123:0"}) do
    assert(UberInventory_GetLinkID(value) == "123");
end;
assert(UberInventory_GetLinkID("|cnIQ2:|Hbattlepet:456:1:2|h[Pet]|h|r") == "456");
assert(UberInventory_GetLinkID(nil) == nil and UberInventory_GetLinkID("invalid") == nil);
UBI_Mail_Transfer, UBI_Hooks = {}, {};
ATTACHMENTS_MAX_SEND, ATTACHMENTS_MAX_RECEIVE = 3, 3;
GetSendMailMoney = function() return 10; end;
GetSendMailItem = function(i) return "Item", 123, 1, i; end;
GetSendMailItemLink = function(i) if i < 3 then return link(123); end; end;
GetInboxHeaderInfo = function() return nil, nil, "Alt", "Subject", 10; end;
GetInboxItem = function(_, i) return "Item", 123, 1, i; end;
GetInboxItemLink = function(_, i) if i < 3 then return link(123); end; end;
local sent, returned;
UBI_Hooks.SendMail = function(...) sent={...}; end;
UBI_Hooks.ReturnInboxItem = function(id) returned=id; end;
UberInventory_SendMail("Alt", "Subject", "Body");
assert(UBI_Mail_Transfer.items["123"] == 3 and UBI_Mail_Transfer.items["|Hitem"] == nil);
assert(sent[1] == "Alt" and sent[2] == "Subject" and sent[3] == "Body");
UberInventory_ReturnInboxItem(7);
assert(UBI_Mail_Transfer.items["123"] == 3 and returned == 7);
print("PASS: mail IDs, hyperlink prefixes, duplicate attachments, nil links, original hooks");

UBI_Global_Options = {Options={ignore_realm=true}};
UBI_PLAYER, UBI_REALM, UBI_Characters = "Alex", "RealmA", {};
UBI_Data = {
    RealmA={Alex={Options={player_realm="Alex-RealmA"}}, Guildbank={}},
    RealmB={Alex={Options={player_realm="Alex-RealmB"}}},
};
UberInventory_GetAlts();
assert(#UBI_Characters == 1 and UBI_Characters[1] == "Alex-RealmB");
UBI_Global_Options.Options.ignore_realm = false;
UberInventory_GetAlts(); assert(#UBI_Characters == 0);
print("PASS: same-name cross-realm alts and current-realm-only setting");

UBI_Items_Work, UBI_Sorted, UBI_Track = {}, {}, {};
UBI_FILTER_LOCATIONS, UBI_FILTER_LOCATIONS_PLAYER = 1, 1;
UBI_FILTER_QUALITY, UBI_FILTER_CLASSES, UBI_FILTER_SUBCLASSES = 1, 1, 0;
UBI_FILTER_USABLE = false;
UBI_LocationList = {{type="current"}};
local messages = {};
UberInventory_Message = function(message) messages[#messages+1] = message; end;
UberInventory_GetLink = function() return "item link"; end;
UBI_ITEM_SEARCH, UBI_ITEM_COUNT_SINGLE = "Search %s", "%d";
UBI_ITEM_SEARCH_DONE, UBI_ITEM_SEARCH_NONE = "Done", "None";
UBI_LOCATION_TEXTURE, UBI_LOCATIONS = {1,2,3,4}, {"Bag","Bank","Mail","Equipped"};
UBI_ACCOUNT_BANK_TITLE = "Account Bank";
for _, query in ipairs({"[", "%", ".", "a+b", "UPPER"}) do
    UBI_Items = {["1"]={itemid=1, name="Item "..query, total=1}};
    UBI_Accountbank = {Items={}};
    UBI_FILTER_TEXT, UBI_Filter = query, {};
    UberInventory_SortFilter(query, false);
    assert(#UBI_Sorted == 1, "search punctuation must match literally");
    UberInventory_Search(query);
    assert(messages[#messages] == UBI_ITEM_SEARCH_DONE);
    UBI_Items = {};
    UBI_Accountbank.Items = {["1"]={itemid=1, name="Bank "..query, total=1}, ["2"]={itemid=2, total=1}};
    UberInventory_Search(query);
    assert(messages[#messages] == UBI_ITEM_SEARCH_DONE, "account-bank-only search must be literal");
end;
UBI_Items = {["1"]={itemid=1,name="Ordinary",total=1}};
UBI_FILTER_TEXT, UBI_Filter = ".", {};
UberInventory_SortFilter(".", false); assert(#UBI_Sorted == 0);
print("PASS: literal inventory/slash/account-bank searches and missing names");

local function widget(name)
    return setmetatable({attributes={}}, {__index=function(obj, key)
        if key == "GetName" then return function() return name; end; end;
        if key == "SetAttribute" then return function(_, attr, value) obj.attributes[attr]=value; end; end;
        return noop;
    end});
end;
local entry, button = widget("TestEntry"), widget("TestEntryItemButton");
button.IconBorder = false;
_G.TestEntryItemButton = button;
for _, suffix in ipairs({"ItemName","ItemCount","ItemSell","ItemBuy"}) do
    _G["TestEntryItemButton"..suffix] = widget();
end;
UberInventory_InventoryItem_OnLeave, UberInventory_UpdateCashField = noop, noop;
UberInventory_GetItemPrices = function() return 0,0,0; end;
UberInventory_UsableItem = function() return false; end;
SetItemButtonTexture, SetItemButtonCount = noop, noop;
function SetItemButtonTextureVertexColor(obj,r,g,b) obj.tint={r,g,b}; end;
C_PetJournal = {GetPetInfoBySpeciesID=function() return "Pet",2; end};
ITEM_QUALITY_COLORS = {[1]={r=1,g=1,b=1}};
local ordinary = {itemid=123,name="Armor",type="Armor",quality=1,total=1};
local battlePet = {itemid=456,name="Pet",type=UBI_BATTLEPET_CLASS,quality=1,total=1};
UberInventory_UpdateButton(entry, ordinary);
assert(button.tint[2] == 0.1);
UberInventory_UpdateButton(entry, battlePet);
assert(button.tint[1] == 1 and button.tint[2] == 1 and button.tint[3] == 1);
cached["123"] = nil;
UberInventory_UpdateButton(entry, ordinary);
assert(button.tint[1] == 0.2 and button.attributes.usable == "uncached");
UberInventory_UpdateButton(entry, battlePet);
assert(button.tint[1] == 1 and button.tint[2] == 1 and button.attributes.usable == nil);
print("PASS: recycled pet tint reset after unusable and uncached items");

local tooltipCalls = 0;
UberInventory_AddItemInfo = function() tooltipCalls = tooltipCalls + 1; end;
local tooltip = {};
Process_OnTooltipSetItem(tooltip, nil);
Process_OnTooltipSetItem(tooltip, {id=UBI_ITEM_ID_WOW_TOKEN, lines={{leftText="Jeton WoW"}}});
Process_OnTooltipSetItem(tooltip, {id=UBI_ITEM_ID_WOW_TOKEN_SHOP});
assert(tooltipCalls == 0 and tooltip.UBI_InfoAdded == nil,
    "both WoW Token variants must be skipped independently of localized names");
Process_OnTooltipSetItem(tooltip, {id=123, lines={{leftText="WoW Token"}}});
assert(tooltipCalls == 1 and tooltip.UBI_InfoAdded,
    "tooltip behavior must depend on item ID, not English display text");
local petLinks = 0;
UberInventory_GetBattlePetLink = function(record) petLinks=petLinks+1; return "pet:"..record.itemid; end;
C_Item.GetItemInfo = function(id) return "Item", "item:"..id; end;
assert(actualGetLink(UBI_ITEM_ID_PET_CAGE,
    {type=UBI_BATTLEPET_CLASS,itemid=UBI_ITEM_ID_PET_CAGE}) == "item:"..UBI_ITEM_ID_PET_CAGE);
assert(petLinks == 0);
assert(actualGetLink(456, {type=UBI_BATTLEPET_CLASS,itemid=456}) == "pet:456" and petLinks == 1);
print("PASS: named item IDs, localized WoW Token filtering, and pet-cage links");
