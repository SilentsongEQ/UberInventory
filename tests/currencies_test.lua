-- Catalog checks use the production table and the actual save/display functions.
tinsert = table.insert;
local expected = {
    [-13] = {3316,2803,3028,3310,3356,3418,3405,3373,3376,3377,3379,3385,3392,3393,
        3400,3448,3546,3363,3442,3443,3444,3445,3446,3465,3383,3341,3343,3345,3347,
        3378,3256,3257,3258,3259,3260,3261,3262,3263,3264,3265,3266},
    [-12] = {2815,3056,3055,3090,3149,3218,3220,3226,3278,3303,3008,2914,2915,2916,
        2917,3107,3108,3109,3110,3284,3286,3288,3290,3089,3100},
};
local groups, entries, group = {}, {};
for _, currency in ipairs(UBI_Currencies) do
    assert(not entries[currency.id], "duplicate currency ID: "..currency.id);
    entries[currency.id] = currency;
    if currency.id < 0 then group=currency.id; else groups[currency.id]=group; end;
end;
for heading, ids in pairs(expected) do
    for _, id in ipairs(ids) do assert(groups[id] == heading, "wrong/missing currency group: "..id); end;
end;
assert(not entries[3044], "Engineering Concentration is not Flame-Blessed Iron");
assert(not entries[3111] and not entries[3112], "do not retain the mismatched duplicate crest IDs");
for id=3256,3266 do assert(entries[id].force == false); end;
for _, id in ipairs({2914,3107,3284,3383,3378}) do assert(entries[id].force == false); end;

local quantities = {[3316]=123,[3257]=7};
local unavailable, unnamed = {[3448]=true}, {[3546]=true};
C_CurrencyInfo = {GetCurrencyInfo=function(id)
    assert(id>0, "headers must never query the currency API");
    if unavailable[id] then return nil; end;
    return {name=unnamed[id] and "" or (id==1822 and "Renown" or "Currency "..id),
        iconFileID=id, quantity=quantities[id] or 0};
end};
UBI_Money = {Currencies={[3448]=99}};
UBI_ACTIVE = false;
UberInventory_Save_Currencies(); assert(UBI_Money.Currencies[3316] == nil);
UBI_ACTIVE = true;
UberInventory_Save_Currencies();
assert(UBI_Money.Currencies[3316] == 123 and UBI_Money.Currencies[3257] == 7);
assert(UBI_Money.Currencies[3448] == 99, "unavailable metadata must not erase a stored balance");
assert(entries[3448].available == false and entries[3546].available == false);
assert(UBI_Money.Currencies[1822] == 1, "preserve existing Renown behavior");
local function widget()
    return {
        SetText=function(self,text) self.text=text; end,
        SetTextColor=function() end, SetTexture=function() end,
        Show=function(self) self.shown=true; end,
        Hide=function(self) self.shown=false; end,
    };
end;
UBI_NUM_TOKENBUTTONS = 500;
for slot=1,UBI_NUM_TOKENBUTTONS do
    _G["Token"..slot]=widget();
    for _, suffix in ipairs({"Name","Count","Icon"}) do _G["Token"..slot..suffix]=widget(); end;
end;
UBI_PLAYER, UBI_REALM = "Alex", "RealmA";
UBI_Data = {
    RealmA={Alex={Money=UBI_Money}},
    RealmB={Alex={Money={Currencies={[3256]=10}}}},
};
UBI_FILTER_LOCATIONS = 1;
UBI_LocationList = {{type="current"},{type="character",value="Alex-RealmB [90]"}};
UBI_TOKEN = "Tokens (%s)";
UberInventoryTokens, UberInventoryTokensHeading = widget(), widget();
UberInventoryTokensScroll = {offset=0, SetVerticalScroll=function(self,pixels) self.offset=math.floor(pixels/17+0.5); end};
UberInventoryTokensScrollScrollBar = {SetValue=function(_,pixels) UberInventoryTokensScroll.offset=math.floor(pixels/17+0.5); end};
function FauxScrollFrame_GetOffset(frame) return frame.offset; end;
function FauxScrollFrame_SetOffset(frame,offset) frame.offset=offset; end;
function FauxScrollFrame_Update(frame,length) frame.updatedLength=length; end;
local function visibleText(text)
    for slot=1,UBI_NUM_TOKENBUTTONS do
        if _G["Token"..slot].shown and _G["Token"..slot.."Name"].text==text then return slot; end;
    end;
end;
UberInventory_DisplayTokens();
assert(_G.Token1Name.text == "Midnight");
assert(visibleText("The War Within"));
assert(visibleText("   Currency 3316"));
assert(visibleText("   Currency 3257") and not visibleText("   Currency 3256"));
assert(not visibleText("   Currency 3448") and not visibleText("   "));
assert(UberInventoryTokensScroll.updatedLength == UberInventoryTokensScroll.itemCount);
UBI_FILTER_LOCATIONS=2;
UberInventory_DisplayTokens();
local slot=visibleText("   Currency 3256");
assert(slot and _G["Token"..slot.."Count"].text==10, "optional rows must use the selected alt's balance");
assert(not visibleText("   Currency 3257"));

UBI_FILTER_LOCATIONS, UBI_NUM_TOKENBUTTONS = 1,20;
UberInventory_DisplayTokens();
local frame=UberInventoryTokensScroll;
UberInventory_OnMouseWheel(frame,-1000,"TOKENS");
assert(frame.offset == frame.itemCount-UBI_NUM_TOKENBUTTONS);
assert(_G.Token20.shown, "bottom must not include an extra blank page");
for _, entry in ipairs(UBI_Currencies) do if entry.id>0 then entry.available=false; end; end;
UberInventory_DisplayTokens();
assert(frame.offset==0 and frame.itemCount<UBI_NUM_TOKENBUTTONS, "clamp after visible rows shrink");
UberInventory_OnMouseWheel(frame,-1000,"TOKENS"); assert(frame.offset==0);
unavailable[3448],unnamed[3546] = nil,nil;
quantities[3448] = 3;
UberInventory_Save_Currencies();
assert(entries[3448].available and UBI_Money.Currencies[3448] == 3);
print("PASS: currency IDs, expansion groups, nil metadata, optional/alt rows, token scroll bounds");
