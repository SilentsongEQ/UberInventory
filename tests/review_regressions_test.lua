-- Exercise production functions with storage and tooltip contexts from the review.
strfind, strlower = string.find, string.lower;
function wipe(t) for k in pairs(t) do t[k] = nil; end; end;
function strsplit() return nil, nil, "100"; end;
local function item(id, name, count)
    return {itemid=id, name=name, quality=1, type="Trade Goods", level=1,
        bag_count=count, bank_count=0, mailbox_count=0, equip_count=0, total=count};
end;
UBI_BATTLEPET_CLASS, UBI_ITEM_UNCACHED = "Pets", "Uncached";
UBI_PLAYER = "Main";
C_CYAN, C_WHITE, C_YELLOW, C_CLOSE, C_BLUE = "", "", "", "", "";
UBI_SIGMA_ICON = "SUM";
UBI_Options = {show_tooltip=true, show_item_count=true};
UBI_Global_Options = {Options={}};
UBI_LOCATION_TEXTURE = {1,2,3,4,5,6,7};
UBI_LOCATIONS = {"bags","bank","mail","equip"};
UBI_FILTER_LOCATIONS = 2;
UBI_LocationList = {{name="All", type="complete"},
    {name="  Alt-Realm [80]", type="character"}};
UBI_Items = {["100"]=item(100, "Ore", 2)};
UBI_Data = {
    Realm={Alt={Options={}, Items={["100"]=item(100, "Ore", 3)}}},
    Other={Alt={Options={}, Items={["100"]=item(100, "Ore", 4)}}},
};
UBI_Characters = {"Alt-Realm", "Alt-Other"};
UBI_Guildbanks = {};
UBI_Accountbank = {Items={}};
UBI_TooltipItem = UBI_Data.Realm.Alt.Items["100"];
UBI_TooltipLocation = 2;
TooltipUtil = {GetDisplayedItem=function() return "Ore", "|Hitem:100|h[Ore]|h"; end};
C_Item = {GetItemInfo=function() return "Ore"; end};
MerchantFrame = {IsVisible=function() return false; end};
UberInventory_AddRecipeSources = function() end;
local tooltip = {lines={}};
function tooltip:AddDoubleLine(a,b) self.lines[#self.lines+1]={a,b}; end;
function tooltip:AddLine(a) self.lines[#self.lines+1]={a}; end;
function tooltip:AddTexture() end;
function tooltip:NumLines() return #self.lines; end;
UberInventory_AddItemInfo(tooltip);
assert(tooltip.lines[#tooltip.lines][2]=="SUM 9", "Selected alt is counted once; same-name alt on another realm remains included");
UBI_TooltipLocation, UBI_FILTER_LOCATIONS = 1, 1;
tooltip.lines={};
UberInventory_AddItemInfo(tooltip);
assert(tooltip.lines[#tooltip.lines][2]=="SUM 9", "Combined view includes each character once");
UBI_TooltipItem, UBI_TooltipLocation = nil, nil;
tooltip.lines={};
UberInventory_AddItemInfo(tooltip);
assert(tooltip.lines[#tooltip.lines][2]=="SUM 9", "Ordinary item tooltip includes each character once");

UBI_ITEM_SEARCH, UBI_ITEM_COUNT_SINGLE = "%s", "%d";
UBI_ITEM_SEARCH_DONE, UBI_ITEM_SEARCH_NONE = "Done", "None";
UBI_ACCOUNT_BANK_TITLE = "Account";
C_Item.GetItemIconByID = function() return 1; end;
UberInventory_GetLink = function(id, record) return record.name.."#"..id; end;
local messages={};
UberInventory_Message = function(s) messages[#messages+1]=s; end;
UBI_Accountbank.Items = {
    ["100"]=item(100, "Ore", 5),
    ["101"]=item(101, "Ore Bank Only", 4),
    ["102"]=item(102, "Ore", 6), -- Same name, different item ID.
};
UberInventory_Search("Ore");
local output=table.concat(messages,"\n");
assert(output:find("Ore#100 7",1,true), "Shared ID combines character and bank counts");
assert(output:find("Ore Bank Only#101 4",1,true), "Bank-only matches appear alongside character matches");
assert(output:find("Ore#102 6",1,true), "Same-name items remain separate by ID");
assert(#messages==5, "Each matching ID appears exactly once, plus search heading/footer");

local cached, requests, timers = {}, {}, {};
C_Item.GetItemInfo = function(id)
    if cached[tostring(id)] then return "Loaded "..id, nil, 2, 70, 1, "Armor", "Cloth"; end;
end;
C_Item.RequestLoadItemDataByID = function(id) requests[id]=(requests[id] or 0)+1; end;
C_Timer = {After=function(_, callback) timers[#timers+1]=callback; end};
function time() return 1000; end;
UberInventoryFrame = {IsVisible=function() return false; end};
dofile("UberInventory_items.lua");
UBI_ACTIVE, UBI_BANK_OPEN = true, true;
Enum = {BankType={Account=2}, BagIndex={AccountBankTab_1=13, AccountBankTab_5=13}};
C_Bank = {CanViewBank=function() return true; end, FetchDepositedMoney=function() return 0; end};
local ids={100,100,101};
C_Container = {
    GetContainerNumSlots=function() return #ids; end,
    GetContainerNumFreeSlots=function() return 0; end,
    GetContainerItemLink=function(_, slot) return "|Hitem:"..ids[slot].."|h[Ore]|h"; end,
    GetContainerItemInfo=function() return {stackCount=2}; end,
};
UberInventory_Badges_Observe = function() end;
UBI_Accountbank.Items = {["100"]=item(100, "Saved Ore", 5)};
UberInventory_Save_AccountBank();
assert(UBI_Accountbank.Items["100"].name=="Saved Ore" and UBI_Accountbank.Items["100"].quality==1);
assert(UBI_Accountbank.Items["100"].total==4 and UBI_Accountbank.Items["101"].total==2);
assert(UBI_Accountbank.Items["101"].name==UBI_ITEM_UNCACHED and UBI_Accountbank.Items["101"].quality==0);
assert(requests[100]==1 and requests[101]==1, "Repeated copies coalesce metadata requests");
cached["100"], cached["101"] = true, true;
UberInventory_ItemInfoReceived(100,true);
UberInventory_ItemInfoReceived(101,true);
assert(UBI_Items["100"].name=="Loaded 100" and UBI_Accountbank.Items["100"].name=="Loaded 100");
assert(UBI_Accountbank.Items["101"].name=="Loaded 101" and UBI_Accountbank.Items["101"].total==2);
assert(#timers==1, "Character and bank updates share one UI refresh");
ids={102};
UberInventory_Save_AccountBank();
UberInventory_ItemInfoReceived(102,false);
UberInventory_Save_AccountBank();
assert(requests[102]==2, "Failed bank metadata loads retry on the next scan");
ids={};
UberInventory_Save_AccountBank();
cached["102"]=true;
UberInventory_ItemInfoReceived(102,true);
assert(UBI_Accountbank.Items["102"]==nil, "Late loads cannot restore removed bank items");
ids={103};
UberInventory_Save_AccountBank();
UBI_Items=nil;
cached["103"]=true;
UberInventory_ItemInfoReceived(103,true);
assert(UBI_Accountbank.Items["103"].name=="Loaded 103", "Bank metadata does not require a character record");
print("PASS: selected-alt totals, mixed character/bank searches, shared-bank cold cache, retries and late events");
