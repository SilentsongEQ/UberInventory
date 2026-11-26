-- Recipe source relationships are generated offline. Names resolve in the client
-- locale where possible; an uncached name remains retryable on the next hover.
local sourceNames = {};
local function PlainText( value )
    if ( issecretvalue and issecretvalue( value ) ) then return nil; end;
    if ( type( value ) ~= "string" or value == "" ) then return nil; end;
    if ( value == RETRIEVING_DATA or value == UNKNOWNOBJECT or value == UNKNOWN ) then return nil; end;
    if ( IsRetrievingData and IsRetrievingData( value ) ) then return nil; end;
    return value;
end;

local function SourceName( source )
    local key = source.kind..":"..( source.id or 0 );
    if ( sourceNames[key] ) then return sourceNames[key]; end;
    local name;
    if ( source.kind == "vendor" or source.kind == "drop" ) then
        if ( C_TooltipInfo and C_TooltipInfo.GetHyperlink ) then
            local ok, data = pcall( C_TooltipInfo.GetHyperlink,
                ( "unit:Creature-0-0-0-0-%d-0000000000" ):format( source.id ) );
            if ( ok and data and data.lines and data.lines[1] ) then
                name = PlainText( data.lines[1].leftText );
            end;
        end;
    elseif ( source.kind == "quest" ) then
        name = C_QuestLog and C_QuestLog.GetTitleForQuestID and PlainText( C_QuestLog.GetTitleForQuestID( source.id ) );
        name = name or PlainText( UBI_RecipeQuestNames[source.id] );
    elseif ( source.kind == "object" ) then
        name = PlainText( UBI_RecipeObjectNames[source.id] );
    elseif ( source.kind == "container" ) then
        name = PlainText( C_Item.GetItemInfo( source.id ) );
    elseif ( source.kind == "encounter" ) then
        name = EJ_GetEncounterInfo and PlainText( EJ_GetEncounterInfo( source.id ) );
    else
        return source.text or UBI_RECIPE_WORLD_DROP;
    end;
    if ( name ) then sourceNames[key] = name; return name; end;
    local label = source.kind == "quest" and QUESTS_LABEL
        or source.kind == "container" and ITEMS
        or source.kind == "object" and UBI_RECIPE_TREASURE
        or source.kind == "encounter" and UBI_RECIPE_ENCOUNTER or "NPC";
    return ( label or UBI_RECIPE_SOURCE ).." #"..source.id;
end;

local function LocationText( source )
    local names, seen = {}, {};
    for _, mapID in ipairs( source.maps or {} ) do
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo( mapID );
        local name = info and PlainText( info.name ) or UBI_RECIPE_MAP:format( mapID );
        if ( not seen[name] ) then names[#names+1] = name; seen[name] = true; end;
    end;
    return table.concat( names, ", " );
end;

local function RequirementText( source )
    local notes = {};
    if ( source.faction ) then notes[#notes+1] = source.faction == 1 and FACTION_HORDE or FACTION_ALLIANCE; end;
    if ( source.races ) then
        local names = {};
        for _, id in ipairs( source.races ) do
            local info = C_CreatureInfo and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo( id );
            names[#names+1] = info and info.raceName or ( UBI_RECIPE_RACE.." #"..id );
        end;
        notes[#notes+1] = table.concat( names, ", " );
    end;
    if ( source.classes ) then
        local names = {};
        for _, id in ipairs( source.classes ) do
            local info = C_CreatureInfo and C_CreatureInfo.GetClassInfo and C_CreatureInfo.GetClassInfo( id );
            names[#names+1] = info and info.className or ( UBI_RECIPE_CLASS.." #"..id );
        end;
        notes[#notes+1] = table.concat( names, ", " );
    end;
    if ( source.reputation ) then
        local id, amount = source.reputation[1], source.reputation[2];
        local info = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID( id );
        notes[#notes+1] = UBI_RECIPE_REPUTATION:format( info and info.name or ( "#"..id ), amount or 0 );
    end;
    if ( source.quests ) then
        local ids = {};
        for _, id in ipairs( source.quests ) do ids[#ids+1] = "#"..id; end;
        notes[#notes+1] = UBI_RECIPE_PREREQUISITES..table.concat( ids, ", " );
    end;
    if ( source.conditional ) then notes[#notes+1] = UBI_RECIPE_CONDITIONAL; end;
    if ( source.status == "removed" ) then notes[#notes+1] = UBI_RECIPE_REMOVED;
    elseif ( source.status == "unavailable" ) then notes[#notes+1] = UBI_RECIPE_UNAVAILABLE;
    elseif ( source.status == "restricted" ) then notes[#notes+1] = UBI_RECIPE_RESTRICTED; end;
    return table.concat( notes, "; " );
end;

function UberInventory_AddRecipeSources( tooltip, itemID )
    local sources = UBI_RecipeSources[itemID];
    if ( not sources ) then return; end;
    local groups = { {}, {}, {} };
    for _, source in ipairs( sources ) do
        local group = source.kind == "vendor" and 1 or source.kind == "quest" and 2 or 3;
        groups[group][#groups[group]+1] = source;
    end;
    local options = { "show_recipe_prices", "show_recipe_reward", "show_recipe_drop" };
    local titles = { UBI_RECIPE_VENDOR_TITLE, UBI_RECIPE_QUEST_TITLE, UBI_RECIPE_OTHER_TITLE };
    local priority = { restricted=1, removed=2, unavailable=3 };
    for group, records in ipairs( groups ) do
        if ( UBI_Options[options[group]] and #records > 0 ) then
            -- Keep historical sources, but present unflagged sources first.
            table.sort( records, function(a,b)
                local left, right = priority[a.status] or 0, priority[b.status] or 0;
                if ( left ~= right ) then return left < right; end;
                return (a.kind..":"..(a.id or 0)..":"..(a.text or "")) < (b.kind..":"..(b.id or 0)..":"..(b.text or ""));
            end );
            tooltip:AddLine( "|n"..titles[group] );
            local shown = math.min( #records, UBI_MAX_RECIPE_INFO );
            for i=1,shown do
                local source = records[i];
                local name = SourceName( source );
                if ( source.kind == "container" ) then name = UBI_RECIPE_CONTAINER..name;
                elseif ( source.kind == "object" ) then name = UBI_RECIPE_TREASURE..": "..name; end;
                tooltip:AddDoubleLine( "  "..name, LocationText( source ), 0, 1, 0, 0, 0.7, 1 );
                local requirements = RequirementText( source );
                if ( requirements ~= "" ) then tooltip:AddLine( "  "..requirements, 1, 0.82, 0, true ); end;
            end;
            if ( #records > shown ) then tooltip:AddLine( UBI_RECIPE_MORE:format( #records-shown ), 0.7, 0.7, 0.7 ); end;
        end;
    end;
end;
