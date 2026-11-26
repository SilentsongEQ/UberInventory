local function noop() end;
local records = 0;
for itemID, sources in pairs( UBI_RecipeSources ) do
    assert( type(itemID) == "number" and #sources > 0 );
    records = records + 1;
    for _, source in ipairs(sources) do
        assert( source.kind and not source.rate and not source.dropRate );
        if source.kind ~= "world" and source.kind ~= "other" then assert(source.id > 0); end;
    end;
end;
assert(records >= 5000 and UBI_RecipeSources[223100]);
assert(not UBI_RecipeSources[444068]); -- This is the recipe spell, not its item.

UBI_RECIPE_VENDOR_TITLE,UBI_RECIPE_QUEST_TITLE,UBI_RECIPE_OTHER_TITLE="Vendors","Quest Rewards","Other Sources";
UBI_RECIPE_WORLD_DROP,UBI_RECIPE_TREASURE,UBI_RECIPE_CONTAINER="World drop","Treasure","Container: ";
UBI_RECIPE_SOURCE,UBI_RECIPE_MAP,UBI_RECIPE_RACE,UBI_RECIPE_CLASS="Source","Map #%d","Race","Class";
UBI_RECIPE_ENCOUNTER="Encounter";
UBI_RECIPE_REPUTATION,UBI_RECIPE_PREREQUISITES="Reputation with %s: %d","Prerequisite quests: ";
UBI_RECIPE_CONDITIONAL,UBI_RECIPE_REMOVED="Additional requirements apply","Historical source (removed)";
UBI_RECIPE_UNAVAILABLE,UBI_RECIPE_RESTRICTED,UBI_RECIPE_MORE="Not currently available","Availability restrictions apply","+%d more sources";
QUESTS_LABEL,ITEMS,FACTION_HORDE,FACTION_ALLIANCE="Quests","Items","Horde","Alliance";
RETRIEVING_DATA="Retrieving data";
local ready, calls, secret = false, 0, {};
issecretvalue=function(v) return v==secret; end;
C_TooltipInfo={GetHyperlink=function(link)
    calls=calls+1;
    if link:find("%-999%-") then return {lines={{leftText=secret}}}; end;
    return {lines={{leftText=ready and "Localized Merchant" or RETRIEVING_DATA}}};
end};
C_Map={GetMapInfo=function(id) if id==84 then return {name="Localized City"}; end; end};
C_QuestLog={GetTitleForQuestID=function(id) return id==200 and "Localized Quest"; end};
C_Item={GetItemInfo=function(id) return "Localized Container"; end};
EJ_GetEncounterInfo=function(id) if id==503 then return "Localized Encounter"; end; end;
C_CreatureInfo={GetRaceInfo=function()return {raceName="Human"};end,GetClassInfo=function()return {className="Mage"};end};
C_Reputation={GetFactionDataByID=function()return {name="Stormwind"};end};
UBI_RecipeObjectNames={[300]="Ancient Chest"}; UBI_RecipeQuestNames={};
UBI_Options={show_recipe_prices=true,show_recipe_reward=true,show_recipe_drop=true};
UBI_MAX_RECIPE_INFO=10;
UBI_RecipeSources={
    [1]={
        {kind="vendor",id=100,maps={84,85},faction=2,races={1},classes={8},reputation={72,42000},quests={700},conditional=true},
        {kind="vendor",id=101,status="removed"},
        {kind="quest",id=200},
        {kind="world"},
        {kind="object",id=300},
        {kind="container",id=400},
        {kind="drop",id=999},
        {kind="encounter",id=503},
    }
};
local tooltip={lines={}};
function tooltip:AddLine(text) self.lines[#self.lines+1]=text; end;
function tooltip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left.." | "..right; end;
local function shown(text) for _,line in ipairs(tooltip.lines) do if line:find(text,1,true) then return true; end; end; return false; end;
UberInventory_AddRecipeSources(tooltip,1);
assert(shown("NPC #100") and shown("NPC #999"));
assert(shown("Localized City, Map #85"));
assert(shown("Alliance; Human; Mage; Reputation with Stormwind: 42000; Prerequisite quests: #700"));
assert(shown("Historical source (removed)") and shown("Localized Quest"));
assert(shown("World drop") and shown("Ancient Chest") and shown("Container: Localized Container"));
assert(shown("Localized Encounter"));
assert(not shown("%"));
ready=true; tooltip.lines={};
UberInventory_AddRecipeSources(tooltip,1);
assert(shown("Localized Merchant"),'Uncached names should retry');
local before=calls; tooltip.lines={};
UberInventory_AddRecipeSources(tooltip,1);
assert(calls==before+1,'Successful names should cache; secret names should retry');
UBI_MAX_RECIPE_INFO=1; tooltip.lines={};
UberInventory_AddRecipeSources(tooltip,1);
assert(shown("+1 more sources") and not shown("Historical source"),'Prefer current sources within the display cap');
UBI_Options={}; tooltip.lines={};
UberInventory_AddRecipeSources(tooltip,1);
assert(#tooltip.lines==0);
UberInventory_AddRecipeSources(tooltip,123456789);
-- Exercise the actual inventory tooltip integration with counts disabled.
UBI_Options={show_tooltip=true,show_recipe_prices=true};
UBI_RecipeSources[1]={{kind="vendor",id=100}};
TooltipUtil={GetDisplayedItem=function()return "Recipe","item:1";end};
strsplit=function()return nil,nil,"1";end;
local merchant=false;
MerchantFrame={IsVisible=function()return merchant;end};
tooltip.Show=noop;
tooltip.NumLines=function(self)return #self.lines;end;
tooltip.lines={};
UberInventory_AddItemInfo(tooltip);
assert(shown("Localized Merchant"));
merchant=true; tooltip.lines={};
UberInventory_AddItemInfo(tooltip);
assert(#tooltip.lines==0,'Merchant tooltips retain their existing source suppression');
ItemRefTooltip=tooltip;
UberInventory_AddItemInfo(tooltip);
assert(shown("Localized Merchant"),'Linked-item tooltips still show sources at merchants');
print('PASS: generated recipe integrity, localized source names, cold/secret metadata, restrictions, source caps, saved options, no drop rates');
