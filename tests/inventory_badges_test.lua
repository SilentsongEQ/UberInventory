-- Exercise production scanners/filtering/rendering, with copy-sensitive WoW API mocks.
local noop = function() end;
strfind, strlower, tsort, tinsert = string.find, string.lower, table.sort, table.insert;
function wipe(t) for key in pairs(t) do t[key] = nil; end; end;
function time() return 1234; end;
function strsplit(separator, text)
    local parts = {};
    for part in (text..separator):gmatch("(.-)"..separator) do parts[#parts+1] = part; end;
    return table.unpack(parts);
end;
UBI_PLAYER, UBI_REALM, UBI_GUILD = "Main", "Realm", "Guild";
UBI_BATTLEPET_CLASS, UBI_ITEM_UNCACHED = "Pets", "Unknown";
UBI_ACTIVE, UBI_BANK_OPEN, UBI_GUILDBANK_OPENED, UBI_MAILBOX_OPEN = true, true, true, true;
UBI_Items, UBI_Accountbank = {}, {Items={}};
UBI_Guildbank = {Guild={Items={}}};
UBI_Options = {track_gb_data=true};
UBI_Data = {Realm={Main={Items=UBI_Items}, Alt={Items={}}}};
UBI_Characters, UBI_Guildbanks = {"Alt-Realm"}, {"Guild"};
UBI_FILTER_LOCATIONS_PLAYER, UBI_FILTER_LOCATIONS = 4, 4;
UBI_FILTER_QUALITY, UBI_FILTER_CLASSES, UBI_FILTER_SUBCLASSES = 1, 1, 0;
UBI_FILTER_USABLE, UBI_FILTER_TEXT = false, "";
UBI_Sorted, UBI_Track, UBI_Items_Work, UBI_Filter = {}, {}, {}, {};
UBI_LocationList = {[1]={type="complete"}, [2]={type="account_bank"},
    [4]={type="current"}, [5]={type="current"}, [6]={type="current"},
    [7]={type="current"}, [8]={type="current"}, [9]={type="character",value="Alt-Realm [80]"},
    [10]={type="guildbank",value="Guild"}, [11]={type="all_character"},
    [12]={type="all_guildbank"}};
local timers, requests, refreshes = {}, {}, 0;
C_Timer = {After=function(_, fn) timers[#timers+1]=fn; end};
UberInventoryFrame = {IsVisible=function() return true; end};
UberInventory_DisplayItems = function() refreshes=refreshes+1; end;
local function flush()
    local queued=timers; timers={};
    for _, fn in ipairs(queued) do fn(); end;
end;
local apiCalls=0;
local loaded=true;
local function info(link)
    apiCalls=apiCalls+1;
    if not loaded then return; end;
    if type(link)=="number" then link="item:"..link..":1"; end;
    local equip="INVTYPE_HEAD";
    if link:find("item:200:",1,true) then equip=""; end;
    if link:find("item:201:",1,true) then equip="INVTYPE_BAG"; end;
    return "Gear", link, 2, 1, 1, "Armor", "Cloth", 1, equip, 1, 0, 4, 1, 2;
end;
C_Item = {GetItemInfo=info, GetDetailedItemLevelInfo=function(link)
    apiCalls=apiCalls+1;
    if loaded then return tonumber(link:match("item:%d+:(%d+)")); end;
end, IsBound=function(location) return location.bound; end,
    RequestLoadItemDataByID=function(id) requests[id]=(requests[id] or 0)+1; end,
    GetItemIconByID=function() return 1; end};
Enum = {ItemBind={OnEquip=2}, BankType={Character=1,Account=2},
    BagIndex={AccountBankTab_1=13,AccountBankTab_5=13}};
local bagSlots = {
    [1]={link="|cnIQ2:|Hitem:100:145|h[Gear]|h|r", bound=false},
    [2]={link="|cffffffff|Hitem:100:150|h[Gear]|h|r", bound=true}};
ItemLocation = {CreateFromBagAndSlot=function(_,bag,slot) return bagSlots[slot]; end,
    CreateFromEquipmentSlot=function() return {bound=true}; end};
C_Container = {GetContainerItemLink=function(_,slot) return bagSlots[slot] and bagSlots[slot].link; end,
    GetContainerItemQuestInfo=noop, GetContainerItemInfo=function() return {stackCount=1}; end,
    GetContainerNumSlots=function() return #bagSlots; end,
    GetContainerNumFreeSlots=function() return 0; end};
GetInventoryItemLink=function() return "item:100:160"; end;
GetInboxItemLink=function() return "item:100:140"; end;
GetInboxItem=function() return "Gear",100,1,1; end;
dofile("UberInventory_items.lua");
local setName="Raid";
C_EquipmentSet={GetEquipmentSetIDs=function() return setName and {1} or {}; end,
    GetEquipmentSetInfo=function() return setName; end,
    GetItemIDs=function() return {[1]=100,[2]=0,[3]=-1}; end};
UberInventory_Badges_SaveSets();
UberInventory_Item(0,1,"bag"); UberInventory_Item(0,2,"bag");
UberInventory_Item(nil,1,"equip");
local record=UBI_Items["100"];
assert(record.badges.version==1 and record.total==3);
local bags=record.badges.locations.bag;
assert(bags.count==2 and bags.minLevel==145 and bags.maxLevel==150);
assert(bags.boeCount==1 and bags.complete);

local function widget(name)
    local obj={name=name,shown=true,width=240,text="",attributes={}};
    function obj:GetName() return self.name; end;
    function obj:SetText(value) self.text=value; end;
    function obj:GetWidth() return self.width; end;
    function obj:SetWidth(value) self.width=value; end;
    function obj:GetStringWidth() return #self.text*7; end;
    function obj:Show() self.shown=true; end;
    function obj:Hide() self.shown=false; end;
    function obj:SetTextColor() end;
    function obj:SetFormattedText(format,...) self.text=format:format(...); end;
    function obj:SetAttribute(key,value) self.attributes[key]=value; end;
    function obj:GetAttribute(key) return self.attributes[key]; end;
    function obj:GetNormalTexture() end;
    function obj:UnlockHighlight() end;
    function obj:LockHighlight() end;
    return obj;
end;
local entry=widget("Row");
local button=widget("RowItemButton"); _G.RowItemButton=button;
for _, suffix in ipairs({"ItemName","ItemCount","ItemBuy","ItemSell","ItemBadges"}) do
    _G[button.name..suffix]=widget(button.name..suffix);
end;
local label=_G.RowItemButtonItemBadges;
local count=_G.RowItemButtonItemCount;
UberInventory_InventoryItem_OnLeave, UberInventory_UpdateCashField = noop, noop;
UberInventory_MarkButton = noop;
UberInventory_GetItemPrices=function() return 0,0,0; end;
SetItemButtonTexture,SetItemButtonCount,SetItemButtonTextureVertexColor=noop,noop,noop;
UBI_ITEM_COUNT_SINGLE="Total: %d";
ITEM_QUALITY_COLORS={[2]={r=1,g=1,b=1}};
local tooltip={lines={}};
function tooltip:AddLine(text) self.lines[#self.lines+1]=text; end;
function tooltip:AddDoubleLine(left, right)
    self.header={left,right};
    self.lines[#self.lines+1]=left.."\t"..right;
end;
local function view(location)
    UBI_FILTER_LOCATIONS=location;
    UberInventory_SortFilter("",false);
    tooltip.lines={};
    UberInventory_Badges_Tooltip(tooltip,UBI_Sorted[1] or record);
    return table.concat(tooltip.lines,"\n");
end;
local text=view(5);
assert(tooltip.header[1]=="Item Level Status" and tooltip.header[2]=="iLvl 145–150");
assert(text:find("iLvl 145–150",1,true) and text:find("copies: 1",1,true));
assert(text:find("Main-Realm: Raid",1,true));
assert(not text:find("unknown",1,true));
UBI_BADGE_LEVEL="Level";
tooltip.lines={}; UberInventory_Badges_Tooltip(tooltip,record);
assert(table.concat(tooltip.lines,"\n"):find("Level 145–150",1,true));
UBI_BADGE_LEVEL=nil;
local callsBefore=apiCalls;
UberInventory_UpdateButton(entry,record);
assert(label.text=="· iLvl 145–150 · BoE · Set" and label.shown);
assert(apiCalls==callsBefore, "binding rows must not query item or set APIs");
-- Reserve the count even when there is no space left for badges.
count.text=string.rep("9",40);
UberInventory_Badges_Render(button,record);
assert(not label.shown and count.width==240);
count.text="Total: 3";
_G.RowItemButtonItemName.width=210;
UberInventory_Badges_Render(button,record);
assert(label.shown and label.width==210-count.width-8);
_G.RowItemButtonItemName.width=240;
text=view(8);
assert(text:find("iLvl 160",1,true) and not text:find("copies:",1,true));
assert(record.total==3, "badge filtering must not change item totals");
text=view(4); assert(text:find("iLvl 145–160",1,true));

-- Replacing one location removes its old copies and preserves unopened storage.
UberInventory_Item(0,1,"bank");
local bank=UBI_Items["100"].badges.locations.bank;
UberInventory_ResetCount("bag");
assert(not UBI_Items["100"].badges.locations.bag and UBI_Items["100"].badges.locations.bank==bank);
bagSlots[1].link="item:100:170";
UberInventory_Item(0,1,"bag");
record=UBI_Items["100"];
assert(record.badges.locations.bag.minLevel==170 and record.badges.locations.bag.maxLevel==170);
assert(record.badges.locations.bag.boeCount==1);
setName="Dungeon"; UberInventory_OnEvent(nil,"EQUIPMENT_SETS_CHANGED");
text=view(5);
assert(text:find("Dungeon",1,true) and not text:find(": Raid",1,true));
setName=nil; UberInventory_OnEvent(nil,"EQUIPMENT_SETS_CHANGED");
text=view(5); assert(not text:find("membership",1,true));

-- Character snapshots must never bleed into shared banks or another character.
local alt={itemid=100,name="Gear",type="Armor",quality=2,bag_count=1,bank_count=0,mailbox_count=0,equip_count=0};
UberInventory_Badges_Observe(alt,nil,"bag","item:100:180",1,0,2);
UBI_Data.Realm.Alt.Items["100"]=alt;
UBI_Data.Realm.Alt.badgeEquipmentSets={version=1,items={[100]={Healing=true}}};
text=view(9);
assert(text:find("iLvl 180",1,true) and text:find("Alt-Realm: Healing",1,true));
assert(not text:find("previously scanned",1,true) and not text:find("Main-Realm",1,true));
text=view(11);
assert(text:find("iLvl 145–180",1,true) and text:find("Alt-Realm: Healing",1,true));
text=view(1);
assert(text:find("iLvl 145–180",1,true));

-- Mail supports link-specific levels but cannot confirm an unbound copy.
UberInventory_Item(1,1,"mailbox");
text=view(7);
assert(text:find("iLvl 140",1,true) and text:find("unknown",1,true));
assert(not text:find("copies:",1,true));
UBI_BANK_OPEN=false;
text=view(6); assert(text:find("iLvl 145",1,true) and not text:find("previously scanned",1,true));
UBI_BANK_OPEN=true;
view(6);
UBI_BANK_OPEN=false; tooltip.lines={};
UberInventory_Badges_Tooltip(tooltip,record);
assert(not table.concat(tooltip.lines,"\n"):find("previously scanned",1,true),
    "closing storage must not add a stale-data message");
UBI_BANK_OPEN=true;

-- Exercise both shared-bank scanners with old/new hyperlink prefixes and copies.
C_Bank={CanViewBank=function() return true; end, FetchDepositedMoney=function() return 0; end};
UberInventory_Save_AccountBank();
local account=UBI_Accountbank.Items["100"];
assert(account.count==2 and account.badges.locations.account.minLevel==150);
assert(account.badges.locations.account.maxLevel==170 and account.badges.locations.account.boeCount==1);
text=view(2); assert(not text:find("Healing",1,true));
UberInventory_GetGuildbanks=noop;
C_GuildBank={GetNumGuildBankTabs=function() return 1; end,
    GetGuildBankTabInfo=function() return "Tab",1,true; end,
    GetGuildBankItemInfo=function(_,slot) return {count=slot<=2 and 1 or 0}; end,
    GetGuildBankItemLink=function(_,slot) return bagSlots[slot] and bagSlots[slot].link; end,
    GetGuildBankMoney=function() return 0; end};
MAX_GUILDBANK_SLOTS_PER_TAB=2;
UberInventory_Save_Guildbank();
local guild=UBI_Guildbank.Guild.Items["100"];
assert(guild.count==2 and guild.badges.locations.guild.minLevel==150);
assert(guild.badges.locations.guild.boeCount==0 and not guild.badges.locations.guild.complete);
text=view(10); assert(not text:find("Healing",1,true) and text:find("unknown",1,true));
text=view(12); assert(text:find("iLvl 150–170",1,true));

loaded=false;
UberInventory_Save_AccountBank();
assert(UBI_Accountbank.Items["100"].name==UBI_ITEM_UNCACHED);
assert(UBI_Accountbank.Items["100"].count==2);
loaded=true;
UberInventory_OnEvent(nil,"ITEM_DATA_LOAD_RESULT",100,true); flush();
text=view(2);
assert(UBI_Accountbank.Items["100"].name=="Gear" and #UBI_Sorted==1);
assert(text:find("iLvl 150–170",1,true));

text=view(1);
assert(text:find("iLvl 140–180",1,true) and text:find("copies: 3",1,true));
assert(text:find("Alt-Realm: Healing",1,true));

-- Legacy, non-equipment, and pet records never borrow a previous row's badges.
view(5); UberInventory_UpdateButton(entry,UBI_Items["100"]);
local oldWidth=count.width;
UberInventory_UpdateButton(entry,{itemid=999,name="Legacy",type="Armor",quality=2,total=999999999});
assert(not label.shown and label.text=="" and count.width==240 and oldWidth<240);
UberInventory_UpdateButton(entry,nil);
assert(not label.shown and label.text=="" and not entry.shown);
local pet={itemid=100,name="Pet",type=UBI_BATTLEPET_CLASS};
UberInventory_Badges_Observe(pet,nil,"bag","battlepet:100:1:2",1,0,1);
assert(pet.badges==nil);
UberInventory_Badges_Render(button,pet);
tooltip.lines={}; UberInventory_Badges_Tooltip(tooltip,pet);
assert(not label.shown and #tooltip.lines==0, "species IDs may collide with gear item IDs");
for _, id in ipairs({200,201}) do
    local item={itemid=id,type="Misc"};
    UberInventory_Badges_Observe(item,nil,"bag","item:"..id..":80",1,0,2);
    assert(item.badges.locations.bag.minLevel==nil);
end;

-- Unknown cache data resolves using the original variant link, not the base ID.
loaded=false;
UberInventory_ResetCount("bag");
bagSlots[1].link="item:100:190";
UberInventory_Item(0,1,"bag");
assert(requests[100]>0, "uncached item observations must request metadata");
assert(not UBI_Items["100"].badges.locations.bag.complete);
loaded=true;
UberInventory_OnEvent(nil,"ITEM_DATA_LOAD_RESULT",100,true);
flush();
text=view(5); assert(text:find("iLvl 190",1,true) and not text:find("unknown",1,true));
local queued=#timers;
UberInventory_OnEvent(nil,"GET_ITEM_INFO_RECEIVED",100,true);
assert(#timers==queued, "duplicate cache events must not schedule badge work");
loaded=false;
UberInventory_ResetCount("bag"); UberInventory_Item(0,1,"bag");
UberInventory_OnEvent(nil,"ITEM_DATA_LOAD_RESULT",100,false);
assert(not UBI_Items["100"].badges.locations.bag.complete);
local before=requests[100];
UberInventory_ResetCount("bag"); UberInventory_Item(0,1,"bag");
assert(requests[100]>before, "a new scan retries failed badge metadata");
UberInventory_ResetCount("bag");
loaded=true;
UberInventory_OnEvent(nil,"ITEM_DATA_LOAD_RESULT",100,true); flush();
assert(not UBI_Items["100"].badges.locations.bag, "late results cannot resurrect a cleared location");

-- Inferred mail invalidates only affected location metadata in saved recipients.
local target=UBI_Data.Realm.Alt;
target.Money={mail=0}; target.Options={mail_expires={}};
target.Items["100"].mailbox_count=0;
target.Items["100"].total=1;
local altBags=target.Items["100"].badges.locations.bag;
UBI_Mail_Transfer={to="Alt",cash=0,items={["100"]=1}};
UBI_SEC_IN_DAY=86400;
UberInventory_GetDateTime=function() return {}; end;
UberInventory_Transfer();
assert(target.Items["100"].mailbox_count==1 and target.Items["100"].total==2);
assert(target.Items["100"].badges.locations.bag==altBags);
assert(not target.Items["100"].badges.locations.mailbox);
text=view(9); assert(text:find("unknown",1,true));

-- Serialized snapshots remain readable after reload without a stale-data message.
view(9);
dofile("UberInventory_badges.lua");
text=view(9);
assert(text:find("iLvl 180",1,true) and not text:find("previously scanned",1,true));
print("PASS: copy levels, binding, filters, sets, scanners, recycled rows, async metadata, mail, saved snapshots");
