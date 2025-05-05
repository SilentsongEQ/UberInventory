--[[ =================================================================
	UberInventory Reborn
	
	Maintained By: SilentsongEQ

    Description:
        Type /ubi or /uberinventory to see what you currently own,
        whether it is in the bank or in the bags you carry.

    Dependencies:
        None

     ================================================================= --]]

-- Local globals
    local _G = _G;
    local strfind, strgsub, strlower = string.find, string.gsub, string.lower;
    local floor, ceil, abs, tonumber = math.floor, math.ceil, math.abs, tonumber;
    local pairs, tinsert, tsort, wipe = pairs, table.insert, table.sort, wipe;
	
-- Create LDB object to interface with other data brokers including the minimap button
	local UBILDB = LibStub("LibDataBroker-1.1"):NewDataObject("UBI", {
	type = "data source",
	text = "UBI",
	icon = "Interface\\Addons\\UberInventory\\artwork\\UberInventory.tga",
	OnClick = function(self, button) 
	    if (button == "LeftButton") then
			UberInventory_UpdateInventory( "all" );
            UberInventory_Toggle_Main();
		end
        if (button == "RightButton") then
		--
        end
		if (button == "MiddleButton") then
            UberInventory_MailExpirationCheck();
		end
	end,
	OnTooltipShow = function(tt)
        tt:AddLine(UBI_NAME_VERSION);
		tt:AddLine(" ", 0.2, 1, 0.2);
        tt:AddLine("|cffeda55fLeft-Click|r to toggle UI.", 0.2, 1, 0.2);
		if ( UBI_Options["warn_mailexpire"] ) then
			tt:AddLine("|cffeda55fMiddle-Click|r for mail expirations.", 0.2, 1, 0.2);
		end
		tt:AddLine(" ", 0.2, 1, 0.2);
		tt:AddLine( UBI_ACCOUNT_SUMMARY_MESSAGE, 0.2, 1, 0.2);
		tt:AddLine( UBI_MONEY_PLAYER_MESSAGE_MINIMAP:format( GetMoneyString( GetMoney(), true ) ), 0.2, 1, 0.2 );
		tt:AddLine( UBI_MONEY_ACCOUNT_MESSAGE_MINIMAP:format( GetMoneyString( GetAccountWideGoldValue(), true ) ), 0.2, 1, 0.2 );
		end,
    });
	
-- Addon Compartment
	function UberInventory_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
		UberInventory_UpdateInventory( "all" );
        UberInventory_Toggle_Main();
	end
 
	function UberInventory_OnAddonCompartmentEnter(addonName, menuButtonFrame)
        GameTooltip:SetOwner( AddonCompartmentFrame )
        GameTooltip:AddLine( UBI_NAME_VERSION )
		GameTooltip:AddLine(" ", 0.2, 1, 0.2);
        GameTooltip:AddLine("|cffeda55fClick|r to toggle UI.", 0.2, 1, 0.2);
		GameTooltip:AddLine(" ", 0.2, 1, 0.2);
		GameTooltip:AddLine( UBI_ACCOUNT_SUMMARY_MESSAGE, 0.2, 1, 0.2);
		GameTooltip:AddLine( UBI_MONEY_PLAYER_MESSAGE_MINIMAP:format( GetMoneyString( GetMoney(), true ) ), 0.2, 1, 0.2 );
		GameTooltip:AddLine( UBI_MONEY_ACCOUNT_MESSAGE_MINIMAP:format( GetMoneyString( GetAccountWideGoldValue(), true ) ), 0.2, 1, 0.2 );
        GameTooltip:Show()
	end

	function UberInventory_OnAddonCompartmentLeave(addonName, menuButtonFrame)
		GameTooltip:Hide();
	end
	
-- Loadouts
    local addon = LibStub("AceAddon-3.0"):NewAddon("UBI", "AceConsole-3.0");
	local minimapIcon = LibStub("LibDBIcon-1.0");
	local AceGUI = LibStub("AceGUI-3.0");
	
-- Classes structure (used to be provided by GetAuctionItemClasses and GetAuctionItemSubClasses)
    UBI_CLASSES = { { id = 1, name = UBI_ALL_CLASSES, childs = {} }, 
                    -- Weapons
                    { id = 2, name = GetItemClassInfo(2)
                    , childs = { GetItemSubClassInfo(2, 0) --LE_ITEM_WEAPON_AXE1H)        -- One-Handed Axes
							   , GetItemSubClassInfo(2, 1) --LE_ITEM_WEAPON_AXE2H)        -- Two-Handed Axes
							   , GetItemSubClassInfo(2, 2) --LE_ITEM_WEAPON_BOWS)         -- Bows
							   , GetItemSubClassInfo(2, 3) --LE_ITEM_WEAPON_GUNS)         -- Guns
							   , GetItemSubClassInfo(2, 4) --LE_ITEM_WEAPON_MACE1H)       -- One-Handed Maces
							   , GetItemSubClassInfo(2, 5) --LE_ITEM_WEAPON_MACE2H)       -- Two-Handed Maces
							   , GetItemSubClassInfo(2, 6) --LE_ITEM_WEAPON_POLEARM)      -- Polearms
							   , GetItemSubClassInfo(2, 7) --LE_ITEM_WEAPON_SWORD1H)      -- One-Handed Swords
							   , GetItemSubClassInfo(2, 8) --LE_ITEM_WEAPON_SWORD2H)      -- Two-Handed Swords
							   , GetItemSubClassInfo(2, 9) --LE_ITEM_WEAPON_WARGLAIVE)    -- Warglaives
							   , GetItemSubClassInfo(2, 10) --LE_ITEM_WEAPON_STAFF)        -- Staves
							   , GetItemSubClassInfo(2, 11) --LE_ITEM_WEAPON_BEARCLAW)     -- Bear Claws
							   , GetItemSubClassInfo(2, 12) --LE_ITEM_WEAPON_CATCLAW)      -- CatClaws
							   , GetItemSubClassInfo(2, 13) --LE_ITEM_WEAPON_UNARMED)      -- Fist Weapons
							   , GetItemSubClassInfo(2, 14) --LE_ITEM_WEAPON_GENERIC)      -- Miscellaneous
							   , GetItemSubClassInfo(2, 15) --LE_ITEM_WEAPON_DAGGER)       -- Daggers
							   , GetItemSubClassInfo(2, 17) --LE_ITEM_WEAPON_DAGGER)       -- Spears
							   , GetItemSubClassInfo(2, 18) --LE_ITEM_WEAPON_CROSSBOW)     -- Crossbows
							   , GetItemSubClassInfo(2, 19) --LE_ITEM_WEAPON_WAND)         -- Wands
							   , GetItemSubClassInfo(2, 20) --LE_ITEM_WEAPON_FISHINGPOLE)  -- Fishing Poles
                    } },
                    -- Armor
                    { id = 3, name = GetItemClassInfo(4)
                    , childs = { GetItemSubClassInfo(4, 4) --LE_ITEM_ARMOR_PLATE)
                               , GetItemSubClassInfo(4, 3) --LE_ITEM_ARMOR_MAIL)
                               , GetItemSubClassInfo(4, 2) --LE_ITEM_ARMOR_LEATHER)
                               , GetItemSubClassInfo(4, 1) --LE_ITEM_ARMOR_CLOTH)
                               , GetItemSubClassInfo(4, 0) --LE_ITEM_ARMOR_GENERIC)
                               , GetItemSubClassInfo(4, 5) --LE_ITEM_ARMOR_COSMETIC)
							   , GetItemSubClassInfo(4, 6) --LE_ITEM_ARMOR_SHIELD)
                    } },
                    -- Container
                    { id = 4, name = GetItemClassInfo(1)
                    , childs = { GetItemSubClassInfo(1,0)
                               , GetItemSubClassInfo(1,1)
                               , GetItemSubClassInfo(1,2)
                               , GetItemSubClassInfo(1,3)
                               , GetItemSubClassInfo(1,4)
                               , GetItemSubClassInfo(1,5)
                               , GetItemSubClassInfo(1,6)
                               , GetItemSubClassInfo(1,7)
                               , GetItemSubClassInfo(1,8)
                               , GetItemSubClassInfo(1,9)
                               , GetItemSubClassInfo(1,10)
															  
                    } },
                    -- Gem
                    { id = 5, name = GetItemClassInfo(3)
                    , childs = { GetItemSubClassInfo(3,0)
                               , GetItemSubClassInfo(3,1)
                               , GetItemSubClassInfo(3,2)
                               , GetItemSubClassInfo(3,3)
                               , GetItemSubClassInfo(3,4)
                               , GetItemSubClassInfo(3,5)
                               , GetItemSubClassInfo(3,6)
                               , GetItemSubClassInfo(3,7)
                               , GetItemSubClassInfo(3,8)
                               , GetItemSubClassInfo(3,9)
                               , GetItemSubClassInfo(3,10)
                               , GetItemSubClassInfo(3,11)
                    } },
                    -- Item Enhancement
                    { id = 6, name = GetItemClassInfo(8)
                    , childs = { GetItemSubClassInfo(8,0)
                               , GetItemSubClassInfo(8,1)
                               , GetItemSubClassInfo(8,2)
                               , GetItemSubClassInfo(8,3)
                               , GetItemSubClassInfo(8,4)
                               , GetItemSubClassInfo(8,5)
                               , GetItemSubClassInfo(8,6)
                               , GetItemSubClassInfo(8,7)
                               , GetItemSubClassInfo(8,8)
                               , GetItemSubClassInfo(8,9)
                               , GetItemSubClassInfo(8,10)
                               , GetItemSubClassInfo(8,11)
                               , GetItemSubClassInfo(8,12)
                               , GetItemSubClassInfo(8,13)
							   , GetItemSubClassInfo(8,14)
                    } },
                    -- Consumable
                    { id = 7, name = GetItemClassInfo(0)
                    , childs = { GetItemSubClassInfo(0,0)
                               , GetItemSubClassInfo(0,1)
                               , GetItemSubClassInfo(0,2)
                               , GetItemSubClassInfo(0,3)
                               , GetItemSubClassInfo(0,5)
                               , GetItemSubClassInfo(0,7)
                               , GetItemSubClassInfo(0,9)
                               , GetItemSubClassInfo(0,8)
                    } },
                    -- Glyph
                    { id = 8, name = GetItemClassInfo(16)
                    , childs = { GetItemSubClassInfo(16,1)
                               , GetItemSubClassInfo(16,2)
                               , GetItemSubClassInfo(16,3)
                               , GetItemSubClassInfo(16,4)
                               , GetItemSubClassInfo(16,5)
                               , GetItemSubClassInfo(16,6)
                               , GetItemSubClassInfo(16,7)
                               , GetItemSubClassInfo(16,8)
                               , GetItemSubClassInfo(16,9)
                               , GetItemSubClassInfo(16,10)
                               , GetItemSubClassInfo(16,11)
                               , GetItemSubClassInfo(16,12)
                    } },
                    -- Trade Goods
                    { id = 9, name = GetItemClassInfo(7)
                    , childs = { GetItemSubClassInfo(7,5)
                               , GetItemSubClassInfo(7,6)
                               , GetItemSubClassInfo(7,7)
                               , GetItemSubClassInfo(7,8)
                               , GetItemSubClassInfo(7,9)
                               , GetItemSubClassInfo(7,12)
                               , GetItemSubClassInfo(7,16)
                               , GetItemSubClassInfo(7,4)
                               , GetItemSubClassInfo(7,1)
                               , GetItemSubClassInfo(7,10)
                               , GetItemSubClassInfo(7,11)
                    } },
                    -- Recipe
                    { id = 10, name = GetItemClassInfo(9)
                    , childs = { GetItemSubClassInfo(9,1)
                               , GetItemSubClassInfo(9,2)
                               , GetItemSubClassInfo(9,3)
                               , GetItemSubClassInfo(9,4)
                               , GetItemSubClassInfo(9,6)
                               , GetItemSubClassInfo(9,8)
                               , GetItemSubClassInfo(9,10)
                               , GetItemSubClassInfo(9,11)
                               , GetItemSubClassInfo(9,5)
                               , GetItemSubClassInfo(9,7)
                               , GetItemSubClassInfo(9,9)
                               , GetItemSubClassInfo(9,0)
                    } },
                    -- Battle Pets
                    { id = 11, name = GetItemClassInfo(17)
                    , childs = { GetItemSubClassInfo(17,0)
                               , GetItemSubClassInfo(17,1)
                               , GetItemSubClassInfo(17,2)
                               , GetItemSubClassInfo(17,3)
                               , GetItemSubClassInfo(17,4)
                               , GetItemSubClassInfo(17,5)
                               , GetItemSubClassInfo(17,6)
                               , GetItemSubClassInfo(17,7)
                               , GetItemSubClassInfo(17,8)
                               , GetItemSubClassInfo(17,9)
                    } },
                    -- Miscellaneous
                    { id = 13, name = GetItemClassInfo(15)
                    , childs = { GetItemSubClassInfo(15,0)
                               , GetItemSubClassInfo(15,1)
                               , GetItemSubClassInfo(15,2)
                               , GetItemSubClassInfo(15,3)
                               , GetItemSubClassInfo(15,4)
                               , GetItemSubClassInfo(15,5)
							   , GetItemSubClassInfo(15,6)
                    } },
                    -- Quest Items
                    { id = 12, name = GetItemClassInfo(12)
                    , childs = {} },
                    -- WoW Token
                    { id = 14, name = GetItemClassInfo(18)
                    , childs = {} },
                  };

-- Information on tokens
    local UBI_Currencies = {
        -- Shadowlands
        { id=-1, name = EXPANSION_NAME8, force = false },
		{ id=1728, force = true }, -- Phantasma
		{ id=1904, force = true }, -- Tower Knowledge
		{ id=1931, force = true }, -- Cataloged Research
		{ id=1819, force = true }, -- Medallion of Service
		{ id=1828, force = true }, -- Soul Ash
		{ id=1906, force = true }, -- Soul Cinders
		{ id=1816, force = true }, -- Sinstone Fragments
		{ id=1767, force = true }, -- Stygia
		{ id=1977, force = true }, -- Stygian Ember
		{ id=1810, force = true }, -- Redeemed Soul
		{ id=1820, force = true }, -- Infused Ruby
		{ id=1822, force = true }, -- Renown
		{ id=1885, force = true }, -- Grateful Offering
		{ id=1813, force = true }, -- Reservoir Anima
		{ id=1883, force = true }, -- Soulbind Conduit Energy
		{ id=1889, force = true }, -- Adventure Campaign Progress
		{ id=1979, force = true }, -- Cyphers of the First Ones
		{ id=2009, force = true }, -- Cosmic Flux

        -- Dungeon and Raid
        { id=-3, name = LFG_TYPE_DUNGEON.." & "..LFG_TYPE_RAID, force = false },
        { id=615, force = true }, -- Mote of Darkness
        { id=395, force = true }, -- Justice Points
        { id=1166, force = true }, -- Timewarped Badge
        { id=614, force = true }, -- Mote of Darkness

        -- Miscellaneous
        { id=-4, name = MISCELLANEOUS, force = false },
        { id=515, force = true }, -- Darkmoon Prize Ticket
        { id=81, force = true }, -- Epicurean's Award
        { id=402, force = true }, -- Ironpaw Token
        { id=416, force = true }, -- Mark of the World Tree

        -- Player vs Player
        { id=-5, name = PLAYER_V_PLAYER, force = false },
        { id=391, force = true }, -- Tol Barad Commendation
		{ id=1585, force = true }, -- Honor Current
		{ id=1586, force = true }, -- Honor Level
        { id=1191, force = true }, -- Valor Points

        -- Battle for Azeroth
        { id=-2, name = EXPANSION_NAME7, force = false },
        { id=1565, force = true }, -- RICH_AZERITE_FRAGMENT
        { id=1710, force = true }, -- SEAFARERS_DUBLOON
        { id=1580, force = true }, -- SEAL_OF_WARTORN_FATE
        { id=1560, force = true }, -- WAR_RESOURCES
        { id=1587, force = true }, -- WAR_SUPPLIES
        { id=1716, force = true }, -- HONORBOUND_SERVICE_MEDAL
        { id=1717, force = true }, -- 7TH_LEGION_SERVICE_MEDAL
        { id=1718, force = true }, -- TITAN_RESIDUUM
        { id=1721, force = true }, -- PRISMATIC_MANAPEARL
		{ id=1803, force = true }, -- ECHOES_OF_NY'ALOTHA
		{ id=1755, force = true }, -- COALESCING VISIONS
		{ id=1719, force = true }, -- CORRUPTED MEMENTOS

		-- Legion
        { id=-6, name = EXPANSION_NAME6, force = false },
        { id=1155, force = true }, -- Ancient Mana
        { id=1275, force = true }, -- Curious Coin
        { id=1226, force = true }, -- Nethershard
        { id=1220, force = true }, -- Order Resources
        { id=1273, force = true }, -- Seal of Broken Fate
        { id=1154, force = true }, -- Shadowy Coins
        { id=1149, force = true }, -- Sightless Eye
        { id=1268, force = true }, -- Timeworn Artifact
        { id=1533, force = true }, -- Wakening Essence
		
        -- Warlords of Draenor
        { id=-7, name = EXPANSION_NAME5, force = false },
        { id=823, force = true }, -- Apexis Crystal
        { id=944, force = true }, -- Artifact Fragment
        { id=824, force = true }, -- Garrison Resources
        { id=994, force = true }, -- Seal of Tempered Fate
        { id=1101, force = true }, -- Oil
        { id=1129, force = true }, -- Seal of Inevitable Fate

        -- Mist of Pandaria
        { id=-8, name = EXPANSION_NAME4, force = false },
        { id=738, force = true }, -- Lesser Charm of Good Fortune
        { id=697, force = true }, -- Elder Charm of Good Fortune
        { id=777, force = true }, -- Timeless Coin
        { id=776, force = true }, -- Warforged Seal
        { id=752, force = true }, -- Mogu Rune of Fate

        -- Cataclysm
        { id=-9, name = EXPANSION_NAME3, force = false },
        { id=361, force = true }, -- Illustrious Jewelcrafter's Token
        { id=698, force = true }, -- Zen Jewelcrafter's Token

        -- Wrath of the Lich King
        { id=-10, name = EXPANSION_NAME2, force = false },
        { id=241, force = true }, -- Champion's Seal
        { id=61, force = true }, -- Dalaran Jewelcrafting Token

    };

-- Text and tooltips for checkbuttons (order is relevant to the ID of the UI object in .xml)
    UBI_CheckButtons = {
        { text = UBI_OPTION_MONEY, tooltip = UBI_OPTION_MONEY_TIP },
        { text = UBI_OPTION_BALANCE, tooltip = UBI_OPTION_BALANCE_TIP },
		{ text = UBI_OPTION_PLACEHOLDER, tooltip = UBI_OPTION_PLACEHOLDER_TIP },
        { text = UBI_OPTION_RECIPEPRICES, tooltip = UBI_OPTION_RECIPEPRICES_TIP },
        { text = UBI_OPTION_QUESTREWARD, tooltip = UBI_OPTION_QUESTREWARD_TIP },
        { text = UBI_OPTION_RECIPEDROP, tooltip = UBI_OPTION_RECIPEDROP_TIP },
        { text = UBI_OPTION_TAKEMONEY, tooltip = UBI_OPTION_TAKEMONEY_TIP },
        { text = UBI_OPTION_SHOWMAP, tooltip = UBI_OPTION_SHOWMAP_TIP },
        { text = UBI_OPTION_GBSEND, tooltip = UBI_OPTION_GBSEND_TIP },
        { text = UBI_OPTION_GBRECEIVE, tooltip = UBI_OPTION_GBRECEIVE_TIP },
        { text = UBI_OPTION_WARN_MAILEXPIRE, tooltip = UBI_OPTION_WARN_MAILEXPIRE_TIP },
        { text = UBI_OPTION_HIGHLIGHT, tooltip = UBI_OPTION_HIGHLIGHT_TIP },
        { text = UBI_OPTION_SHOWTOOLTIP, tooltip = UBI_OPTION_SHOWTOOLTIP_TIP },
        { text = UBI_OPTION_ITEMCOUNT, tooltip = UBI_OPTION_ITEMCOUNT_TIP },
        { text = UBI_OPTION_GBTRACK, tooltip = UBI_OPTION_GBTRACK_TIP },
        { text = UBI_OPTION_PRICES_VENDOR, tooltip = UBI_OPTION_PRICES_VENDOR_TIP },
        { text = UBI_OPTION_PRICES_AH, tooltip = UBI_OPTION_PRICES_AH_TIP },
        { text = UBI_OPTION_REALMIGNORE, tooltip = UBI_OPTION_REALMIGNORE_TIP },
		{ text = UBI_OPTION_SELLGREYS, tooltip = UBI_OPTION_SELLGREYS_TIP },
		{ text = UBI_OPTION_AUTOREPAIRSELF, tooltip = UBI_OPTION_AUTOREPAIRSELF_TIP },
		{ text = UBI_OPTION_SHOWITEMID, tooltip = UBI_OPTION_SHOWITEMID_TIP },
    };

-- Static dialogs
    StaticPopupDialogs["UBI_CONFIRM_DELETE"] = {
        text = "%s",
        button1 = YES,
        button2 = NO,
        timeout = 10,
        whileDead = 1,
        exclusive = 1,
        showAlert = 1,
        hideOnEscape = 1
    };

-- Enable/Disable an UI object
    function UberInventory_SetState( object, state )
        if ( object ) then
            if ( state ) then
                object:Enable();
            else
                object:Disable();
            end;
        end;
    end;

-- UberInventory task: Collect mailbox cash
    function UBI_Task_CollectCash( mailid )
        -- Mail info
        local _, _, mailSender, mailSubject, cashAttached = GetInboxHeaderInfo( mailid );
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo( mailid );

        if ( cashAttached > 0 ) then
            -- Report cash attached to message
            UberInventory_Message( UBI_MAIL_CASH:format( GetCoinTextureString( cashAttached ), mailSender, mailSubject ), true );

            -- Take the money
            TakeInboxMoney( mailid );
        end;
    end;

-- UberInventory task: Send stream end indication
    function UBI_Task_SendMessage( task, info )
        -- Define valid tasks
        local valid_tasks = { VERINFO=1, GBSTART=1, GBITEM=1, GBCASH=1, GBEND=1, GBREQUEST=1 };

        -- Only send message when in a guild and a valid task has been provided
        if ( IsInGuild() and valid_tasks[task] ) then
            if ( info ) then
                C_ChatInfo.SendAddonMessage( "UBI", "UBI:"..task.." "..info, "GUILD" );
            else
                C_ChatInfo.SendAddonMessage( "UBI", "UBI:"..task, "GUILD" );
            end;
        end;
    end;

-- Upgrade data structures
    function UberInventory_Upgrade()
        -- From global to local
        local UBI_Options = UBI_Options;
        local UBI_Data = UBI_Data;

        -- Upgrade process
		--UBI_Global_Options["Options"]["patch_message_version"] = "1.1.1.1";		
		--UberInventory_Message( "DEBUG: Previous version forced to v1.1.1.1", true );	
		
        if ( UBI_Global_Options["Options"]["patch_message_version"] ~= UBI_VERSION ) then
			
			-- ---------------------------------------------------
			-- PATCHER SET 1
			--     Upgrade to version 10.0.0.2
			--     Reset settings to defaults
			-- ---------------------------------------------------
			--UberInventory_Message( "DEBUG: Patcher version: "..UBI_PATCHER.." | Addon version: "..UBI_VERSION, true);
            if ( tonumber(UBI_PATCHER) == 1 ) then
				UBI_Global_Options["Options"]["ignore_realm"] = UBI_Defaults["ignore_realm"];
				UberInventory_SetDefaults( frame );
				
				--UberInventory_UpdateUI();
				UberInventory_Message( "Upgrading data store and settings to version "..UBI_VERSION.." (currently "..UBI_Global_Options["Options"]["patch_message_version"]..")", true);
            end;

			-- ---------------------------------------------------
            -- Set current version for active player
            UBI_Options["version"] = UBI_VERSION;
			
            -- Show upgrade message
			if ( UBI_SHOWUPGRADEMESSAGE == "true" ) then
				UberInventory_UpgradeMessage();
			end;
			UBI_Global_Options["Options"]["patch_message_version"] = UBI_VERSION;

        end;
		
		-- Datastore maintenance
		-- 		Add PlayerRealm attribute for each stored character
		--		Remove old options
		--		Executed each time the addon loads
		for realm, record in pairs( UBI_Data ) do
			for player, value in pairs( UBI_Data[realm] ) do
				if ( player ~= "Guildbank" ) then
					-- update player realm and version info by character
					playerRealm = player.."-"..realm;
					UBI_Data[realm][player]["Options"]["player_realm"] = playerRealm;
					UBI_Data[realm][player]["Options"]["version"] = UBI_VERSION;
					
					-- remove old options
					if ( UBI_Data[realm][player]["Options"]["ignore_realm"] ~= nil ) then
						UBI_Data[realm][player]["Options"]["ignore_realm"] = nil;
					end;
					if ( UBI_Data[realm][player]["Options"]["pricing_data"] ~= nil ) then
						UBI_Data[realm][player]["Options"]["pricing_data"] = nil;
					end;
					if ( UBI_Data[realm][player]["Options"]["show_sell_prices"] ~= nil ) then
						UBI_Data[realm][player]["Options"]["show_sell_prices"] = nil;
					end;
					
					-- UberInventory_Message( "DEBUG UPGRADE PLAYER_REALM: "..playerRealm, true );
				end;
			end;
		end;
		
    end;

-- Days since visit
    function UberInventory_DaysSince( visit )
        local timediff;
        local today = time( UberInventory_GetDateTime() );

        if ( type( visit ) == "table" ) then
            timediff = difftime( today, time( visit ) or today );
        else
            timediff = difftime( today, visit or today )
        end;

        return floor( timediff / UBI_SEC_IN_DAY ), SecondsToTime( timediff );
    end;

-- Send message to the default chat frame
    function UberInventory_Message( msg, prefix )
        -- Initialize
        local prefixText = "";

        -- Add application prefix
        if ( prefix and true ) then
            prefixText = C_GREEN.."UBI: "..C_CLOSE;
        end;

        -- Send message to chatframe
        DEFAULT_CHAT_FRAME:AddMessage( prefixText..( msg or "" ) );
    end;

-- Save cash owned
    function UberInventory_SaveMoney()
        if ( not UBI_ACTIVE ) then return; end;

        -- Save money
        UBI_Money["Cash"] = GetMoney();
    end;

-- Save other currencies owned ( Honor points, Arena points, Tokens, etc )
    function UberInventory_Save_Currencies()
        if ( not UBI_ACTIVE ) then return; end;
		local quantity;

        -- Save other currencies
        for key, value in pairs( UBI_Currencies ) do
            if ( value.id > 0 ) then
				--UberInventory_Message( "DEBUG GetCurrencyInfo: id = "..value.id, true );
                local CurrencyInfo = C_CurrencyInfo.GetCurrencyInfo( value.id );			-- v9.0 moved to C_CurrencyInfo
				value.name, value.icon = CurrencyInfo.name, CurrencyInfo.iconFileID;
				quantity = CurrencyInfo.quantity or 0;
				if ( value.name == "Renown" ) then
					quantity = quantity + 1;
				end;
                UBI_Money["Currencies"][value.id] = quantity;
            end;
        end;
    end;

-- Specialized SetTooltipMoney function (till internal Blizzard code for SetTooltipMoney is fixed)
    function UberInventory_SetTooltipMoney( tooltip, money, type, prefix, suffix )
        -- Initialize
        local moneystring = GetCoinTextureString( money );

        -- Build the string
        if ( prefix ) then moneystring = prefix..moneystring; end;
        if ( suffix ) then moneystring = moneystring..suffix; end;

        -- Add info to the tooltip
        tooltip:AddLine( moneystring.."  ", 1.0, 1.0, 1.0 );
    end;

-- Update slot count information
    function UberInventory_Update_SlotCount()
        UberInventoryFrameBagSlots:SetFormattedText( UBI_SLOT_BAGS, UBI_Options["bag_free"] , UBI_Options["bag_max"] );
        UberInventoryFrameBankSlots:SetFormattedText( UBI_SLOT_BANK, UBI_Options["bank_free"], UBI_Options["bank_max"] );
        UberInventoryFrameReagentBankSlots:SetFormattedText( UBI_SLOT_REAGENTBANK, UBI_Options["reagent_free"], UBI_Options["reagent_max"] );
		UberInventoryFrameAccountBankSlots:SetFormattedText( UBI_SLOT_ACCOUNTBANK, UBI_Accountbank["FreeSlotCount"], UBI_Accountbank["SlotCount"] );
    end;

-- Fetch item prices (buy, sell)
    function UberInventory_GetItemPrices( itemid )
        -- Initialize
        local buyoutPrice, buyPrice, sellPrice;
		
        if ( itemid ) then
          -- Get Auction House buyout price (if available)
          if ( type( GetAuctionBuyout ) == "function" ) then
              -- AuctionLite, Auctionator, AuctionaMaster
              buyoutPrice = GetAuctionBuyout( itemid  ) or 0;
          -- elseif ( AucAdvanced ) then
          --     -- Auctioneer
          --     buyoutPrice = select( 6, AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems( itemid ) ) or 0;
          end;

		  buyPrice = UBI_Prices_Buy[itemid];
          sellPrice = select( 11, C_Item.GetItemInfo( itemid ) );
		end;
        
		return buyPrice, sellPrice, buyoutPrice;
    end;

-- Get Date and time (platform independed)
    function UberInventory_GetDateTime()
	    local date = C_DateAndTime.GetCurrentCalendarTime();				-- v9.0.1 C_Calendar.GetDate() deprecated
		local month_, day_, year_ = date.month, date.monthDay, date.year;
        local hour_, minute_ = GetGameTime();

        return { year=year_, month=month_, day=day_, hour=hour_, min=minute_, sec=00 };
    end;

-- Extract info from tooltip
    function UberInventory_Scan_Tooltip( itemid, color, searchtext )
        -- Rounding function
        local function round( x, digit )
            -- Positions to be shifted
            local shift = 10 ^ digit;

            -- Round the number to wanted decimals
            return floor( x * shift + 0.5 ) / shift;
        end;

        -- Initialize
        local digits = 4;
        local colorFound, textFound = false, false;
        local r, g, b, a, txtLeft, txtRight;

        -- Setup tooltip for extracting data
        local tooltip = UberInventory_ItemTooltip;
        tooltip:ClearLines();
        tooltip:SetHyperlink( UberInventory_GetLink( itemid ) );
        tooltip:Show();

        -- Correct color precision
        color.r = round( color.r, digits );
        color.g = round( color.g, digits );
        color.b = round( color.b, digits );

        -- Traverse tooltip lines
        for i = 1, tooltip:NumLines() do
            -- Get text
            txtLeft = _G[tooltip:GetName().."TextLeft"..i]:GetText();
            txtRight = _G[tooltip:GetName().."TextRight"..i]:GetText();

            -- Find the specified color
            if ( color ) then
                -- Check left color
                r, g, b, a = _G[tooltip:GetName().."TextLeft"..i]:GetTextColor();

                -- Check if requested color was used
                if ( ( round( r, digits ) == color.r ) and
                     ( round( g, digits ) == color.g ) and
                     ( round( b, digits ) == color.b ) and
                     txtLeft ) then
                    colorFound = true;
                end;

                -- Check right color
                local r, g, b, a = _G[tooltip:GetName().."TextRight"..i]:GetTextColor();

                -- Check if requested color was used
                if ( ( round( r, digits ) == color.r ) and
                     ( round( g, digits ) == color.g ) and
                     ( round( b, digits ) == color.b ) and
                     txtRight ) then
                    colorFound = true;
                end;
            end;

            -- Find the specified text
            if ( searchtext and txtLeft ) then
                textFound = txtLeft:match( searchtext );
            end;
            if ( searchtext and txtRight ) then
                textFound = txtRight:match( searchtext );
            end;

            -- Stop on first blank line or new-line char
            if ( txtLeft == "" or txtLeft:find( "\n" ) ) then
                return colorFound, textFound;
            end;
        end;

        return colorFound, textFound;
    end;

-- Can item be used by current player
    function UberInventory_UsableItem( itemid )
        -- Initialize
        local TOOLTIP_RED = { r = 0.99999779462814, g = 0.12548992037773, b = 0.12548992037773 };

        -- Determine if the color red is used within the tooltip
        local colorFound, textFound = UberInventory_Scan_Tooltip( itemid, TOOLTIP_RED, ITEM_SPELL_KNOWN );

        -- Return result (usable or not)
        return ( ( not colorFound ) or textFound );
    end;

-- Build list of usable alts
    function UberInventory_GetAlts()
        -- Initialize
        local UBI_Characters = UBI_Characters;
		local playerRealm;
        wipe( UBI_Characters );

        -- if ignoring realm, loop through looking for characters across all realms
        if ( UBI_Global_Options["Options"]["ignore_realm"] ) then
            for realm, record in pairs( UBI_Data ) do
                for player, value in pairs( UBI_Data[realm] ) do
					if ( player ~= "Guildbank" ) and
					( player ~= UBI_PLAYER ) then
					-- ( ( UBI_Data[realm][player]["Options"]["faction"] or "<Unknown>" ) == UBI_FACTION ) then
						-- Add alt to the list
						playerRealm = UBI_Data[realm][player]["Options"]["player_realm"];
						-- UberInventory_Message( "DEBUG UberInventory_GetAlts A: "..playerRealm, true );
						tinsert( UBI_Characters, playerRealm );
					end;
				end;
			end;
        else
			-- Traverse all players to determine valid alts
			for player, value in pairs( UBI_Data[UBI_REALM] ) do
				if ( player ~= "Guildbank" ) and
				   ( player ~= UBI_PLAYER ) then
				   -- ( ( UBI_Data[UBI_REALM][player]["Options"]["faction"] or "<Unknown>" ) == UBI_FACTION ) then
					-- Add alt to the list
					playerRealm = UBI_Data[UBI_REALM][player]["Options"]["player_realm"];
                    -- UberInventory_Message( "DEBUG UberInventory_GetAlts B: "..playerRealm, true );
					tinsert( UBI_Characters, playerRealm );
				end;
			end;
        end;

        -- Sort alts alphabetically
        tsort( UBI_Characters );
    end;
	

-- Build list of guildbanks
    function UberInventory_GetGuildbanks()
        -- Initialize
        local UBI_Guildbanks = UBI_Guildbanks;
        wipe( UBI_Guildbanks );

        -- Traverse all guildbanks
        for key, value in pairs( UBI_Guildbank ) do
            -- if ( ( value["Faction"] or "<Unknown>" ) == UBI_FACTION ) then
                -- Add alt to the list
                tinsert( UBI_Guildbanks, key );
            -- end;
        end;

        -- Sort alts alphabetically
        tsort( UBI_Guildbanks );
    end;


-- Populate locations internal list
    function UberInventory_Build_Locations()
        -- Initialize
        local UBI_Item, level, classColor;
        local UBI_LocationCounter = UBI_LocationCounter;

        -- Clear locations and reset counter
        wipe( UBI_LocationList );
        UBI_LocationCounter = 1;

        -- Custom function for adding items to dropdownbox
        local function UberInventory_AddLocation( item, itemtype )
            item.owner = UberInventoryFrameLocationDropDown;
            UBI_LocationList[UBI_LocationCounter] = { key = item.value, name = item.text, value = strtrim( item.text ), type = itemtype, object = item };
            UBI_LocationCounter = UBI_LocationCounter + 1;
        end;

		-- _______________________________________________________________________________
        -- All items (inludes current characters, all guildbanks and all other characters)
        UBI_Item = { text = UBI_ALL_LOCATIONS,
                     value = UBI_LocationCounter,
                     notCheckable = 1,
                     func = UberInventory_Locations_OnClick,
                     colorCode = "|cFFFFFF00" };
        UberInventory_AddLocation( UBI_Item, "complete" );

		-- _______________________________________________________________________________
        -- Account Bank
		UBI_Item = { text = UBI_ACCOUNT_BANK_TITLE,
                     value = UBI_LocationCounter,
                     notCheckable = 1,
                     func = UberInventory_Locations_OnClick,
                     colorCode = "|cFFFFFF00" };
        UberInventory_AddLocation( UBI_Item, "account_bank" );

        -- Insert divider
        UBI_Item = { text = "",
                     isTitle = 1,
                     notCheckable = 1 };
        UberInventory_AddLocation( UBI_Item, "title" );
		

		-- _______________________________________________________________________________
        -- Current characters
        if ( UBI_Options["level"] ) then
            level = " ["..C_YELLOW..UBI_Options["level"]..C_CLOSE.."]";
        else
            level = "";
        end;

        UBI_Item = { text = UBI_PLAYER..level,
                     value = UBI_LocationCounter,
                     notCheckable = 1,
                     func = UberInventory_Locations_OnClick,
                     colorCode = "|cFFFFFF00" };
        UberInventory_AddLocation( UBI_Item, "current" );

        -- Add the basic locations
        for key, value in pairs( UBI_LOCATIONS ) do
            -- Set new item
            UBI_Item = { text = "  "..value,
                         value = UBI_LocationCounter,
                         icon = UBI_LOCATION_TEXTURE[key],
                         notCheckable = 1,
                         func = UberInventory_Locations_OnClick };

            -- Add item to dropdown
            UberInventory_AddLocation( UBI_Item, "current" );
        end;

		-- _______________________________________________________________________________
        -- Add separator if there are guildbanks to be added
        if ( #UBI_Guildbanks > 0 ) then
            -- Set new item
            UBI_Item = { text = "",
                         isTitle = 1,
                         notCheckable = 1 };
            UberInventory_AddLocation( UBI_Item, "title" );

            UBI_Item = { text = UBI_ALL_GUILDBANKS,
                         value = UBI_LocationCounter,
                         notCheckable = 1,
                         func = UberInventory_Locations_OnClick,
                         colorCode = "|cFFFFFF00" };
            UberInventory_AddLocation( UBI_Item, "all_guildbank" );
        end;

        -- Add guildbanks (how to determine faction for image?)
        for key, value in pairs( UBI_Guildbanks ) do
            -- Set new item
            UBI_Item = { text = "  "..value,
                         value = UBI_LocationCounter,
                         icon = UBI_LOCATION_TEXTURE[7],
                         notCheckable = 1,
                         func = UberInventory_Locations_OnClick };

            -- Add highlight to current players guildbank
            if ( value == UBI_GUILD ) then
                UBI_Item.colorCode = ITEM_QUALITY_COLORS[5].hex;
            end;

            -- Add item to dropdown (Guildbank only added if in a guild)
            UberInventory_AddLocation( UBI_Item, "guildbank" );
        end;

		-- _______________________________________________________________________________
        -- Add separator if there are alts to be added
        if ( #UBI_Characters > 0 ) then
            -- Set new item
            UBI_Item = { text = "",
                         isTitle = 1,
                         notCheckable = 1 };
            UberInventory_AddLocation( UBI_Item, "title" );

            UBI_Item = { text = UBI_ALL_CHARACTERS,
                         value = UBI_LocationCounter,
                         notCheckable = 1,
                         func = UberInventory_Locations_OnClick,
                         colorCode = "|cFFFFFF00" };
            UberInventory_AddLocation( UBI_Item, "all_character" );
        end;

        -- Add alts to the list from the relevant realm and faction (Alliance or Horde)
        for key, value in pairs( UBI_Characters ) do
		    -- break apart "player-realm"
		    player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
			-- UberInventory_Message( "DEBUG LIST BUILD: "..player..":::"..realm, true );
			
            if ( not UBI_Global_Options["Options"]["ignore_realm"] and realm == UBI_REALM ) then
			    addToList = true;
			elseif ( UBI_Global_Options["Options"]["ignore_realm"] ) then
				addToList = true;
			else
			    addToList = false;
			end;
			
			-- color the text based on class
			classColor = C_WHITE;
			if ( UBI_Data[realm][player]["Options"]["class"] == "PALADIN" ) then
				classColor = C_PALADIN;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "WARRIOR" ) then
				classColor = C_WARRIOR;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "PRIEST" ) then
				classColor = C_PRIEST;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "DEATHKNIGHT" ) then
				classColor = C_DEATHKNIGHT;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "ROGUE" ) then
				classColor = C_ROGUE;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "HUNTER" ) then
				classColor = C_HUNTER;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "SHAMAN" ) then
				classColor = C_SHAMAN;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "MAGE" ) then
				classColor = C_MAGE;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "WARLOCK" ) then
				classColor = C_WARLOCK;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "MONK" ) then
				classColor = C_MONK;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "DRUID" ) then
				classColor = C_DRUID;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "DEMONHUNTER" ) then
				classColor = C_DEMONHUNTER;
			elseif ( UBI_Data[realm][player]["Options"]["class"] == "EVOKER" ) then
				classColor = C_EVOKER;
			end;
			
			-- add the level in yellow
            if ( addToList and UBI_Data[realm][player]["Options"]["level"] ) then
                level = " ["..C_YELLOW..UBI_Data[realm][player]["Options"]["level"]..C_CLOSE.."]";
            else
                level = "";
            end;

            UBI_Item = { text = "  "..value..level,
                         value = UBI_LocationCounter,
                         icon = UBI_LOCATION_TEXTURE[7], -- Faction icon
                         notCheckable = 1,
                         func = UberInventory_Locations_OnClick,
                         colorCode = classColor };

            -- Replace faction icon with class icon if the class is known
            if ( addToList and UBI_Data[realm][player]["Options"]["class"] and UBI_Data[realm][player]["Options"]["class"] ~= "??" ) then
                local tLeft, tRight, tTop, tBottom = unpack( CLASS_ICON_TCOORDS[ UBI_Data[realm][player]["Options"]["class"] ] );

                UBI_Item.icon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";
                UBI_Item.tCoordLeft = tLeft;
                UBI_Item.tCoordRight = tRight;
                UBI_Item.tCoordTop = tTop;
                UBI_Item.tCoordBottom = tBottom;
            end;

            UberInventory_AddLocation( UBI_Item, "character" );
        end;
   end;

-- Populate locations dropdown box (Also contains items for alts on the same realm from the same faction (Alliance or Horde))
    function UberInventory_Locations_Init( self )
        -- Build list of locations
        UberInventory_Build_Locations();

        -- Add items to the dropdown box
        for key, value in pairs( UBI_LocationList ) do
            -- Add item to dropdown
            UIDropDownMenu_AddButton( value.object );
        end;
   end;

-- Resets position in scrollframe to the top
    function UberInventory_ScrollToTop()
       FauxScrollFrame_SetOffset( UberInventoryFrameScroll, 0 );
       UberInventoryFrameScrollScrollBar:SetValue( 0 );
    end;

-- Update locations dropdown box
    function UberInventory_Locations_OnClick( self )
        UBI_FILTER_LOCATIONS = self.value;
        UIDropDownMenu_SetText( self.owner, UBI_LocationList[UBI_FILTER_LOCATIONS].value );
        UberInventory_ScrollToTop();
        UberInventory_DisplayItems();

        -- Update token info on screen
        if ( UberInventoryTokens:IsVisible() ) then
            UberInventory_DisplayTokens();
        end;
    end;

-- Populate quality dropdown box
    function UberInventory_Quality_Init( self )
        -- Initialize
        local UBI_Item;
        local UBI_QUALITY = UBI_QUALITY;
		local colorhex;
				
        for key, value in pairs( UBI_QUALITY ) do

			-- 20250504 Fix for item quality menu not populating
			if ( key == 1 ) then
				colorhex = ITEM_QUALITY_COLORS[1].hex;				-- "All Qualities" menu item
			else
				colorhex = ITEM_QUALITY_COLORS[key-2].hex;			-- Color for specific quality
			end;
			
			-- print(key.."   "..colorhex..value);

            -- Set new item
            UBI_Item = { text = value,
                         value = key,
                         owner = UberInventoryFrameQualityDropDown,
                         notCheckable = 1,
                         func = UberInventory_Quality_OnClick,
						 colorCode = colorhex };

            -- Add item to dropdown
            UIDropDownMenu_AddButton( UBI_Item );
        end;
    end;

-- Update quality dropdown box
    function UberInventory_Quality_OnClick( self )
        UBI_FILTER_QUALITY = self.value;
        UIDropDownMenu_SetText( self.owner, UBI_QUALITY[UBI_FILTER_QUALITY] );
        UberInventory_ScrollToTop();
        UberInventory_DisplayItems();
    end;

-- Populate classes dropdown box
    function UberInventory_Classes_Init( self )
        -- Initialize
        local subclasses, UBI_Item;
        local UBI_CLASSES = UBI_CLASSES;

        -- Build structure for classes
        if ( UIDROPDOWNMENU_MENU_LEVEL == 1 ) then
            for key, value in pairs( UBI_CLASSES ) do
                -- Set new item
                UBI_Item = { text = value.name,
                             value = {value.id, 0},
                             owner = UberInventoryFrameClassDropDown,
                             notCheckable = 1,
                             hasArrow = #(value.childs) > 0,
                             func = UberInventory_Classes_OnClick };

                -- Add item to dropdown
                UIDropDownMenu_AddButton( UBI_Item, UIDROPDOWNMENU_MENU_LEVEL );
            end;
        end;

        -- Build structure for subclasses
        if ( UIDROPDOWNMENU_MENU_LEVEL == 2 ) then
            -- Determine subclasses
            subclasses = UBI_CLASSES[UIDROPDOWNMENU_MENU_VALUE[1]].childs;

            for key, value in pairs( subclasses ) do
                if ( value ) then
                    -- Set new tem
                    UBI_Item = { text = value,
                                 value = { UIDROPDOWNMENU_MENU_VALUE[1], key },
                                 owner = UberInventoryFrameClassDropDown,
                                 notCheckable = 1,
                                 func = UberInventory_Classes_OnClick
                                 };

                    -- Add item to dropdown
                    UIDropDownMenu_AddButton( UBI_Item, UIDROPDOWNMENU_MENU_LEVEL );
                end;
            end;
        end;
    end;

-- Update classes dropdown box
    function UberInventory_Classes_OnClick( self )
        -- Get selection
        UBI_FILTER_CLASSES = self.value[1];
        UBI_FILTER_SUBCLASSES = self.value[2];

        -- Determine dropdown text
        local infoText = UBI_CLASSES[UBI_FILTER_CLASSES].name;
        if ( UBI_FILTER_SUBCLASSES > 0 ) then
            infoText = infoText.." > "..UBI_CLASSES[UBI_FILTER_CLASSES].childs[UBI_FILTER_SUBCLASSES]
            HideDropDownMenu( 1 ); -- Collapse also the top level menu
        end;

        UIDropDownMenu_SetText( self.owner, infoText );
        UberInventory_ScrollToTop();
        UberInventory_DisplayItems();
    end;

-- Returns an itemLink
    function UberInventory_GetLink( itemid, record )
        if ( record and ( record.type == UBI_BATTLEPET_CLASS and record.item ~= 82800 ) ) then
            return UberInventory_GetBattlePetLink( record );
        end;

        -- Get name of item
        local itemName, itemLink, itemQuality = C_Item.GetItemInfo( itemid );

        -- If the item has never been seen before, itemName will be nil
        if ( itemName == nil ) then
            local color = ITEM_QUALITY_COLORS[0].hex;
            itemLink = color.."|Hitem:"..itemid..":0:0:0:0:0:0:0|h["..UBI_ITEM_UNCACHED.."]|h|r";
        end;

        -- Return itemLink
        return itemLink;
    end;

-- Returns an Battlepet Link
    function UberInventory_GetBattlePetLink( record )
        -- Initialize
        local health, power, speed = 0, 0, 0;

        -- Get name of item
        local name, icon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID( record.itemid );

        -- If the item has never been seen before, name will be nil
        if ( name == nil ) then
            name = UBI_ITEM_UNCACHED;
        end;

        -- Get additional battlepet info
        if ( record.extra ) then
            health = record.extra[1] or 0;
            power = record.extra[2] or 0;
            speed = record.extra[3] or 0;
        end;

        -- Determine item color
        local color = ITEM_QUALITY_COLORS[record.quality].hex;

        -- Return itemLink
        return color.."|Hbattlepet:"..record.itemid..":"..record.level..":"..record.quality..":"..health..":"..power..":"..speed..":0x0000000000000000|h["..name.."]|h|r";
    end;

-- Sorting table content
    function UberInventory_SortFilter( str, cmdline )
        -- From global to local
        local UBI_Track = UBI_Track;
        local UBI_Sorted = UBI_Sorted;
        local UBI_Items_Work = UBI_Items_Work;

        -- determine if sorting/collecting is needed
        if ( UBI_Filter.text == UBI_FILTER_TEXT and
             UBI_Filter.location == UBI_FILTER_LOCATIONS and
             UBI_Filter.quality == UBI_FILTER_QUALITY and
             UBI_Filter.class == UBI_FILTER_CLASSES and
             UBI_Filter.subclass == UBI_FILTER_SUBCLASSES and
             UBI_Filter.usable == UBI_FILTER_USABLE and
             UBI_Filter.date == UBI_SCAN_DATE ) and not UberInventoryFrame:IsVisible() then
            return;
        else
            -- Store new filter settings
            UBI_Filter = { text = UBI_FILTER_TEXT,
                           location = UBI_FILTER_LOCATIONS,
                           quality = UBI_FILTER_QUALITY,
                           class = UBI_FILTER_CLASSES,
                           subclass = UBI_FILTER_SUBCLASSES,
                           usable = UBI_FILTER_USABLE,
                           date = UBI_SCAN_DATE };
        end;

        -- Initialize globals
        wipe( UBI_Sorted );
        wipe( UBI_Track );
        wipe( UBI_Items_Work );
        UBI_Inventory_count = 0;

        -- Copy items to separate array for sorting and displaying
        local include_item;
        local subclasses;
        local function UberInventory_CopyItems( str, cmdline )
            -- Copy items to local array (including filter)
            for key, record in pairs( UBI_Items_Work ) do
                -- Initialize
                include_item = true;

                -- Count number of unique items
                if ( not UBI_Track[record.itemid] ) then
                    UBI_Inventory_count = UBI_Inventory_count + 1;
                    UBI_Track[record.itemid] = 0;
                end;

                -- Fix totalCount (only for actual characters)
                if ( record.bag_count ) then
                    record.total = record.bag_count + record.bank_count + record.mailbox_count + record.equip_count + ( record.void_count or 0 ) + ( record.reagent_count or 0 );
                end;

                -- Only apply filters when searching from then inventory frame
                if ( not cmdline ) then
                    -- Filter on location (4 = Character, 5 = Bags, 6 = Banks, 7 = Mail, 8 = Equipped, 9 = Void Storage, 10 = Reagent Bank )
					local index = UBI_FILTER_LOCATIONS_PLAYER + 1;
                    if ( ( UBI_FILTER_LOCATIONS == index and record.bag_count == 0 ) or
                         ( UBI_FILTER_LOCATIONS == index + 1 and record.bank_count == 0 ) or
                         ( UBI_FILTER_LOCATIONS == index + 2 and record.mailbox_count == 0 ) or
                         ( UBI_FILTER_LOCATIONS == index + 3 and record.equip_count == 0 ) or
                         ( UBI_FILTER_LOCATIONS == index + 4 and ( record.void_count or 0 ) == 0 ) or
                         ( UBI_FILTER_LOCATIONS == index + 5 and ( record.reagent_count or 0 ) == 0 ) ) then
                        include_item = false;
                    end;

                    -- Filter on quality
                    if ( UBI_FILTER_QUALITY > 1 and record.quality ~= UBI_FILTER_QUALITY-2 ) then
                        include_item = false;
                    end;

                    -- Filter on class
                    if ( UBI_FILTER_CLASSES > 1 and record.type ~= UBI_CLASSES[UBI_FILTER_CLASSES].name ) then
                        include_item = false;
                    end;

                    -- Filter on subclass
                    if ( UBI_FILTER_SUBCLASSES > 0 and record.subtype ~= UBI_CLASSES[UBI_FILTER_CLASSES].childs[UBI_FILTER_SUBCLASSES] ) then
                        include_item = false;
                    end;

                    -- Filter on usability
                    if ( UBI_FILTER_USABLE ) then
                        if ( not UberInventory_UsableItem( record.itemid ) ) then
                            include_item = false;
                        end;
                    end;
                end;
				
                -- Filter on name and store into structure suitable for sorting
				if ( include_item and record.name ) then
					if ( ( strfind( strlower( record.name ) , strlower( str ) ) or 0 ) > 0 ) and include_item then
						-- Insert item into sorting structure
						if ( UBI_Track[record.itemid] == 0 ) then
							tinsert( UBI_Sorted, record );
						end;

						-- Track correct item totals
						UBI_Track[record.itemid] = UBI_Track[record.itemid] + record.total;
					end;
				end;
				
            end;
        end;

        -- Set base list of items to use
        if ( cmdline or UBI_LocationList[UBI_FILTER_LOCATIONS].type == "current" ) then
            -- Current character
            UBI_Items_Work = UBI_Items;
            UberInventory_CopyItems( str, cmdline );
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "guildbank" ) then
            -- Guildbank
            UBI_Items_Work = UBI_Guildbank[UBI_LocationList[UBI_FILTER_LOCATIONS].value]["Items"];
            UberInventory_CopyItems( str, cmdline );
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "account_bank" ) then
            -- Account bank
			UBI_Items_Work = UBI_Accountbank["Items"];
            UberInventory_CopyItems( str, cmdline );
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "character" ) then
            -- Alt characters
			local character_dirty = UBI_LocationList[UBI_FILTER_LOCATIONS].value;
			local character = string.sub ( character_dirty, 1, string.find( character_dirty, "%[", 1 ) - 2);
			--UberInventory_Message( "DEBUG UberInventory_SortFilter raw: "..character, true );
			
	        -- break apart "player-realm"
		    player = string.sub ( character, 1, string.find( character, "-", 1 ) - 1 );
			realm = string.sub ( character, string.find( character, "-", 1 ) + 1, string.len( character) );
			--UberInventory_Message( "DEBUG UberInventory_SortFilter clean: "..player..":::"..realm..":::", true );
            
			UBI_Items_Work = UBI_Data[realm][player]["Items"];
            UberInventory_CopyItems( str, cmdline );
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "complete" ) then
            -- Traverse characters
            for key, value in pairs( UBI_Characters ) do
				-- break apart "player-realm"
		        player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			    realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
                
				UBI_Items_Work = UBI_Data[realm][player]["Items"];
                UberInventory_CopyItems( str, cmdline );
            end;

            -- Current character
            UBI_Items_Work = UBI_Items;
            UberInventory_CopyItems( str, cmdline );
			
			-- Account bank
			UBI_Items_Work = UBI_Accountbank["Items"];
            UberInventory_CopyItems( str, cmdline );

            -- Traverse guildbanks
            for key, value in pairs( UBI_Guildbanks ) do
                UBI_Items_Work = UBI_Guildbank[value]["Items"];
                UberInventory_CopyItems( str, cmdline );
            end;
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_guildbank" ) then
            -- Traverse guildbanks
            for key, value in pairs( UBI_Guildbanks ) do
                UBI_Items_Work = UBI_Guildbank[value]["Items"];
                UberInventory_CopyItems( str, cmdline );
            end;
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_character" ) then
            -- Current character
            UBI_Items_Work = UBI_Items;
            UberInventory_CopyItems( str, cmdline );

            -- Traverse characters
            for key, value in pairs( UBI_Characters ) do
		        -- break apart "player-realm"
		        player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			    realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
			    -- UberInventory_Message( "DEBUG LIST BUILD: "..player..":::"..realm, true );
                UBI_Items_Work = UBI_Data[realm][player]["Items"];
                UberInventory_CopyItems( str, cmdline );
            end;
        end;

        -- Sort the array alphabetically based on item name
        tsort( UBI_Sorted, function( rec1, rec2 )
                               return rec1.name < rec2.name
                           end  );
    end;

-- Reset filters
    function UberInventory_ResetFilters( button )
        -- Reset dropdown for location
        if ( button == "RightButton" ) then
            UBI_FILTER_LOCATIONS = UBI_FILTER_LOCATIONS_ALLITEMS_INDEX; -- All items
        else
            UBI_FILTER_LOCATIONS = UBI_FILTER_LOCATIONS_PLAYER; -- Current character
        end;
        UIDropDownMenu_SetText( UberInventoryFrameLocationDropDown, UBI_LocationList[UBI_FILTER_LOCATIONS].value );

        -- Reset dropdown for quality
        UBI_FILTER_QUALITY = 1;
        UIDropDownMenu_SetText( UberInventoryFrameQualityDropDown, UBI_QUALITY[UBI_FILTER_QUALITY] );

        -- Reset dropdown for class
        UBI_FILTER_CLASSES = 1;
        UBI_FILTER_SUBCLASSES = 0;
        UIDropDownMenu_SetText( UberInventoryFrameClassDropDown, UBI_ALL_CLASSES );

        -- Reset usable items
        UBI_FILTER_USABLE = false;
        UberInventoryFrameUsableItems:SetChecked( UBI_FILTER_USABLE );

        -- Reset search text (and refresh items displayed)
        if ( UBI_FILTER_TEXT == "" ) then
            UberInventory_ScrollToTop();
            UberInventory_DisplayItems();

            -- Update token info on screen
            if ( UberInventoryTokens:IsVisible() ) then
                UberInventory_DisplayTokens();
            end;
        else
            UberInventoryFrameItemSearch:SetText( "" );
        end;
    end;

-- Reset item counts
    function UberInventory_ResetCount( location )
        -- From global to local
        local UBI_Items = UBI_Items;

        -- Clear counts
        location = location.."_count";
        for key, record in pairs( UBI_Items ) do
            record[location] = 0;
        end;
    end;

-- Add sell prices to items in your bag (only used if not already at a merchant)
    function UberInventory_AddItemInfo( tooltip )
        -- Skip when user does not want information added to tooltip
        if ( not UBI_Options["show_tooltip"] ) then return; end;

        -- Set smaller font for vendor, quest and drop information
        local function SetSmallerFont()
            local numlines = tooltip:NumLines();
            local txtLeft = _G[ tooltip:GetName().."TextLeft"..numlines ];
            local txtRight = _G[ tooltip:GetName().."TextRight"..numlines ];
            txtLeft:SetFontObject( GameTooltipTextSmall );
            txtLeft:SetTextColor( 0.0, 1.0, 0.0 );
            txtRight:SetFontObject( GameTooltipTextSmall );
            txtRight:SetTextColor( 0.0, 0.7, 1.0 );
        end;

		-- Function for adding counts per location (only non-zero locations are added to the tooltip)
        local function AddLocationInfo( tooltip, bag, bank, mailbox, equipped, void, reagent, itemid )
			if ( UBI_Global_Options["Options"]["show_item_id"] ) then
				tooltip:AddDoubleLine( "|nUBI General Info", C_CYAN.."|nID: "..itemid );
			else
				tooltip:AddDoubleLine( "|nUBI General Info", "" );
			end;

            if ( bag > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[1], bag ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[1] ); end;
            if ( bank > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[2], bank ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[2] ); end;
            if ( mailbox > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[3], mailbox ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[3] ); end;
            if ( equipped > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[4], equipped ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[4] ); end;
            if ( ( void or 0 ) > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[5], void ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[5] ); end;
            if ( ( reagent or 0 ) > 0 ) then tooltip:AddDoubleLine( UBI_LOCATIONS[6], reagent ); tooltip:AddTexture( UBI_LOCATION_TEXTURE[6] ); end;
        end;

        -- Initialize
        local itemCount = 1;
        local guildCount = 0;
        local spacerAdded = false;
		local classColor;

        -- Get the itemLink
		-- local itemName, itemLink = tooltip:GetItem();
		-- print("itemLink: ", itemLink);
		local itemName, itemLink = TooltipUtil.GetDisplayedItem( tooltip );					-- 20230116 Fix for tooltip errors being thrown when using tooltip:GetItem()

        -- Does the slot contain an item
        if ( itemLink ) then
            -- Get item ID
			local _, _, itemId = strsplit( ":", itemLink );									-- 20250504 Itemlink changes (validated)
            local _, _, _, _, _, itemType, itemSubType = C_Item.GetItemInfo( itemLink );	-- 20250504 validated

            -- Get count (only if count label exists and is visible, otherwise use the value 1)
            if ( tooltip:GetName() == "ItemRefTooltip" ) then
                itemCount = 1;
--[[             else
                -- Special fix needed for Auctioneer Advanced, since this AddOn removes itembutton as soon as
                -- the mouse is over it to display a bigger button on a different location.
                -- (2009/07/28) Additional fix implemented (ticket #4)
                -- (2009/08/01) Additional fix implemented (related to Skillet)
                if ( GetMouseFocus() and GetMouseFocus():GetName() ) then
                  local objCount = _G[ GetMouseFocus():GetName().."Count" ];
                  if ( objCount and objCount:IsVisible() and objCount.GetText ) then
                      itemCount = tonumber( objCount:GetText() or "" ) or 1;
                  end;
                else
                    itemCount = 1;
                end;
--]]
            end;

            -- Get stored sell price
            local itemId_num = tonumber( itemId );
            local buyPrice, sellPrice, buyoutPrice = UberInventory_GetItemPrices( itemId_num );
            local name, area, mob, rate, count;
            local UBI_Zones = UBI_Zones;
            local totalCount = 0;

            -- Only perform the following part when it not has already been done (gets called twice for recipe related items)
            if ( not tooltip.UBI_InfoAdded or false ) then

                -- Add additional pricing information when not at a vendor
                if ( not MerchantFrame:IsVisible() or tooltip == ItemRefTooltip ) then
--[[                    
					-- Add pricing information for selling to vendors
                    if ( UBI_Options["show_sell_prices"] ) then
                        tooltip:AddLine( "|nUBI Pricing Info" );
                        if ( ( sellPrice or 0 ) == 0 ) then  -- Item unsellable
                            tooltip:AddLine( ITEM_UNSELLABLE, 1.0, 1.0, 1.0 );
                        elseif ( itemCount > 0 ) then -- Calculate sell price and add it
                            -- Add money to the tooltip
                            --tooltip:AddLine( "|n" );
                            UberInventory_SetTooltipMoney( tooltip, sellPrice * itemCount, "STATIC", UBI_ITEM_SELL, "" );
                        end;
                    end;
--]]
                    -- Add pricing information for buying recipes from vendors (mainly for auction house use)
                    local recipeData = UBI_RecipeVendors[itemId_num];
                    if ( UBI_Options["show_recipe_prices"] and recipeData ) then
                        -- Add section title (incl cash) to the tooltip
                        tooltip:AddLine( "|nUBI Recipe Vendor Info" );
                        if ( buyPrice ) then
                            tooltip:AddLine( UBI_ITEM_RECIPE_SOLD_BY:format( GetCoinTextureString( buyPrice ) ), 1.0, 1.0, 1.0 );
                        else
                            tooltip:AddLine( UBI_ITEM_RECIPE_SOLD_BY:format( "??" ), 1.0, 1.0, 1.0 );
                        end;

                        -- Add vendors to the tooltip
                        count = 0;
                        for idx, vendor in pairs( recipeData ) do
                            if ( count >= UBI_MAX_RECIPE_INFO ) then break; end;
                            name, area = strsplit( "|", UBI_Creatures[vendor] );
                            tooltip:AddDoubleLine( "  "..name, UBI_Zones[tonumber( area )] );
                            SetSmallerFont();
                            count = count + 1;
                        end;
                    end;

                    -- Add quest reward information for recipes
                    local recipeQuest = UBI_RecipeQuestRewards[itemId_num];
                    if ( UBI_Options["show_recipe_reward"] and recipeQuest ) then
                        -- Add section title to the tooltip
                        tooltip:AddLine( "|nUBI Recipe Quest Info" );
                        tooltip:AddLine( UBI_ITEM_RECIPE_REWARD_FROM, 1.0, 1.0, 1.0 );

                        -- Add quests to the tooltip
                        count = 0;
                        for idx, quest in pairs( recipeQuest ) do
                            if ( count >= UBI_MAX_RECIPE_INFO ) then break; end;
                            name, area = strsplit( "|", UBI_Quests[quest] )
                            tooltip:AddDoubleLine( "  "..name, UBI_Zones[tonumber( area )] );
                            SetSmallerFont();
                            count = count + 1;
                        end;
                    end;

                    -- Add drop information for recipes
                    local recipeDrop = UBI_RecipeDrops[itemId_num];
                    if ( UBI_Options["show_recipe_drop"] and recipeDrop ) then
                        -- Add section title to the tooltip
                        tooltip:AddLine( "|nUBI Recipe Drop Info" );
                        --tooltip:AddLine( UBI_ITEM_RECIPE_DROP_BY, 1.0, 1.0, 1.0 );

                        -- Add quests to the tooltip
                        count = 0;
                        for idx, drop in pairs( recipeDrop ) do
                            if ( count >= UBI_MAX_RECIPE_INFO ) then break; end;
                            mob, rate = strsplit( ":", drop );
                            mob = tonumber( mob );
                            rate = tonumber( rate );
                            name, area = strsplit( "|", UBI_Creatures[mob] );
                            tooltip:AddDoubleLine( "  "..name.." ("..UBI_Droprates[rate]..")", UBI_Zones[tonumber( area )] );
                            SetSmallerFont();
                            count = count + 1;
                        end;
                    end;
                end;

                -- Only display item counts when show_item_count is turned on
                if ( UBI_Options["show_item_count"] ) then
				
                    -- Add counts (if UBI_TooltipItem is populated then we are showing a tooltip from the main inventory frame)
                    if ( UBI_TooltipItem ) then
                        -- Only add the info when we are not show data from the guildbank
                        if ( UBI_TooltipItem["bag_count"] and ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "current" or
                                                                UBI_LocationList[UBI_FILTER_LOCATIONS].type == "character" ) ) then
                            -- Add full item count information
                            AddLocationInfo( tooltip,
                                             UBI_TooltipItem["bag_count"],
                                             UBI_TooltipItem["bank_count"],
                                             UBI_TooltipItem["mailbox_count"],
                                             UBI_TooltipItem["equip_count"],
                                             UBI_TooltipItem["void_count"],
                                             UBI_TooltipItem["reagent_count"],
											 itemId );
                            totalCount = totalCount + UBI_TooltipItem["bag_count"] + UBI_TooltipItem["bank_count"] + UBI_TooltipItem["mailbox_count"] + UBI_TooltipItem["equip_count"] + ( UBI_TooltipItem["void_count"] or 0 ) + ( UBI_TooltipItem["reagent_count"] or 0 );
                            spacerAdded = true;
                        end;
                    elseif ( UBI_Items[itemId] ) then
                        AddLocationInfo( tooltip,
                                         UBI_Items[itemId]["bag_count"],
                                         UBI_Items[itemId]["bank_count"],
                                         UBI_Items[itemId]["mailbox_count"],
                                         UBI_Items[itemId]["equip_count"],
                                         UBI_Items[itemId]["void_count"],
                                         UBI_Items[itemId]["reagent_count"],
										 itemId );
                        totalCount = totalCount + UBI_Items[itemId]["bag_count"] + UBI_Items[itemId]["bank_count"] + UBI_Items[itemId]["mailbox_count"] + UBI_Items[itemId]["equip_count"] + ( UBI_Items[itemId]["void_count"] or 0 ) + ( UBI_Items[itemId]["reagent_count"] or 0 );
                        spacerAdded = true;
                    end;

                    -- Add info from current character if viewing data from an alt
                    if ( UBI_Items[itemId] and UBI_TooltipLocation and UBI_LocationList[UBI_FILTER_LOCATIONS].type ~= "current" ) then
                        -- Insert spacer if not already added
                        if ( not spacerAdded ) then
                            tooltip:AddLine( "|n" );
                            spacerAdded = true;
                        end;

                        -- Add the count and icon for the current alt
                        totalCount = totalCount + UBI_Items[itemId].total;
                        tooltip:AddDoubleLine( UBI_PLAYER, UBI_Items[itemId].total );
                        tooltip:AddTexture( UBI_LOCATION_TEXTURE[7] );
                    end;

                    -- Add information for alt characters
                    local UBI_Characters = UBI_Characters;
                    local record;
                    for key, value in pairs( UBI_Characters ) do
		                -- break apart "player-realm"
		                player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			            realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
						-- UberInventory_Message( "DEBUG UberInventory_AddItemInfo: "..player..":::"..realm, true );

						-- color the text based on class
						classColor = C_WHITE;
						if ( UBI_Data[realm][player]["Options"]["class"] == "PALADIN" ) then
							classColor = C_PALADIN;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "WARRIOR" ) then
							classColor = C_WARRIOR;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "PRIEST" ) then
							classColor = C_PRIEST;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "DEATHKNIGHT" ) then
							classColor = C_DEATHKNIGHT;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "ROGUE" ) then
							classColor = C_ROGUE;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "HUNTER" ) then
							classColor = C_HUNTER;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "SHAMAN" ) then
							classColor = C_SHAMAN;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "MAGE" ) then
							classColor = C_MAGE;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "WARLOCK" ) then
							classColor = C_WARLOCK;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "MONK" ) then
							classColor = C_MONK;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "DRUID" ) then
							classColor = C_DRUID;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "DEMONHUNTER" ) then
							classColor = C_DEMONHUNTER;
						elseif ( UBI_Data[realm][player]["Options"]["class"] == "EVOKER" ) then
							classColor = C_EVOKER;
						end;
			
                        if ( UBI_Data[realm][player]["Items"][itemId] ) then
                            if ( player ~= strtrim( UBI_LocationList[UBI_TooltipLocation or 1].name ) ) then
                                -- Insert spacer if not already added
                                if ( not spacerAdded ) then
                                    tooltip:AddLine( "|n" );
                                    spacerAdded = true;
                                end;

                                -- Fix total
                                record = UBI_Data[realm][player]["Items"][itemId];
                                record.total = record.bag_count + record.bank_count + record.mailbox_count + record.equip_count + (record.void_count or 0) + (record.reagent_count or 0);
                                totalCount = totalCount + ( record.total or 0 );

                                -- Add the count and icon for the current alt
                                tooltip:AddDoubleLine( classColor..value, record.total );
								
								-- Replace faction icon with class icon if the class is known
								if ( UBI_Data[realm][player]["Options"]["class"] and UBI_Data[realm][player]["Options"]["class"] ~= "??" ) then
									local tLeft, tRight, tTop, tBottom = unpack( CLASS_ICON_TCOORDS[ UBI_Data[realm][player]["Options"]["class"] ] );
									tooltip:AddTexture( "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", tLeft, tRight, tTop, tBottom );
								end;
                            end;
                        end;
                    end;

                    -- Add information for guildbanks
                    local UBI_Guildbanks = UBI_Guildbanks;
                    for key, value in pairs( UBI_Guildbanks ) do
                        if ( UBI_Guildbank[value]["Items"][itemId] ) then
                            -- Insert spacer if not already added
                            if ( not spacerAdded ) then
                                tooltip:AddLine( "|n" );
                                spacerAdded = true;
                            end;

                            -- Add the count and icon for the current guildbank
                            totalCount = totalCount + UBI_Guildbank[value]["Items"][itemId].total;
                            tooltip:AddDoubleLine( C_GREY..value..C_CLOSE, C_GREY..UBI_Guildbank[value]["Items"][itemId].total..C_CLOSE );
                            tooltip:AddTexture( UBI_LOCATION_TEXTURE[7] );
                        end;
                    end;

					-- Add information for account bank
					if ( UBI_Accountbank["Items"][itemId] ) then
						-- Insert spacer if not already added
						if ( not spacerAdded ) then
							tooltip:AddLine( "|n" );
							spacerAdded = true;
						end;

						-- Add the count and icon for the account bank
						local val = UBI_Accountbank["Items"][itemId].total;
						totalCount = totalCount + val;
						tooltip:AddDoubleLine( C_BLUE..UBI_ACCOUNT_BANK_TITLE..C_CLOSE, C_BLUE..val..C_CLOSE );
						tooltip:AddTexture( UBI_LOCATION_TEXTURE[2] );
					end;

                    -- Add total itemcount
                    if ( totalCount > 0 ) then
                        tooltip:AddDoubleLine( " ", C_YELLOW..UBI_SIGMA_ICON.." "..totalCount..C_CLOSE );
                    end;
				
                end;
            end;
        end;

        tooltip.maxlines = tooltip:NumLines();
    end;

	function Process_OnTooltipSetItem(tooltip, data)
	
		-- The C_TooltipInfo APIs now return data with all data and line arguments surfaced, removing the need to call TooltipUtil.SurfaceArgs().
		-- TooltipUtil.SurfaceArgs(data)

--		for _, line in ipairs(data.lines) do
--			TooltipUtil.SurfaceArgs(line)
--		end
--		print("Tooltip Type: ", data.type)
--		print("Unit GUID: ", data.guid)
--		print("Unit Name: ", data.lines[1].leftText)
--		print("Unit Info: ", data.lines[2].leftText)
--		print("Unit Faction: ", data.lines[3].leftText)

		-- Only show UBI tooltip data when it is safe to do so
		if ( data.lines[1].leftText ~= "WoW Token" )
		then
			UberInventory_AddItemInfo( tooltip );
			tooltip.UBI_InfoAdded = true;
		end;

	end;

-- HOOK - Set new OnTooltipSetItem and OnHide script for Tooltip objects
    function UberInventory_HookTooltip( tooltip )
        -- From global to local
        local UBI_Hooks = UBI_Hooks;

        -- Store default script
        local tooltipName = tooltip:GetName();
		
		--UBI_Hooks["OnTooltipSetItem"][tooltipName] = tooltip:GetScript( "OnTooltipSetItem" );		-- Prior to client 100002
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, Process_OnTooltipSetItem);	-- client 100002
        UBI_Hooks["OnTooltipCleared"][tooltipName] = tooltip:GetScript( "OnTooltipCleared" );


--[[	-- Prior to client 100002
        -- Set new script to handle OntooltipSetItem
        tooltip:SetScript( "OnTooltipSetItem", function( self, ... )
            -- From global to local
            local UBI_Hooks = UBI_Hooks;

            -- Get tooltip name
            local tooltipName = self:GetName();

            -- Call default script
            if ( UBI_Hooks["OnTooltipSetItem"][tooltipName] ) then
                UBI_Hooks["OnTooltipSetItem"][tooltipName]( self, ... );
            end;

            -- Call new script (adds the item information)
            UberInventory_AddItemInfo( self );

            -- Turn on UberInventory indicator
            self.UBI_InfoAdded = true;
        end );

--]]

        -- Set new script to handle OnTooltipCleared
        tooltip:SetScript( "OnTooltipCleared", function( self, ... )
            -- From global to local
            local UBI_Hooks = UBI_Hooks;

            -- Get tooltip name
            local tooltipName = self:GetName();

            -- Force reset of fonts (maxlines is a custom attribute added within the UberInventory_AddItemInfo function)
            if ( self.maxlines ) then
                local txtLeft, txtRight;
                for i = 1, self.maxlines do
                    txtLeft = _G[self:GetName().."TextLeft"..i];
                    txtRight = _G[self:GetName().."TextRight"..i];
                    if ( txtLeft ) then txtLeft:SetFontObject( GameTooltipText ); end;
                    if ( txtRight ) then txtRight:SetFontObject( GameTooltipText ); end;
                end;
            end;

            -- Call default script
            if ( UBI_Hooks["OnTooltipCleared"][tooltipName] ) then
                UBI_Hooks["OnTooltipCleared"][tooltipName]( self, ... );
            end;

            -- Turn off UberInventory indicator
            self.UBI_InfoAdded = false;
        end );
     end;

-- Get item information and store it
    function UberInventory_Item( bagID, slotID, location )
        -- From global to local
        local UBI_Items = UBI_Items;

        -- Initialize
        local bankCount, bagCount, mailCount, equipCount, voidCount, reagentCount = 0, 0, 0, 0, 0, 0, 0;
        local itemLink = nil;
        local questItem, questID = nil, nil;
        local extra = {};

        -- Get itemLink
        if ( location == "mailbox" ) then
            itemLink = GetInboxItemLink( bagID, slotID );
            questItem, questID = C_Container.GetContainerItemQuestInfo( bagID, slotID );
        elseif ( location == "equip" ) then
            itemLink = GetInventoryItemLink( "player", slotID );
        elseif ( location == "void" ) then
            local itemID = GetVoidItemInfo( bagID, slotID );
            if ( itemID ) then
                itemLink = UberInventory_GetLink( itemID );
            end;
        else
            itemLink = C_Container.GetContainerItemLink( bagID, slotID );
            questItem, questID = C_Container.GetContainerItemQuestInfo( bagID, slotID );
        end;

        -- Retrieve item information
        if ( itemLink ) then
            -- Initialize
            local itemCount, _ = 0;

            -- Fetch item information (itemLink skipped from GetItemInfo, does not always work at this stage (Quest related items))
            local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = C_Item.GetItemInfo( itemLink );
            local _, _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId = strsplit( ":", itemLink );		-- 20250504 new 2nd attribute

            if ( location == "mailbox" ) then
                _, _, _, itemCount = GetInboxItem( bagID, slotID );
            elseif ( location == "equip" ) then
                itemCount = 1;
			elseif ( location == "void" ) then				-- 20230122 stackable items cannot be stored in void storage
                itemCount = 1;								--          so set item count to 1
            else
                local containerinfo = C_Container.GetContainerItemInfo( bagID, slotID );
				itemCount = containerinfo.stackCount;
            end;

            -- Get existing item counts or activate sorting (new item is added)
            if ( UBI_Items[itemId] ) then
                bankCount = ( UBI_Items[itemId]["bank_count"] or 0 );
                bagCount = ( UBI_Items[itemId]["bag_count"] or 0 );
                mailCount = ( UBI_Items[itemId]["mailbox_count"] or 0 );
                equipCount = ( UBI_Items[itemId]["equip_count"] or 0 );
                voidCount = ( UBI_Items[itemId]["void_count"] or 0 );
                reagentCount = ( UBI_Items[itemId]["reagent_count"] or 0 );
            end;

            -- Sort out itemCount
            if ( location == "bank" ) then
                bankCount = bankCount + itemCount;
            elseif ( location == "bag" ) then
                bagCount = bagCount + itemCount;
            elseif ( location == "mailbox" ) then
                mailCount = mailCount + ( itemCount or 0 );
            elseif ( location == "equip" ) then
                equipCount = equipCount + itemCount;
            elseif ( location == "void" ) then
                voidCount = voidCount + ( itemCount or 1 );
            elseif ( location == "reagent" ) then
                reagentCount = reagentCount + ( itemCount or 1 );
            end;
            local totalCount = bagCount + bankCount + mailCount + equipCount + ( voidCount or 0 ) + ( reagentCount or 0 );

            -- Handle Battle Pets
            if ( strfind( itemLink, "battlepet:" ) and itemId ~= 82800 ) then
                local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit( ":", itemLink );
                local name, icon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID( speciesID );

                itemName = name;
                itemQuality = tonumber( breedQuality );
                itemType = UBI_BATTLEPET_CLASS;
                itemSubType = _G["BATTLE_PET_NAME_"..petType];
                itemLevel = level;
                extra = { maxHealth, power, speed };
            end;

            -- Store the item information
            UBI_Items[itemId] = { ["itemid"] = tonumber( itemId ),
                                  ["name"] = itemName,
                                  ["quality"] = itemQuality,
                                  ["level"] = itemLevel,
                                  ["bag_count"] = bagCount,
                                  ["bank_count"] = bankCount,
                                  ["mailbox_count"] = mailCount,
                                  ["equip_count"] = equipCount,
                                  ["void_count"] = voidCount,
                                  ["reagent_count"] = reagentCount,
                                  ["type"] = itemType,
                                  ["subtype"] = itemSubType,
                                  ["total"] = totalCount,
                                  ["qitem"] = questItem,
                                  ["qid"] = questID,
                                  ["extra"] = extra
                                  };
        end;
    end;

-- Handle Bag items
    function UberInventory_Save_Bag()
        if ( not UBI_ACTIVE ) then return; end;

        -- Initialize
        local slotCount, freeCount = 0, 0;

        -- Reset bag counts
        UberInventory_ResetCount( "bag" );

        -- Traverse bags
        --for bagID = 0, 4 do
		for bagID = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1 do
            if ( C_Container.GetContainerNumSlots( bagID ) ) then
                slotCount = slotCount + C_Container.GetContainerNumSlots( bagID );
                freeCount = freeCount + C_Container.GetContainerNumFreeSlots( bagID );
                for slotID = 1, C_Container.GetContainerNumSlots( bagID ) do
                    UberInventory_Item( bagID, slotID, "bag" );
                end;
            end;
        end;

        -- Save slot count
        UBI_Options["bag_max"] = slotCount;
        UBI_Options["bag_free"] = freeCount;
    end;

-- Handle Void Storage
    function UberInventory_Save_VoidStorage( event )
        if ( not UBI_ACTIVE ) then return; end;

        -- Reset void storage counts
        UberInventory_ResetCount( "void" );

        -- Traverse void storage slots
        for tabID = 2, 1, -1 do
            for voidID = 1, 80 do
                UberInventory_Item( tabID, voidID, "void" );
            end;
        end;

        -- Update inventory frame if visible
        if ( UberInventoryFrame:IsVisible() ) then
            UberInventory_DisplayItems();
        end;
    end;

-- Handle Reagent Bank items
    function UberInventory_Save_ReagentBank()
        if ( not UBI_ACTIVE ) then return; end;

		if ( UBI_BANK_OPEN ) then					-- v100002 - REAGENTBANK_CONTAINER only available at the bank
			-- Intialize
			local slotCount, freeCount = 0, 0;

			-- Reset reagent bank counts
			UberInventory_ResetCount( "reagent" );

			-- Traverse reagent bag
			if ( C_Container.GetContainerNumSlots( REAGENTBANK_CONTAINER ) ) then
				slotCount = C_Container.GetContainerNumSlots( REAGENTBANK_CONTAINER );
				for slotID = 1, C_Container.GetContainerNumSlots( REAGENTBANK_CONTAINER ) do
					if ( not C_Container.GetContainerItemLink( REAGENTBANK_CONTAINER, slotID ) ) then
						freeCount = freeCount + 1;
					end;

					UberInventory_Item( REAGENTBANK_CONTAINER, slotID, "reagent" );
				end;
			end;

			-- Save slot count
			UBI_Options["reagent_max"] = slotCount;
			UBI_Options["reagent_free"] = freeCount;

			-- Update inventory frame if visible
			if ( UberInventoryFrame:IsVisible() ) then
				UberInventory_DisplayItems();
			end;
		end;
    end;

-- Handle Bank items
    function UberInventory_Save_Bank()
        if ( not UBI_ACTIVE ) then return; end;

        -- Intialize
        local slotCount, freeCount = 0, 0;

        if ( UBI_BANK_OPEN ) then
            -- Reset bank counts
            UberInventory_ResetCount( "bank" );

            -- Traverse bank slots
            slotCount = C_Container.GetContainerNumSlots( BANK_CONTAINER );
            for slotID = 1, C_Container.GetContainerNumSlots( BANK_CONTAINER ) do
                if ( not C_Container.GetContainerItemLink( BANK_CONTAINER, slotID ) ) then
                    freeCount = freeCount + 1;
                end;
				UberInventory_Item( BANK_CONTAINER, slotID, "bank" );
            end;

            -- Traverse bank bags
            --for bagID = 5, 11 do
			for bagID = NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS do
                if ( C_Container.GetContainerNumSlots( bagID ) ) then
                    slotCount = slotCount + C_Container.GetContainerNumSlots( bagID );
                    freeCount = freeCount + C_Container.GetContainerNumFreeSlots( bagID );
                    for slotID = 1, C_Container.GetContainerNumSlots( bagID ) do
                        UberInventory_Item( bagID, slotID, "bank" );
                    end;
                end;
            end;

            -- Save slot count
            UBI_Options["bank_max"] = slotCount;
            UBI_Options["bank_free"] = freeCount;
			
			-- Update account bank now that the bank window is open
			UberInventory_Save_AccountBank();
        end;
    end;
	
	
	-- Warband Bank / Warbank
	-- https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes
	function UberInventory_Save_AccountBank()
	    if ( not UBI_ACTIVE ) then return; end;

		local slotCount, freeCount, itemCount = 0, 0, 0;
		local UBI_Accountbank = UBI_Accountbank;
		--UberInventory_Message( "DEBUG UberInventory_Save_AccountBank: Start of function" );
		
		if ( UBI_BANK_OPEN ) then
		    -- Clear the existing data
            wipe( UBI_Accountbank["Items"] );

			-- Traverse account bank tabs
			for AccountTabID = Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_5 do
				if ( C_Container.GetContainerNumSlots( AccountTabID ) ) then
					slotCount = slotCount + C_Container.GetContainerNumSlots( AccountTabID );
					freeCount = freeCount + C_Container.GetContainerNumFreeSlots( AccountTabID );
					--UberInventory_Message( "DEBUG UberInventory_Save_AccountBank: Tab = "..AccountTabID.."  Slotcount = "..slotCount.."  Freecount = "..freeCount, true );
					for slotID = 1, slotCount do
						itemCount = 0;
						local itemLink = C_Container.GetContainerItemLink( AccountTabID, slotID );

						if ( itemLink ) then
                            -- Fetch item information
                            local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = C_Item.GetItemInfo( itemLink );
                            local _, _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId = strsplit( ":", itemLink );			-- 20250504 new 2nd attribute
							local containerinfo = C_Container.GetContainerItemInfo( AccountTabID, slotID );
							local count = containerinfo.stackCount;
							
							-- Get existing item count
                            if ( UBI_Accountbank["Items"][itemId] ) then
                                itemCount = UBI_Accountbank["Items"][itemId]["count"];
                            end;
							
							-- Handle Battle Pets
                            if ( strfind( itemLink, "battlepet:" ) ) then
                                local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit( ":", itemLink );
                                local name, icon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID( speciesID );

                                itemName = name;
                                itemQuality = tonumber( breedQuality );
                                itemType = UBI_BATTLEPET_CLASS;
                                itemSubType = _G["BATTLE_PET_NAME_"..petType];
                                itemLevel = level;
                                extra = { maxHealth, power, speed };
                            end;

							--UberInventory_Message ( "DEBUG Tab: "..AccountTabID.."  Slot: "..slotID.."  Name: "..itemName.."  ID: "..itemId.."  Qty: "..count );
							
							-- Store the item information
                            UBI_Accountbank["Items"][itemId] = { ["itemid"] = tonumber( itemId ),
                                                                 ["name"] = itemName,
                                                                 ["quality"] = itemQuality,
                                                                 ["level"] = itemLevel,
                                                                 ["count"] = itemCount + count,
                                                                 ["type"] = itemType,
                                                                 ["subtype"] = itemSubType,
                                                                 ["extra"] = extra,
                                                                 ["total"] = itemCount + count };
						end;
					end;
				end;
			end;
			
			-- Store slot counts
			UBI_Accountbank["SlotCount"] = slotCount;
			UBI_Accountbank["FreeSlotCount"] = freeCount;
		end;
		
		-- Store account bank cash
		amount = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		UBI_Accountbank["Cash"] = amount;
		--UberInventory_Message ( "DEBUG Cash: "..amount );
		
		-- Update inventory frame if visible
		if ( UberInventoryFrame:IsVisible() ) then
			UberInventory_DisplayItems();
		end;
		
		--UberInventory_Message( "DEBUG UberInventory_Save_AccountBank: End of function" );
		
	end;


-- Handle Mailbox items
    function UberInventory_Save_Mailbox()
        if ( not UBI_ACTIVE ) then return; end;

        -- Initialize
        local today = time( UberInventory_GetDateTime() );
        local UBI_Options = UBI_Options;
        local UBI_Money = UBI_Money;
        local mailSender, mailSubject, cashAttached, daysLeft, itemAttached, _;
        local mailText, mailTexture, mailTakeable, mailInvoice;
        local invoiceType, bid, buyout, deposit, consignment;

        if ( UBI_MAILBOX_OPEN ) then
            -- Reset mailbox cash
            UBI_Money["mail"] = 0;

            -- Reset expiration date
            if ( UBI_Options["mail_expires"] ) then wipe( UBI_Options["mail_expires"] ) else UBI_Options["mail_expires"] = {}; end;

            -- Reset mailbox counts
            UberInventory_ResetCount( "mailbox" );

            -- Get number of mails in inbox
            local numItems = GetInboxNumItems();

            -- Traverse mailbox (Reverse order)
            for mailID = numItems, 1, -1 do
                -- Mail info
                _, _, mailSender, mailSubject, cashAttached, _, daysLeft, itemAttached = GetInboxHeaderInfo( mailID );
                daysLeft = today + ( floor( daysLeft ) * UBI_SEC_IN_DAY );

                -- Register all mails stored in mailbox stored by expiration date (exclude sales pending mails)
                if ( itemAttached or cashAttached > 0 ) then
                    UBI_Options["mail_expires"][daysLeft] = ( UBI_Options["mail_expires"][daysLeft] or 0 ) + 1;
                end;

                -- Handle attachment
                if ( itemAttached ) then
                    for attachID = 1, ATTACHMENTS_MAX_RECEIVE do
                        UberInventory_Item( mailID, attachID, "mailbox" );
                    end;
                end;

                -- Handle money
                if ( cashAttached > 0 ) then
                    if ( UBI_Options["take_money"] ) then
                        -- Add task to take inbox money (if not items are attached this also deletes the mail)
                        TaskHandlerLib:AddTask( "UberInventory", UBI_Task_CollectCash, mailID );
                    end;

                    -- Record the mailbox cash
                    UBI_Money["mail"] = UBI_Money["mail"] + cashAttached;
                end;

                -- Update wallet/mail info (if mainframe is shown)
                UberInventory_WalletMailCashInfo();
            end;

            -- Reregister MAIL_INBOX_UPDATE event
            UBI:RegisterEvent( "MAIL_INBOX_UPDATE" );
        end;
    end;

-- Handle Equiped items
    function UberInventory_Save_Equipped()
        if ( not UBI_ACTIVE ) then return; end;

        -- Initialize
        local slotID, _;

        -- Reset Equiped counts
        UberInventory_ResetCount( "equip" );

        -- Traverse equip slots
        for key, value in pairs( UBI_EQUIP_SLOTS ) do
            slotID, _ = GetInventorySlotInfo( value );
            UberInventory_Item( nil, slotID, "equip" );
        end;
    end;

-- Handle Guildbank items
    function UberInventory_Save_Guildbank( event )
        if ( not UBI_ACTIVE ) then return; end;

        -- Exit if tracking is turned off
        if ( not UBI_Options["track_gb_data"] ) then return; end;

        -- Exit if already saving gb data
        if ( UBI_PROCESSING_GB ) then return; end;

        -- From global to local
        local UBI_Guildbank = UBI_Guildbank;

        -- Initialize
        local itemCount = 0;
        local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals, count, itemLink, _;
        local itemName, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture;
        local itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId;

        if ( UBI_GUILDBANK_OPENED ) then
            -- indicate we are already saving gb data
            UBI_PROCESSING_GB = true;

            -- Start out to assume we have view access to all guildbank tabs
            UBI_GUILDBANK_VIEWACCESS = true;

            -- Clear the existing data
            wipe( UBI_Guildbank[UBI_GUILD]["Items"] );

            -- Traverse guild bank tabs/slots to store into UberInventory
            for gbTab = 1, GetNumGuildBankTabs() do
                -- Can we view the content of all guildbank tabs?
                --   isViewable = true;
                local name, icon, isViewable = GetGuildBankTabInfo( gbTab );
                if ( not isViewable ) then
                    UBI_GUILDBANK_VIEWACCESS = false;
                end;

                -- Only collect when tab is viewable (to prevent messages in chat)
                if ( isViewable ) then

                    for gbSlot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
                        -- Reset
                        itemCount = 0;

                        -- Get slot information
                        _, count, _ = GetGuildBankItemInfo( gbTab, gbSlot );
                        itemLink = GetGuildBankItemLink( gbTab, gbSlot );

                        if ( itemLink ) then
                            -- Fetch item information
                            itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = C_Item.GetItemInfo( itemLink );
                            _, _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId = strsplit( ":", itemLink );		-- 20250504 new 2nd attribute

                            -- Get existing item count
                            if ( UBI_Guildbank[UBI_GUILD]["Items"][itemId] ) then
                                itemCount = UBI_Guildbank[UBI_GUILD]["Items"][itemId]["count"];
                            end;

                            -- Handle Battle Pets
                            if ( strfind( itemLink, "battlepet:" ) ) then
                                local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit( ":", itemLink );
                                local name, icon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID( speciesID );

                                itemName = name;
                                itemQuality = tonumber( breedQuality );
                                itemType = UBI_BATTLEPET_CLASS;
                                itemSubType = _G["BATTLE_PET_NAME_"..petType];
                                itemLevel = level;
                                extra = { maxHealth, power, speed };
                            end;

                            -- Store the item information
                            UBI_Guildbank[UBI_GUILD]["Items"][itemId] = { ["itemid"] = tonumber( itemId ),
                                                                          ["name"] = itemName,
                                                                          ["quality"] = itemQuality,
                                                                          ["level"] = itemLevel,
                                                                          ["count"] = itemCount + count,
                                                                          ["type"] = itemType,
                                                                          ["subtype"] = itemSubType,
                                                                          ["extra"] = extra,
                                                                          ["total"] = itemCount + count };
                        end;
                    end;
                end;

            end;

            -- Done saving gb data
            UBI_PROCESSING_GB = false;
        end;

        -- Store guildbank cash
        UBI_Guildbank[UBI_GUILD]["Cash"] = GetGuildBankMoney();

        -- Rebuild list of guildbanks
        UberInventory_GetGuildbanks();

        -- Update inventory frame if visible
        if ( UberInventoryFrame:IsVisible() ) then
            UberInventory_DisplayItems();
        end;
    end;

-- Handle Guildbank items
    function UberInventory_Receive_Guildbank()
        -- From global to local
        local UBI_Guildbank = UBI_Guildbank;
        local UBI_GBData = UBI_GBData;

        -- Exit if tracking is turned off
        if ( not UBI_Options["track_gb_data"] ) then return; end;

        -- Init guildbank structures (if needed)
        UberInventory_Guildbank_Init()

        -- Show receiving data
        UberInventory_Message( UBI_NEW_GBDATA:format( UBI_GBSender ), true );

        -- Clear the existing data
        wipe( UBI_Guildbank[UBI_GUILD]["Items"] );

        -- Traverse all guildbank tabs and slots
        local itemLink, itemName, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, _;
        for key, value in pairs( UBI_GBData ) do
            -- Fetch item information
            itemLink = UberInventory_GetLink( value.itemid );
            itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = C_Item.GetItemInfo( itemLink );

            -- Store the item information
            UBI_Guildbank[UBI_GUILD]["Items"][value.itemid] = { ["itemid"] = tonumber( value.itemid ),
                                                                ["name"] = value.name or itemName or UBI_ITEM_UNCACHED,
                                                                ["quality"] = value.quality or itemQuality,
                                                                ["level"] = value.level or itemLevel or 0,
                                                                ["count"] = value.count,
                                                                ["type"] = value.type or itemType or UBI_ITEM_UNCACHED,
                                                                ["subtype"] = value.subtype or itemSubType or UBI_ITEM_UNCACHED,
                                                                ["total"] = value.count };

            if ( value.extra ) then
            end;
        end;

        -- Update inventory frame if visible
        if ( UberInventoryFrame:IsVisible() ) then
            -- Update items
            UberInventory_DisplayItems();

            -- Update slot count information
            UberInventory_Update_SlotCount();
        end;

        -- Track Guildbank last visit date/time
        UBI_Options["guildbank_visit"] = UberInventory_GetDateTime();

        -- Clear sender
        UBI_GBSender = nil;
    end;

-- Send Guildbank data to other guild members
    function UberInventory_Send_Guildbank()
        -- From global to local
        local UBI_Guildbank = UBI_Guildbank;
        local sendData;

        -- Get number of online guild members
        local numTotal, numOnline = GetNumGuildMembers();

        -- Exit if tracking is turned off
        if ( not UBI_Options["track_gb_data"] ) then return; end;

        -- Only send data when we have view access to all guildbank tabs
        if ( UBI_GUILDBANK_VIEWACCESS and numOnline > 1 ) then
            -- Show message
            UberInventory_Message( UBI_GB_SENDING, true );

            -- Send start message
            TaskHandlerLib:AddTask( "UberInventory", UBI_Task_SendMessage, "GBSTART", UBI_VERSION );

            -- Send the actual guildbank data
            for key, record in pairs( UBI_Guildbank[UBI_GUILD]["Items"] ) do
                -- Create data string
                sendData = key.." "..
                           record["count"].." "..
                           strgsub( record["name"], " ", "_" ).." "..
                           strgsub( record["type"], " ", "_" ).." "..
                           strgsub( record["subtype"], " ", "_" ).." "..
                           record["level"].." "..
                           record["quality"];

                -- Send data string
                TaskHandlerLib:AddTask( "UberInventory", UBI_Task_SendMessage, "GBITEM", sendData );
            end;

            -- Send cash
            TaskHandlerLib:AddTask( "UberInventory", UBI_Task_SendMessage, "GBCASH", UBI_Guildbank[UBI_GUILD]["Cash"] );

            -- Send done message
            TaskHandlerLib:AddTask( "UberInventory", UBI_Task_SendMessage, "GBEND" );
        end;
    end;

-- Check for expiring mails (only when the option warn_mailexpire is on)
    function UberInventory_MailExpirationCheck()
        -- From global to local
        local UBI_Data = UBI_Data;
        local realm, daysLeft;

        if ( UBI_Options["warn_mailexpire"] ) then
		    UberInventory_Message(UBI_MAIL_CHECK_MESSAGE, true );
			
            -- Check mail expiration for all characters from the current realm
            for key, record in pairs( UBI_Data ) do
                realm = key;

                for player, value in pairs( UBI_Data[realm] ) do
                    if ( player ~= "Guildbank" and value["Options"]["mail_expires"] ) then
                        for key, record in pairs( value["Options"]["mail_expires"] ) do
                            -- Get number of days till expiration (negative number are good)
                            daysLeft = UberInventory_DaysSince( key );

                            -- If daysleft less then zero, mail expires into the future, positive numbers means the mail are already expired
                            if ( daysLeft < 0 ) then
                                daysLeft = abs( daysLeft );
                                if ( daysLeft <= UBI_MAIL_EXPIRE_WARNING ) then
                                    UberInventory_Message( UBI_MAIL_EXPIRES:format( player, realm, record, daysLeft ), true );
                                end;
                            else
								if ( daysLeft <= UBI_MAIL_EXPIRE_CUTOFF ) then
									UberInventory_Message( UBI_MAIL_LOST:format( player, realm, record, daysLeft ), true );
								end;
                            end;
                        end;
                    end;
                end;
            end;
		end;
    end;

-- v9.0 Not called temporarily due to AceGUI not being updated for Shadowlands at time of writing	
-- Check for expiring mails - dialog version
    function UberInventory_MailExpirationCheck_Dialog()	
			-- Main frame
		local frame = AceGUI:Create( "Frame" );
		frame:SetTitle( "Mail Expiration" );
		frame:SetWidth( 400 );
		frame:SetHeight( 300 );
		frame:SetStatusText( "Mail Expiration Status" )
		frame:SetCallback( "OnClose", function(widget) AceGUI:Release(widget) end )
		frame:SetLayout( "Fill" )
	    
		-- Add scrolling
		scrollcontainer = AceGUI:Create( "SimpleGroup" ) -- "InlineGroup" is also good  (org ScrollGroup)
		scrollcontainer:SetFullWidth( true )
		scrollcontainer:SetFullHeight( true )
		scrollcontainer:SetLayout( "Fill" )
		frame:AddChild( scrollcontainer )
		
		scroll = AceGUI:Create( "ScrollFrame" )
		scroll:SetLayout( "Flow" )
		scrollcontainer:AddChild( scroll )

        local realm, daysLeft, mailExpireString, iCritical;
		mailExpireString = "";
		iCritical = 0;

 	    for key, record in pairs( UBI_Data ) do
			realm = key;

			for player, value in pairs( UBI_Data[realm] ) do
				if ( player ~= "Guildbank" and value["Options"]["mail_expires"] ) then
					for key, record in pairs( value["Options"]["mail_expires"] ) do
						-- Get number of days till expiration (negative number are good)
						daysLeft = UberInventory_DaysSince( key );

						-- If daysleft less then zero, mail expires into the future, positive numbers means the mail are already expired
						if ( daysLeft < 0 ) then
						    daysLeft = abs( daysLeft );
                            if ( daysLeft <= UBI_MAIL_EXPIRE_WARNING ) then
								iCritical = iCritical + 1;
							    mailExpireString = mailExpireString .. C_RED .. "!!! ";
							end;
						        mailExpireString = mailExpireString .. UBI_MAIL_EXPIRES_LISTBOX:format( player, realm, record, daysLeft ) .. C_CLOSE .. "\n";
						else
							if ( daysLeft <= UBI_MAIL_EXPIRE_CUTOFF ) then
								mailExpireString = mailExpireString .. UBI_MAIL_LOST:format( player, realm, record, daysLeft ) .. C_CLOSE .. "\n";
							end;
						end;
					end;
				end;
			end;
		end;
		
		if ( mailExpireString == "" ) then
		    mailExpireString = UBI_MAIL_EMPTY;
		end;

		frame:SetStatusText( UBI_CRITICAL_MAIL_STATUS .. iCritical );
		
		-- List mail expirations
		local label1 = AceGUI:Create( "Label" )
		label1:SetFullWidth( true )
		label1:SetText( mailExpireString )
		scroll:AddChild( label1 )
		
		-- Perform chatbox critical expiration output
		UberInventory_MailExpirationCheck();
	end;
		

-- Cleanup inventory
    function UberInventory_Cleanup()
        -- From global to local
        local UBI_Items = UBI_Items;

        -- Remove items for which bag_count, bank_count, mailbox_count and equip_count equals 0
        for key, record in pairs( UBI_Items ) do
            if ( record.name ) then
                if ( record.bag_count + record.bank_count + record.mailbox_count + record.equip_count + ( record.void_count or 0 ) + ( record.reagent_count or 0 ) == 0 ) then
                    -- Remove the item
                    UBI_Items[key] = nil;
                end;
            else
                -- Remove the item if name is not found
                UBI_Items[key] = nil;
            end;
        end;
    end;

-- Update inventory
    function UberInventory_UpdateInventory( location )
        -- Update the inventory
        if ( location == "bank" or location == "all" ) then
            UberInventory_Save_Bank();
        end;
        if ( location == "accountbank" or location == "all" ) then
            UberInventory_Save_AccountBank();
        end;
        if ( location == "bag" or location == "all" ) then
            UberInventory_Save_Bag();
        end;
        if ( location == "mail" or location == "all" ) then
            UberInventory_Save_Mailbox();
        end;
        if ( location == "equip" or location == "all" ) then
            UberInventory_Save_Equipped();
        end;
        if ( location == "reagent" or location == "all" ) then
            UberInventory_Save_ReagentBank();
        end;

        -- Store last update info
        UBI_SCAN_DATE = time();

        -- Cleanup the inventory (remove zero-count items)
        UberInventory_Cleanup();

        -- Get cash information
        UberInventory_SaveMoney();

        -- Update wallet/mail info (if mainframe is shown)
        UberInventory_WalletMailCashInfo();

        -- Update inventory frame if visible
        if ( UberInventoryFrame:IsVisible() ) then
            -- Update items
            UberInventory_DisplayItems();

            -- Update token info on screen
            if ( UberInventoryTokens:IsVisible() ) then
                UberInventory_DisplayTokens();
            end;

            -- Update slot count information
            UberInventory_Update_SlotCount();
        end;
    end;

-- Handle UBI initialization
    function UberInventory_Init()
        -- Initiliaze SavedVariables
        if ( UBI_Data == nil ) then
            UBI_Data = {};
        end;

        if ( UBI_Accountbank_Data == nil ) then
            UBI_Accountbank_Data = {};
        end;
		
		if ( UBI_Global_Options == nil ) then
		    UBI_Global_Options = {};
		end;

        if ( UBI_Data[UBI_REALM] == nil ) then
            UBI_Data[UBI_REALM] = {};
        end;

        if ( UBI_Data[UBI_REALM][UBI_PLAYER] == nil ) then
            UBI_Data[UBI_REALM][UBI_PLAYER] = {};
        end;

        if ( UBI_Data[UBI_REALM][UBI_PLAYER]["Options"] == nil ) then
            UBI_Data[UBI_REALM][UBI_PLAYER]["Options"] = { ["version"] = UBI_VERSION,
														   ["show_money"] = UBI_Defaults["show_money"],
                                                           ["show_balance"] = UBI_Defaults["show_balance"],
                                                           ["show_tooltip"] = UBI_Defaults["show_tooltip"],
                                                           ["show_item_count"] = UBI_Defaults["show_item_count"],
                                                           ["show_recipe_prices"] = UBI_Defaults["show_recipe_prices"],
                                                           ["show_recipe_reward"] = UBI_Defaults["show_recipe_reward"],
                                                           ["show_recipe_drop"] = UBI_Defaults["show_recipe_drop"],
                                                           ["show_highlight"] = UBI_Defaults["show_highlight"],
                                                           ["track_gb_data"] = UBI_Defaults["track_gb_data"],
                                                           ["send_gb_data"] = UBI_Defaults["send_gb_data"],
                                                           ["receive_gb_data"] = UBI_Defaults["receive_gb_data"],
                                                           ["warn_mailexpire"] = UBI_Defaults["warn_mailexpire"],
                                                           ["bag_max"] = 0,
                                                           ["bag_free"] = 0,
                                                           ["bank_max"] = 0,
                                                           ["bank_free"] = 0,
                                                           ["reagent_max"] = 0,
                                                           ["reagent_free"] = 0,
                                                           ["alpha"] = UBI_Defaults["alpha"],
                                                           ["take_money"] = UBI_Defaults["take_money"],
                                                           ["faction"] = UBI_FACTION,
                                                           ["mail_expires"] = {},
                                                           ["level"] = UnitLevel( "player" ),
                                                           ["class"] = select( 2, UnitClass( "player" ) ),
														   ["player_realm"] = UBI_PLAYER.."-"..UBI_REALM,
                                                         };
        end;
		
		if ( UBI_Global_Options["Options"] == nil ) then
		    UBI_Global_Options["Options"] = { ["sell_greys"] = UBI_Defaults["sell_greys"],
			                                  ["autorepair_self"] = UBI_Defaults["autorepair_self"],
											  ["ignore_realm"] = UBI_Defaults["ignore_realm"],
											  ["patch_message_version"] = UBI_Defaults["patch_message_version"],
											  ["show_item_id"] = UBI_Defaults["show_item_id"],
			                                };
		end;

		-- Added 11.0.7.2
		if ( UBI_Global_Options["Options"]["show_item_id"] == nil ) then
			UberInventory_Message(C_CYAN.."Upgrading Database:|n"..
								  C_YELLOW.."> Adding *Show Item ID* to UBI options.", true);
		    UBI_Global_Options["Options"]["show_item_id"] = UBI_Defaults["show_item_id"];
		end;

        if ( UBI_Data[UBI_REALM][UBI_PLAYER]["Items"] == nil ) then
            UBI_Data[UBI_REALM][UBI_PLAYER]["Items"] = {};
        end;

        if ( UBI_Data[UBI_REALM][UBI_PLAYER]["Money"] == nil ) then
            UBI_Data[UBI_REALM][UBI_PLAYER]["Money"] = { ["mail"] = 0,
                                                         ["Cash"] = 0,
                                                         ["Currencies"] = {} };
        end;

		if ( UBI_Data[UBI_REALM]["Guildbank"] == nil ) then
            UBI_Data[UBI_REALM]["Guildbank"] = {};
        end;

		-- Initialize account bank data structure
        if ( UBI_Accountbank_Data["Accountbank"] == nil ) then
            UBI_Accountbank_Data["Accountbank"] = {};
			UBI_Accountbank_Data["Accountbank"]["Items"] = {};
			UBI_Accountbank_Data["Accountbank"]["Cash"] = 0;
			UBI_Accountbank_Data["Accountbank"]["SlotCount"] = 0;
			UBI_Accountbank_Data["Accountbank"]["FreeSlotCount"] = 0;
        end;
		
        -- Create global variables for easy reference
        UBI_Money = UBI_Data[UBI_REALM][UBI_PLAYER]["Money"];
        UBI_Items = UBI_Data[UBI_REALM][UBI_PLAYER]["Items"];
        UBI_Options = UBI_Data[UBI_REALM][UBI_PLAYER]["Options"];
        UBI_Guildbank = UBI_Data[UBI_REALM]["Guildbank"];
		UBI_Accountbank = UBI_Accountbank_Data["Accountbank"];

        -- Upgrade data structures
        UberInventory_Upgrade();
		
        -- Set faction again, to allow for faction change
        UBI_Options["faction"] = UBI_FACTION;

        -- Build list of alts and guildbanks
        UberInventory_GetAlts();
        UberInventory_GetGuildbanks();

        -- Build the inventory
        UberInventory_UpdateInventory( "all" );

        -- Build list for locations
        UberInventory_Build_Locations();

        -- Initialize Options dialog
        UberInventory_AddCategory( UberInventoryOptionsFrame );

        -- Force refersh of stored currencies
        UberInventory_Save_Currencies();

        UBI:RegisterEvent( "BAG_UPDATE" );

    end;

-- Initialize guildbank data structure
    function UberInventory_Guildbank_Init()
        if ( IsInGuild() and UBI_Options["track_gb_data"] ) then
            if ( UBI_GUILD and not UBI_Guildbank[UBI_GUILD] ) then
                UBI_Guildbank[UBI_GUILD] = {};
                UBI_Guildbank[UBI_GUILD]["Items"] = {};
                UBI_Guildbank[UBI_GUILD]["Cash"] = 0;
                UBI_Guildbank[UBI_GUILD]["Faction"] = UBI_FACTION;
            end;
        end;
    end;

-- Register events
    function UberInventory_RegisterEvents()
        for key, value in pairs( UBI_TRACKED_EVENTS ) do
            UBI:RegisterEvent( value );
        end;
    end;

-- Register events
    function UberInventory_UnregisterEvents()
        for key, value in pairs( UBI_TRACKED_EVENTS ) do
            UBI:UnregisterEvent( value );
        end;
    end;

-- Handle startup of the addon
    function UberInventory_OnLoad()
        -- Install hooks
        UberInventory_Install_Hooks();

        -- Show startup message
        UberInventory_Message( UBI_STARTUP_MESSAGE, false );

        -- Register slash commands
        SlashCmdList["UBI"] = UberInventory_SlashHandler;
        SLASH_UBI1 = "/ubi";
        SLASH_UBI2 = "/uberinventory";

        -- Register events to be monitored
        UberInventory_RegisterEvents();

        -- Correct quality list
        tinsert( UBI_QUALITY, 1, UBI_ALL_QUALITIES );
				
		-- Update inventory after 90s - resolves taint issues from addons such as CanIMogIt
		C_Timer.After( 90, function() UberInventory_UpdateInventoryNewLoad() end );
    end;

-- Install all of the hooks used by UberInventory
    function UberInventory_Install_Hooks()
        -- Hook the Tooltips (OnTooltipSetItem, OnTooltipCleared)
        UberInventory_HookTooltip( GameTooltip );
        UberInventory_HookTooltip( ItemRefTooltip );
        UberInventory_HookTooltip( ShoppingTooltip1 );
        UberInventory_HookTooltip( ShoppingTooltip2 );

        -- Hook mail stuff
        UBI_Hooks["ReturnInboxItem"] = ReturnInboxItem;
        ReturnInboxItem = UberInventory_ReturnInboxItem;
        UBI_Hooks["SendMail"] = SendMail;
        SendMail = UberInventory_SendMail;
		
		-- v10.0.2 hook for guild bank
		
    end;

-- Track mails returned to (current account) characters
    function UberInventory_ReturnInboxItem( mailID )
        local _, _, mailSender, mailSubject, cashAttached, _, daysLeft, itemAttached = GetInboxHeaderInfo( mailID );

        wipe( UBI_Mail_Transfer );
        UBI_Mail_Transfer.to = mailSender;
        UBI_Mail_Transfer.cash = cashAttached;
        UBI_Mail_Transfer.items = {};

        for attachID = 1, ATTACHMENTS_MAX_RECEIVE do
            local itemName, _, _, itemCount = GetInboxItem( mailID, attachID );
            if ( itemName ) then
                local _, itemId = strsplit( ":", GetInboxItemLink( mailID, attachID ) );
                UBI_Mail_Transfer.items[itemId] = ( UBI_Mail_Transfer.items[itemId] or 0 ) + ( itemCount or 0 );
            end;
        end;

        if ( UBI_Hooks["ReturnInboxItem"] ) then
            UBI_Hooks["ReturnInboxItem"]( mailID );
        end;
    end;

-- Track mails sent to (current account) characters
    function UberInventory_SendMail( to, subject, body )
        wipe( UBI_Mail_Transfer );
        UBI_Mail_Transfer.to = to;
        UBI_Mail_Transfer.cash = GetSendMailMoney();
        UBI_Mail_Transfer.items = {};

        for i = 1, ATTACHMENTS_MAX_SEND do
            local itemName, _, itemTexture, itemCount = GetSendMailItem( i );			-- 9.0.2.2 - itemID return added between name and texture (itemCount fix)
            if ( itemName ) then
                local _, itemId = strsplit( ":", GetSendMailItemLink( i ) );
                UBI_Mail_Transfer.items[itemId] = ( UBI_Mail_Transfer.items[itemId] or 0 ) + itemCount;
            end;
        end;

        if ( UBI_Hooks["SendMail"] ) then
            UBI_Hooks["SendMail"]( to, subject, body );
        end;
    end;

-- Transfer gold/items between characters
    function UberInventory_Transfer()
        if ( UBI_Mail_Transfer.to ) then
            if ( UBI_Data[UBI_REALM][UBI_Mail_Transfer.to] ) then
                -- Determine expiration date/time of transfered cash/items
                local daysLeft = time( UberInventory_GetDateTime() ) + ( 30 * UBI_SEC_IN_DAY );

                -- Transfer cash
                UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Money"]["mail"] = ( UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Money"]["mail"] or 0 ) + UBI_Mail_Transfer.cash;

                -- Transfer items
                local itemName, itemLink, itemQuality, itemLevel, itemClass, itemSubclass, tempItem, _;
                local itemCount = 0;
                for key, value in pairs( UBI_Mail_Transfer.items ) do
                    itemName, itemLink, itemQuality, itemLevel, _, itemClass, itemSubclass = C_Item.GetItemInfo( key );
                    tempItem = UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Items"][key];
					--UberInventory_Message("DEBUG: _Transfer: " .. itemName .. " : " .. value, true);
                    if ( tempItem ) then
                        UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Items"][key] = { ["itemid"] = tonumber( key ),
                                                                                    ["name"] = itemName,
                                                                                    ["quality"] = itemQuality,
                                                                                    ["level"] = itemLevel,
                                                                                    ["bag_count"] = tempItem["bag_count"],
                                                                                    ["bank_count"] = tempItem["bank_count"],
                                                                                    ["mailbox_count"] = tempItem["mailbox_count"] + value,
                                                                                    ["equip_count"] = tempItem["equip_count"],
                                                                                    ["void_count"] = ( tempItem["void_count"] or 0 ),
                                                                                    ["reagent_count"] = ( tempItem["reagent_count"] or 0 ),
                                                                                    ["type"] = itemClass,
                                                                                    ["subtype"] = itemSubclass,
                                                                                    ["total"] = tempItem["total"] + value,
                                                                                    ["qitem"] = tempItem["qitem"],
                                                                                    ["qid"] = tempItem["qitem"],
                                                                                    };
                    else
                        UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Items"][key] = { ["itemid"] = tonumber( key ),
                                                                                    ["name"] = itemName,
                                                                                    ["quality"] = itemQuality,
                                                                                    ["level"] = itemLevel,
                                                                                    ["bag_count"] = 0,
                                                                                    ["bank_count"] = 0,
                                                                                    ["mailbox_count"] = value,
                                                                                    ["equip_count"] = 0,
                                                                                    ["void_count"] = 0,
                                                                                    ["reagent_count"] = 0,
                                                                                    ["type"] = itemClass,
                                                                                    ["subtype"] = itemSubclass,
                                                                                    ["total"] = value,
                                                                                    };
                    end;
                    itemCount = itemCount + 1;
                end;

                -- Register new expiration
                if ( UBI_Mail_Transfer.cash > 0 or itemCount > 0 ) then
                    UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Options"]["mail_expires"][daysLeft] = ( UBI_Data[UBI_REALM][UBI_Mail_Transfer.to]["Options"]["mail_expires"][daysLeft] or 0 ) + 1;
                end;
            end;
        end;

        -- Force refresh if main window is open
        if ( UberInventoryFrame:IsVisible() ) then
            UberInventory_DisplayItems();
        end;

        -- Clear temporary data
        wipe( UBI_Mail_Transfer );
    end;


-- Called when MAIL_CLOSED event is fired.
-- Calling function: UberInventory_OnEvent
-- This is now a hook on MailFrame:HookScript("OnHide", fn_MAIL_CLOSED);
function fn_MAIL_CLOSED()
	if ( UBI_MAILBOX_OPEN ) then
		UBI:RegisterEvent( "MAIL_INBOX_UPDATE" );  -- Re-register MAIL_INBOX_UPDATE event
		UBI_Options["mail_visit"] = UberInventory_GetDateTime();
		UberInventory_UpdateInventory( "mail" );
		UBI_MAILBOX_OPEN = false;
	end;
end;

-- Handle events sent to the addon
    function UberInventory_OnEvent( self, event, ... )
        -- Get additional arguments
        local arg1, arg2, arg3, arg4 = ...;

        -- Load data from previous session
        if ( event == "ADDON_LOADED" and arg1 == "UberInventory" ) then
            -- Execute main initialization code
            UberInventory_Init();

            -- Track current player level and class
            UBI_Options["level"] = UnitLevel( "player" );
            UBI_Options["class"] = select( 2, UnitClass( "player" ) );

            -- Check bank visit
            if ( UberInventory_DaysSince( UBI_Options["bank_visit"] ) >= UBI_BANK_VISIT_INTERVAL ) then
                UberInventory_Message( UBI_LAST_BANK_VISIT:format( UberInventory_DaysSince( UBI_Options["bank_visit"] ) ), true );
            else
                if ( not UBI_Options["bank_visit"] ) then UberInventory_Message( UBI_VISIT_BANK, true ); end;
            end;

            -- Check guildbank visit
            if ( IsInGuild() ) then
                if ( UberInventory_DaysSince( UBI_Options["guildbank_visit"] ) >= UBI_GUILDBANK_VISIT_INTERVAL ) then
                    UberInventory_Message( UBI_LAST_GUILDBANK_VISIT:format( UberInventory_DaysSince( UBI_Options["guildbank_visit"] ) ), true );
                else
                    if ( not UBI_Options["guildbank_visit"] ) then UberInventory_Message( UBI_VISIT_GUILDBANK, true ); end;
                end;
            end;

            -- Check mailbox visit
            if ( UberInventory_DaysSince( UBI_Options["mail_visit"] ) >= UBI_MAILBOX_VISIT_INTERVAL ) then
                UberInventory_Message( UBI_LAST_MAILBOX_VISIT:format( UberInventory_DaysSince( UBI_Options["mail_visit"] ) ), true );
            else
                if ( not UBI_Options["mail_visit"] ) then UberInventory_Message( UBI_VISIT_MAILBOX, true ); end;
            end;

            -- Check for mail that are about to expire
            UberInventory_MailExpirationCheck();

            -- Set transparency
            UberInventory_Change_Alpha( UBI_Options["alpha"] );

            -- Broadcast current version to the guild
            UBI_Task_SendMessage( "VERINFO", UBI_VERSION );

            return;
        end;

        -- Track the new level of the player
        if ( event == "PLAYER_LEVEL_UP" ) then
            -- Track current player level and rebuild the list
            UBI_Options["level"] = arg1;
            UberInventory_Build_Locations();
        end;

        if ( event == "PLAYER_LEAVING_WORLD" ) then
            UBI_ACTIVE = false;
        end;

        -- Update info inventory change (enters the world, enters/leaves an instance, or respawns at a graveyard, reloadui)
        if ( event == "PLAYER_ENTERING_WORLD" ) then
            UBI_ACTIVE = true;

            -- Register AddOn Message prefix
			C_ChatInfo.RegisterAddonMessagePrefix( "UBI" );

            -- Update balance frame
            UberInventory_ShowBalanceFrame( UBI_Options["show_balance"] );

            -- Get guild name
            UBI_GUILD = GetGuildInfo( "player" );
            UberInventory_Guildbank_Init();

            UberInventory_UpdateInventory( "all" );
            return;
        end;

        if ( event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" ) then
            UberInventory_UpdateInventory( "equip" );
            return;
        end;

        -- After a money event show the current cash amount
        if ( event == "PLAYER_MONEY" ) then
            -- Save current cash balance
            UberInventory_SaveMoney();

            -- Update wallet/mail info (if mainframe is shown)
            UberInventory_WalletMailCashInfo();

            -- Show message
            if ( UBI_Options["show_money"] ) then
                UberInventory_Message( UBI_MONEY_MESSAGE:format( GetCoinTextureString( GetMoney() ) ), true );
            end;
            return;
        end;

        -- On currency changes update stored data and refresh UI
        if ( event == "CURRENCY_DISPLAY_UPDATE" ) then
            -- Save other currencies
            if ( UBI_Money ) then
                UberInventory_Save_Currencies();
            end;

            -- Update token info on screen
            if ( UberInventoryTokens:IsVisible() ) then
                UberInventory_DisplayTokens();
            end;

            return;
        end;

        -- Bank closed
        if ( event == "BANKFRAME_CLOSED" ) then
            UBI_BANK_OPEN = false;
            return;
        end;

        -- Bank opened
        if ( event == "BANKFRAME_OPENED" ) then
            UBI_BANK_OPEN = true;
            UBI_Options["bank_visit"] = UberInventory_GetDateTime();
            UberInventory_UpdateInventory( "bank" );
            return;
        end;

        -- Items in the bank have changed
        if ( event == "PLAYERREAGENTBANKSLOTS_CHANGED" ) then
            UberInventory_UpdateInventory( "reagent" );
            return;
        end;

        -- Items in the bank have changed
        if ( event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED" ) then
            UberInventory_UpdateInventory( "bank" );
            return;
        end;

        if ( event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" ) then
            UberInventory_UpdateInventory( "accountbank" );
            return;
        end;
		
		

        -- Guild cash changed
        if ( event == "GUILDBANK_UPDATE_MONEY" and IsInGuild() and UBI_Options["track_gb_data"] ) then
            if ( UBI_Guildbank and UBI_Guildbank[UBI_GUILD] and UBI_Guildbank[UBI_GUILD]["Cash"] ) then
                UBI_Guildbank[UBI_GUILD]["Cash"] = GetGuildBankMoney();
            end;

            -- Update cash info on screen
            if ( UberInventoryFrame:IsVisible() ) then
                UberInventory_DisplayItems();
            end;
            return;
        end;

		-- Guildbank opened
		-- https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW
		if ( event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" ) then
			if ( arg1 == Enum.PlayerInteractionType.GuildBanker and UBI_Options["track_gb_data"]) then
				-- Track Guildbank open
				UBI_GUILDBANK_OPENED = true;

				UBI:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" );
				UBI:RegisterEvent( "GUILDBANK_UPDATE_TABS" );

				-- Traverse guild bank tabs and force loading of data
				for gbTab = 1, GetNumGuildBankTabs() do
					-- Retrieve data from the server (only for visible tabs to prevent warnings)
					local name, icon, isViewable = GetGuildBankTabInfo( gbTab );
					if ( isViewable ) then
						TaskHandlerLib:AddTask( "UberInventory", QueryGuildBankTab, gbTab );
					end;
				end;

				-- Track Guildbank last visit date/time
				UBI_Options["guildbank_visit"] = UberInventory_GetDateTime();
				return;
			end;
		end;

        -- Guildbank closed (send guildbank data using the chat system)
		-- https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_HIDE
		if ( event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" ) then
			if ( arg1 == Enum.PlayerInteractionType.GuildBanker and UBI_Options["track_gb_data"]) then
				-- Store guildbank cash
				UBI_Guildbank[UBI_GUILD]["Cash"] = GetGuildBankMoney();

				-- Start sending guildbank data
				if ( UBI_Options["send_gb_data"] ) then
					UberInventory_Send_Guildbank();
				end;
				UBI:UnregisterEvent( "GUILDBANKBAGSLOTS_CHANGED" );
				UBI:UnregisterEvent( "GUILDBANK_UPDATE_TABS" );

				UBI_GUILDBANK_OPENED = false;
				return;
			end;
        end;
		
        -- Update Guildbank information
        if ( ( event == "GUILDBANK_UPDATE_TABS" or event == "GUILDBANKBAGSLOTS_CHANGED" ) and UBI_GUILDBANK_OPENED and UBI_Options["track_gb_data"] ) then
            -- Send start message
            UberInventory_Save_Guildbank( event );
            return;
        end;

        -- Mailbox opened
        if ( event == "MAIL_SHOW" ) then
            UBI_MAILBOX_OPEN = true;
			MailFrame:HookScript("OnHide", fn_MAIL_CLOSED);			-- v10.0.2 client
            UBI:RegisterEvent( "MAIL_INBOX_UPDATE" );
            return;
        end;

        -- Mailbox changes
        if ( event == "MAIL_INBOX_UPDATE" ) then
            UBI:UnregisterEvent( "MAIL_INBOX_UPDATE" ); 			-- Prevent additional MAIL_INBOX_UPDATE event to be handled
			UBI_Options["mail_visit"] = UberInventory_GetDateTime();
            UberInventory_UpdateInventory( "mail" );
            return;
        end;

        -- Record transferred gold/items
        if ( event == "MAIL_SUCCESS" ) then
            UberInventory_Transfer();
            return;
        end;

        -- Items in the bags have changed
        if ( event == "BAG_UPDATE" and arg1 >= -2 ) then
            -- Update inventory
            UberInventory_UpdateInventory( "bag" );

            -- If bank is open rescan item
            if ( ( arg1 == BANK_CONTAINER) or ( arg1 == REAGENTBANK_CONTAINER ) or ( arg1 >= 5 and arg1 <= 11 ) ) then
				UberInventory_Save_Bank();
			end;

            -- If guildbank is open rescan it
            if ( UBI_GUILDBANK_OPENED ) then UberInventory_Save_Guildbank( 'UBI_RESCAN_GUILDBANK' ); end;
            return;
        end;

        -- Void Storage events
        if ( event == "VOID_STORAGE_UPDATE" or event == "VOID_TRANSFER_DONE" or event == "VOID_STORAGE_CONTENTS_UPDATE" ) then
            UberInventory_Save_VoidStorage( event );
        end;

        -- Handle UberInventory related guildchat messages
        if ( event == "CHAT_MSG_ADDON" and arg1 == "UBI" and arg4 ~= UBI_PLAYER and ( UBI_Options["receive_gb_data"] or UBI_GUILDBANK_FORCED ) ) then
            if ( arg2:find( "UBI:VERINFO" ) ) then
                -- Extract version number from the data string
                local _, gbVersion = strsplit( " ", arg2 );
				gbVersionNumber = gbVersion:gsub( '%W', '' );         -- leave only alphanumeric
				UBI_VERSION_Number = UBI_VERSION:gsub( '%W', '' );
                -- UberInventory_Message( 'DEBUG: '..gbVersion.. '   ' ..gbVersionNumber..'   '..UBI_VERSION_Number, true );
				
                -- Check if there is a more recent version of UberInventory
                if ( tonumber( gbVersionNumber ) > ( tonumber( UBI_VERSION_Number ) or 0 ) and not UBI_VERSION_WARNING ) then
                    UberInventory_Message( UBI_NEW_VERSION:format( arg4, gbVersion ), true );
                    UBI_VERSION_WARNING = true;
                end;

                -- If this version is more recent send message to other users using this addon
                if ( tonumber( gbVersionNumber ) < ( tonumber( UBI_VERSION_Number ) or 0 ) ) then
                    UBI_Task_SendMessage( "VERINFO", UBI_VERSION );
                end;
            elseif ( arg2:find( "UBI:GBSTART" ) and not UBI_GUILDBANK_OPENED ) then
                -- Start receiving Guildbank data, reset on each new receive from player.
                -- This way only the most recent data should be received.
                -- Only data from equal versions is allowed
                wipe( UBI_GBData );
                UBI_GBSender = arg4;
            elseif ( arg2:find( "UBI:GBITEM" ) and not UBI_GUILDBANK_OPENED ) then
                -- Receiving Guildbank data (item), only receive data from latest sender
                if ( UBI_GBSender == arg4 and UBI_Options["track_gb_data"] ) then
                    local _, itemID, itemCount, itemName, itemType, itemSubtype, itemLevel, itemQuality, extra = strsplit( " ", arg2 );
                    UBI_GBData[itemID] = { ["itemid"] = tonumber( itemID ),
                                           ["count"] = tonumber( itemCount ),
                                           ["name"] = strgsub( itemName, "_", " " ),
                                           ["type"] = strgsub( itemType, "_", " " ),
                                           ["subtype"] = strgsub( itemSubtype, "_", " " ),
                                           ["level"] = tonumber( itemLevel ),
                                           ["quality"] = tonumber( itemQuality ) };
                end;
            elseif ( arg2:find( "UBI:GBCASH" ) and not UBI_GUILDBANK_OPENED ) then
                -- Receiving Guildbank cash, only receive data from latest sender
                if ( UBI_GBSender == arg4 and UBI_Options["track_gb_data"] ) then
                    -- Init guildbank structures (if needed)
                    UberInventory_Guildbank_Init();

                    local _, gbCash = strsplit( " ", arg2 );
                    UBI_Guildbank[UBI_GUILD]["Cash"] = tonumber( gbCash );

                    -- Update cash info on screen
                    if ( UberInventoryFrame:IsVisible() ) then
                        UberInventory_DisplayItems();
                    end;
                end;
            elseif ( arg2:find( "UBI:GBEND" ) and not UBI_GUILDBANK_OPENED ) then
                -- Stop receiving Guildbank data and process the received data, only process data from latest sender
                if ( UBI_GBSender == arg4 and UBI_Options["track_gb_data"] ) then
                    UberInventory_Receive_Guildbank();
                    UBI_GUILDBANK_FORCED = false;
                end;
            end;
        end;

        -- Handle request for sending guildbank data
        if ( event == "CHAT_MSG_ADDON" and arg1 == "UBI" and arg4 ~= UBI_PLAYER ) then
            if ( arg2:find( "UBI:GBREQUEST" ) and UBI_Options["track_gb_data"] ) then
                if ( UBI_GUILDBANK_OPENED and UBI_GUILDBANK_VIEWACCESS ) then
                    UberInventory_Send_Guildbank();
                end;
            end;
        end;

        -- Pandarian toon has selected faction
        if ( event == "NEUTRAL_FACTION_SELECT_RESULT" ) then
            UberInventory_GetAlts();
            UberInventory_GetGuildbanks();
        end;
		
		-- Auto sell grey items
		if ( event == "MERCHANT_SHOW" and UBI_Global_Options["Options"]["sell_greys"] ) then
			sellValue = 0	
			for iBag = 0,4 do
				for containerSlots = 1, C_Container.GetContainerNumSlots( iBag ) do
					CurrentItemLink = C_Container.GetContainerItemLink( iBag, containerSlots );
					if CurrentItemLink then
						_, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo( CurrentItemLink );
						local containerinfo = C_Container.GetContainerItemInfo( iBag, containerSlots );
						itemCount = containerinfo.stackCount;
						if itemRarity == 0 and itemSellPrice ~= 0 then
							sellValue = sellValue + ( itemSellPrice * itemCount );
							C_Container.UseContainerItem( iBag, containerSlots );
							PickupMerchantItem();
						end;
					end;
				end;
			end;
			if ( sellValue > 0 ) then
				UberInventory_Message( UBI_MONEY_MESSAGE_GREYSELL:format( GetCoinTextureString( sellValue ) ), true );
			end;
		end;
		
		-- Auto repair using own coin
		if ( event == "MERCHANT_SHOW" and UBI_Global_Options["Options"]["autorepair_self"] and CanMerchantRepair() ) then
			repairAllCost, canRepair = GetRepairAllCost();
			if ( canRepair and repairAllCost > 0 ) then
			    -- Use own funds
			    if ( repairAllCost <= GetMoney() ) then
			    	RepairAllItems(false);
					UberInventory_Message( UBI_MONEY_MESSAGE_AUTOREPAIR_SELF:format( GetCoinTextureString( repairAllCost ) ), true );
			    end;
			end;
        end;

        -- Build the inventory
        UberInventory_UpdateInventory( "all" );

        -- Build list for locations
        UberInventory_Build_Locations();

        -- Rebuild list of guildbanks
        if ( UBI_GUILD ~= GetGuildInfo( "player" ) ) then
            UBI_GUILD = GetGuildInfo( "player" );
            UberInventory_Guildbank_Init();
            UberInventory_GetGuildbanks();
            UberInventory_Build_Locations();
        end;
    end;

-- Show or hide the balance frame
    function UberInventory_ShowBalanceFrame( showFrame )
        if ( showFrame ) then
            UberInventoryBalanceFrame:Show();
            MoneyFrame_Update( "UberInventoryBalanceFrameMoneyFrame", GetMoney() );
        else
            UberInventoryBalanceFrame:Hide();
        end;
    end;

-- Update transparency of frames
    function UberInventory_Change_Alpha( alpha )
        UberInventoryFrameTexture:SetAlpha( alpha );
        UberInventoryFrameBorderTexture:SetAlpha( alpha );
        UberInventoryTokensTexture:SetAlpha( alpha );
        UberInventoryTokensBorderTexture:SetAlpha( alpha );
    end;


-- Init frame options
    function UberInventory_SetOptions( frame )
        -- Initiliaze
        local UBI_Options = UBI_Options;

        -- Apply settings to the frame
        _G[ "SettingMoney" ]:SetChecked( UBI_Options["show_money"] );
        _G[ "SettingBalance" ]:SetChecked( UBI_Options["show_balance"] );
        _G[ "SettingShowTooltip" ]:SetChecked( UBI_Options["show_tooltip"] );
        _G[ "SettingRecipePrice" ]:SetChecked( UBI_Options["show_recipe_prices"] );
        _G[ "SettingQuestReward" ]:SetChecked( UBI_Options["show_recipe_reward"] );
        _G[ "SettingRecipeDrop" ]:SetChecked( UBI_Options["show_recipe_drop"] );
        _G[ "SettingHighlight" ]:SetChecked( UBI_Options["show_highlight"] );
        _G[ "SettingInboxMoney" ]:SetChecked( UBI_Options["take_money"] );
        _G[ "SettingAlpha" ]:SetValue( UBI_Options["alpha"] );
        _G[ "SettingSendGuildbankData" ]:SetChecked( UBI_Options["send_gb_data"] );
        _G[ "SettingReceiveGuildbankData" ]:SetChecked( UBI_Options["receive_gb_data"] );
        _G[ "SettingTrackGuildbankData" ]:SetChecked( UBI_Options["track_gb_data"] );
        _G[ "SettingWarnMailExpire" ]:SetChecked( UBI_Options["warn_mailexpire"] );
        _G[ "SettingShowItemcount" ]:SetChecked( UBI_Options["show_item_count"] );
		_G[ "SettingIgnoreRealm" ]:SetChecked( UBI_Global_Options["Options"]["ignore_realm"] );
		_G[ "SettingAutoSellGreys" ]:SetChecked( UBI_Global_Options["Options"]["sell_greys"] );
		_G[ "SettingAutoRepairSelf" ]:SetChecked( UBI_Global_Options["Options"]["autorepair_self"] );
		_G[ "SettingShowItemID" ]:SetChecked( UBI_Global_Options["Options"]["show_item_id"] );

        UberInventory_Redraw_TooltipOptions();
    end;

-- Redraw state for tooltip options
    function UberInventory_Redraw_TooltipOptions()
        local state = _G[ "SettingShowTooltip" ]:GetChecked();
        UberInventory_SetState( _G[ "SettingRecipePrice" ], state );
        UberInventory_SetState( _G[ "SettingQuestReward" ], state );
        UberInventory_SetState( _G[ "SettingRecipeDrop" ], state );
		UberInventory_SetState( _G[ "SettingShowItemID" ], state );
    end;

-- Save frame options
    function UberInventory_SaveOptions( frame )
        -- Initiliaze
        local UBI_Options = UBI_Options;
		local org_ignore_realm = UBI_Global_Options["Options"]["ignore_realm"];

        -- Save settings from the frame
        UBI_Options["show_money"] = _G[ "SettingMoney" ]:GetChecked();
        UBI_Options["show_balance"] = _G[ "SettingBalance" ]:GetChecked();
        UBI_Options["show_tooltip"] = _G[ "SettingShowTooltip" ]:GetChecked();
        UBI_Options["show_recipe_prices"] = _G[ "SettingRecipePrice" ]:GetChecked();
        UBI_Options["show_recipe_reward"] = _G[ "SettingQuestReward" ]:GetChecked();
        UBI_Options["show_recipe_drop"] = _G[ "SettingRecipeDrop" ]:GetChecked();
        UBI_Options["show_highlight"] = _G[ "SettingHighlight" ]:GetChecked();
        UBI_Options["show_item_count"] = _G[ "SettingShowItemcount" ]:GetChecked();
        UBI_Options["take_money"] = _G[ "SettingInboxMoney" ]:GetChecked();
        UBI_Options["alpha"] = _G[ "SettingAlpha" ]:GetValue();
        UBI_Options["send_gb_data"] = _G[ "SettingSendGuildbankData" ]:GetChecked();
        UBI_Options["receive_gb_data"] = _G[ "SettingReceiveGuildbankData" ]:GetChecked();
        UBI_Options["track_gb_data"] = _G[ "SettingTrackGuildbankData" ]:GetChecked();
        UBI_Options["warn_mailexpire"] = _G[ "SettingWarnMailExpire" ]:GetChecked();
		UBI_Global_Options["Options"]["ignore_realm"] = _G[ "SettingIgnoreRealm" ]:GetChecked();
		UBI_Global_Options["Options"]["sell_greys"] = _G[ "SettingAutoSellGreys" ]:GetChecked();
		UBI_Global_Options["Options"]["autorepair_self"] = _G[ "SettingAutoRepairSelf" ]:GetChecked();
		UBI_Global_Options["Options"]["show_item_id"] = _G[ "SettingShowItemID" ]:GetChecked();
		
        -- If Ignore Realm option has changed, a reload UI is needed
		if ( org_ignore_realm ~= UBI_Global_Options["Options"]["ignore_realm"] ) then
		   UberInventory_ReloadUI();
		end;
    end;

-- Apply setting to the UI
    function UberInventory_UpdateUI()
        -- Initiliaze
        local UBI_Options = UBI_Options;

        -- Hide or show balance frame based on the current settings (look for a more elegant solution)
        UberInventory_ShowBalanceFrame( UBI_Options["show_balance"] );

        -- Restore or set transparency
        UberInventory_Change_Alpha( UBI_Options["alpha"] );

        -- Force refresh
        UberInventory_DisplayItems();
    end;

-- Revert all options to default values
    function UberInventory_SetDefaults( frame )
        -- Initiliaze
        local UBI_Options = UBI_Options;

        -- Restore defaults
        for key, value in pairs( UBI_Defaults ) do
            UBI_Options[key] = value;
        end;

        -- Hide or show balance frame based on the current settings (look for a more elegant solution)
        UberInventory_ShowBalanceFrame( UBI_Options["show_balance"] );

        -- Restore or set transparency
        UberInventory_Change_Alpha( UBI_Options["alpha"] );

        -- Redraw Options frame
        UberInventory_SetOptions( frame );
    end;

-- Make Settings frame known to the system
    function UberInventory_AddCategory( frame )
        -- Set panel name
        frame.name = UBI_NAME;

        -- Set okay function
        frame.okay = function( self )
            UberInventory_SaveOptions( self );
            UberInventory_UpdateUI();
        end;

        -- Set cancel function
        frame.cancel = function( self )
            UberInventory_SetOptions( self );
            UberInventory_UpdateUI();
        end;

        -- set defaults function
        frame.default = function( self )
            UberInventory_SetDefaults( self );
            UberInventory_UpdateUI();
        end;

        -- Add the panel
        -- InterfaceOptions_AddCategory( frame );
		local category, layout = Settings.RegisterCanvasLayoutCategory(frame, frame.name);
		Settings.RegisterAddOnCategory(category);
    end;
	

-- Update button mask to indicate item usability (clear = usable, red = usuable, blue = uncached item)
    function UberInventory_MarkButton( button, itemid )
        -- Clear state
        button:SetAttribute( "usable", nil );

        -- Reapply color coding
        if UberInventory_UsableItem( itemid ) then
            SetItemButtonTextureVertexColor( button, 1, 1, 1 );
        else
            SetItemButtonTextureVertexColor( button, 1, 0.1, 0.1 );
        end;

        -- Item still not locally cached, mark it again
        if ( not C_Item.GetItemInfo( itemid ) ) then
            button:SetAttribute( "usable", "uncached" );
            SetItemButtonTextureVertexColor( button, 0.2, 0.2, 0.8 );
        end;
    end;

-- Handle uncached items
    function UberInventory_ItemButton_OnUpdate( self, elapsed )
        -- Initialize
        local state = self:GetAttribute( "usable" );
        local total_elapsed = self:GetAttribute( "elapsed" ) + elapsed;

        -- To minimize load perform the rest only if item is uncached and concerns a visible button
        if ( state and state == "uncached" and self:IsVisible() ) then
            -- Update total elapsed time since last real call
            self:SetAttribute( "elapsed", total_elapsed );

            -- Re-mark the button and reset elapsed
            if ( total_elapsed > 0.5 ) then
                UberInventory_MarkButton( self, self:GetID() );
                self:SetAttribute( "elapsed", 0 );
            end;
        end;
    end;

-- Update cash field
    function UberInventory_UpdateCashField( frame, cash, prefix )
        -- Update cash info and resize frame
        if ( cash > 0 ) then
            frame:SetText( (prefix or "")..GetMoneyString( cash, true ).."  " );
        else
            frame:SetText( (prefix or "").."---" );
        end;
    end;

-- Update inventory button
    function UberInventory_UpdateButton( slot, record )
        local objSlot = _G[ "UberInventoryFrameItem"..slot ];
        local button = objSlot:GetName().."ItemButton";
        local buttonObj = _G[ button ];

        -- Record is nil, item does not exist and button should be hidden
        if ( not record ) then
            objSlot:Hide();
            return;
        else
            objSlot:Show();
        end;

        -- Get itemID
        local itemid = record["itemid"];

        -- Get item prices
        local buyPrice, sellPrice, buyoutPrice = UberInventory_GetItemPrices( itemid );

        -- Get item counts
        local bagCount = record["bag_count"] or 0;
        local bankCount = record["bank_count"] or 0;
        local mailCount = record["mailbox_count"] or 0;
        local equipCount = record["equip_count"] or 0;
        local voidCount = record["void_count"] or 0;
        local reagentCount = record["reagent_count"] or 0;
        local guildCount = record["count"] or 0;
        local totalCount = record["total"] or 0;

        -- Quest information
        local questID = ( record["qid"] or 0 );
        local questItem = ( record["qitem"] or flase );

        -- Get correct totalCount for combined inventory searches
        if ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "complete" or UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_character" or UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_guildbank" ) then
            totalCount = UBI_Track[record.itemid] or 0;
        end;

        -- Set item image
        if ( record["type"] == UBI_BATTLEPET_CLASS and itemid ~= 82800 ) then
            local _, icon = C_PetJournal.GetPetInfoBySpeciesID( itemid );
            SetItemButtonTexture( buttonObj, icon );
        else
            SetItemButtonTexture( buttonObj, GetItemIcon( itemid ) );
        end;

        -- Set item name
        local itemcolor = ITEM_QUALITY_COLORS[record.quality];
        _G[ button.."ItemName" ]:SetText( record["name"] );
        _G[ button.."ItemName" ]:SetTextColor( itemcolor.r, itemcolor.g, itemcolor.b );


        -- Set item count
        --if ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "current" or UBI_LocationList[UBI_FILTER_LOCATIONS].type == "character" ) then
        --    _G[ button.."ItemCount" ]:SetFormattedText( UBI_ITEM_COUNT, totalCount, bagCount, bankCount, mailCount, equipCount, voidCount, reagentCount );
        --else
            _G[ button.."ItemCount" ]:SetFormattedText( UBI_ITEM_COUNT_SINGLE, totalCount );
        --end;
        SetItemButtonCount( buttonObj, totalCount );

        -- Set item id (for tooltip)
        buttonObj:SetID( itemid );
        buttonObj:SetAttribute( "inventoryitem", record );
        buttonObj:SetAttribute( "location", UBI_FILTER_LOCATIONS );
        buttonObj:SetAttribute( "usable", nil );
        buttonObj:SetAttribute( "elapsed", 0 );

        -- Update buy, buyout and sell prices

		-- Show sell price
		_G[ button.."ItemSell" ]:Show();

		-- Update price fields
		UberInventory_UpdateCashField( _G[ button.."ItemBuy" ], buyPrice or 0, UBI_ITEM_BUY );
		UberInventory_UpdateCashField( _G[ button.."ItemSell" ], sellPrice or 0, UBI_ITEM_SELL );

        -- Mark usability onto the itembutton
        if ( record["type"] ~= UBI_BATTLEPET_CLASS ) then
            UberInventory_MarkButton( buttonObj, itemid );
        end;

        -- Mark quest item
        local questTexture = _G[ button.."IconQuestTexture" ];
        if ( questID > 0 ) then
            questTexture:SetTexture( TEXTURE_ITEM_QUEST_BANG );
            questTexture:Show();
        elseif ( questItem ) then
            questTexture:SetTexture( TEXTURE_ITEM_QUEST_BORDER) ;
            questTexture:Show();
        else
            questTexture:Hide();
        end;
    end;

-- Mousewheel support for scrolling through items
    function UberInventory_OnMouseWheel( frame, delta, type )
        local offset = FauxScrollFrame_GetOffset( frame ) or 0;
        local newOffset = math.max( offset - delta, 0 );

        -- Update scroll positions and force redisplay of content
        if ( type == "ITEMS" ) then
            local maxOffset = ceil( ( #UBI_Sorted - UBI_NUM_ITEMBUTTONS ) / 2 );
            frame:SetVerticalScroll( math.min( maxOffset, newOffset ) * 36 );
            UberInventory_DisplayItems();
        elseif ( type == "TOKENS" ) then
            local maxOffset = #UBI_Currencies+1 - UBI_NUM_TOKENBUTTONS;
            frame:SetVerticalScroll( math.min( maxOffset, newOffset ) * 17 );
            UberInventory_DisplayTokens();
		elseif ( type == "DELETION" ) then
            local maxOffset = #g_deletionList+1 - UBI_NUM_DELETIONBUTTONS;
            frame:SetVerticalScroll( math.min( maxOffset, newOffset ) * 17 );
            UberInventory_DisplayDeletionList();
        end;
    end;

-- Display items (by page, UBI_NUM_ITEMBUTTONS items)
    function UberInventory_DisplayItems()
        -- From global to local
        local UBI_Characters = UBI_Characters;
        local UBI_Guildbanks = UBI_Guildbanks;
        local UBI_Data = UBI_Data;
        local UBI_Guildbank = UBI_Guildbank;
        local UBI_Sorted = UBI_Sorted;

        -- Create GB structure if it does not already exist
        UberInventory_Guildbank_Init();

        -- Sort and filter items
        UberInventory_SortFilter( UBI_FILTER_TEXT or "", false );

        -- Get current offset
        local offset = FauxScrollFrame_GetOffset( UberInventoryFrameScroll ) or 0;

        -- Update scrollbars (reset scroll position when needed)
        if ( offset > ceil( (#UBI_Sorted-UBI_NUM_ITEMBUTTONS) / 2 ) ) then
            UberInventory_ScrollToTop();
            offset = 0;
        else
            FauxScrollFrame_Update( UberInventoryFrameScroll, ceil( #UBI_Sorted / 2 ), 8, 36 );
        end;

        -- Execute code to actually add the items to the inventory frame
        local index;
        for slot = 1, UBI_NUM_ITEMBUTTONS do
            -- Calculate the actual index within sorted array
            index = ( offset * 2 ) + slot;

            -- Display item
            UberInventory_UpdateButton( slot, UBI_Sorted[ index ] );
        end;

        -- Update inventory count
         UberInventoryFrameInventoryCount:SetFormattedText( UBI_INVENTORY_COUNT, #UBI_Sorted, UBI_Inventory_count );
		

        -- Disable the token button
        UberInventory_SetState( UberInventoryFrameTokensButton, false );

        -- Show/Hide the moneyframe for displaying Guildbank or Alt cash
        if ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "current" ) then
            UberInventoryFrameMoneyOthersCash:SetText( UBI_EMPTY_TEXT );
            UberInventory_SetState( UberInventoryFrameTokensButton, true );
        else
            -- Initialize
            local otherCash = 0;

            -- Determine the cash owned
            if ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "guildbank" ) then
                otherCash = UBI_Guildbank[UBI_LocationList[UBI_FILTER_LOCATIONS].value]["Cash"];
            elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "character" ) then
			    -- Alt characters
				local character_dirty = UBI_LocationList[UBI_FILTER_LOCATIONS].value;
			    local character = string.sub ( character_dirty, 1, string.find( character_dirty, "%[", 1 ) - 2);
				-- UberInventory_Message( "DEBUG UberInventory_DisplayItems raw: "..character, true );

	            -- break apart "player-realm"
		        player = string.sub ( character, 1, string.find( character, "-", 1 ) - 1 );
			    realm = string.sub ( character, string.find( character, "-", 1 ) + 1, string.len( character) );
			    -- UberInventory_Message( "DEBUG UberInventory_DisplayItems: "..player.."   "..realm, true );
				
                otherCash = UBI_Data[realm][player]["Money"]["Cash"] + UBI_Data[realm][player]["Money"]["mail"];
                UberInventory_SetState( UberInventoryFrameTokensButton, true );
            elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_character" ) then
                -- Traverse guildbanks
                otherCash = otherCash + UBI_Data[UBI_REALM][UBI_PLAYER]["Money"]["Cash"] + UBI_Data[UBI_REALM][UBI_PLAYER]["Money"]["mail"];

                -- Traverse characters
                for key, value in pairs( UBI_Characters ) do
				    -- break apart "player-realm"
		            player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			        realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
                    otherCash = otherCash + UBI_Data[realm][player]["Money"]["Cash"] + UBI_Data[realm][player]["Money"]["mail"];
                end;
            elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "all_guildbank" ) then
                -- Traverse guildbanks
                for key, value in pairs( UBI_Guildbanks ) do
                    otherCash = otherCash + UBI_Guildbank[value]["Cash"];
                end;
            elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "complete" ) then
                -- Traverse guildbanks
                otherCash = otherCash + UBI_Data[UBI_REALM][UBI_PLAYER]["Money"]["Cash"] + UBI_Data[UBI_REALM][UBI_PLAYER]["Money"]["mail"];

                -- Traverse characters
                for key, value in pairs( UBI_Characters ) do
					-- break apart "player-realm"
		            player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			        realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
                    otherCash = otherCash + UBI_Data[realm][player]["Money"]["Cash"] + UBI_Data[realm][player]["Money"]["mail"];
                end;

                -- Traverse guildbanks
                for key, value in pairs( UBI_Guildbanks ) do
                    otherCash = otherCash + UBI_Guildbank[value]["Cash"];
                end;
				
            end;

            -- Update the cash info for Alt/Guildbank
            UberInventory_UpdateCashField( UberInventoryFrameMoneyOthersCash, otherCash );
        end;
    end;

-- Display tokens
    function UberInventory_DisplayTokens()
        local tokenList = {};
        local line, index, button, currency, tokenData, toon;
        local offset = FauxScrollFrame_GetOffset( UberInventoryTokensScroll );

        -- Determine token set to be displayed
        if ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "current" ) then
            tokenData = UBI_Data[UBI_REALM][UBI_PLAYER]["Money"]["Currencies"];
            toon = UBI_PLAYER;
        elseif ( UBI_LocationList[UBI_FILTER_LOCATIONS].type == "character" ) then
		    -- Alt character
			local character_dirty = UBI_LocationList[UBI_FILTER_LOCATIONS].value;
			local character = string.sub ( character_dirty, 1, string.find( character_dirty, "%[", 1 ) - 2);
			
		    -- Break apart "player-realm"
		    player = string.sub ( character, 1, string.find( character, "-", 1 ) - 1 );
			realm = string.sub ( character, string.find( character, "-", 1 ) + 1, string.len( character) );
			
            tokenData = UBI_Data[realm][player]["Money"]["Currencies"];
            toon = UBI_LocationList[UBI_FILTER_LOCATIONS].value;
        else
            UberInventoryTokens:Hide();
            return;
        end;

        -- Build new list containing headings, non-zero tokens and forced tokens
        for key, value in pairs( UBI_Currencies ) do
            if ( value.id < 0 or value.force ) then
                tinsert( tokenList, value );
            else
                if ( ( tokenData[value.id] or 0 ) > 0 ) then
                    tinsert( tokenList, value );
                end;
            end;
        end;
        local length = #tokenList;

        -- Update scrollbars
        FauxScrollFrame_Update( UberInventoryTokensScroll, length+1, UBI_NUM_TOKENBUTTONS, 17 );

        -- Set title and show frame
        UberInventoryTokensHeading:SetText( UBI_TOKEN:format( toon ) );
        UberInventoryTokens:Show();

        -- Redraw items
        for line = 1, UBI_NUM_TOKENBUTTONS, 1 do
            index = offset + line;
            button = _G[ "Token"..line ];
            if index <= length then
                if ( tokenList[index].id > 0 ) then
                     _G[ "Token"..line.."Icon" ]:SetTexture( tokenList[index].icon );
                     _G[ "Token"..line.."Icon" ]:Show();
                     if ( ( tokenData[tokenList[index].id] or 0 ) > 0 ) then
                         _G[ "Token"..line.."Name" ]:SetTextColor( 1.0, 1.0, 1.0 );
                         _G[ "Token"..line.."Count" ]:SetTextColor( 1.0, 1.0, 1.0 );
                     else
                         _G[ "Token"..line.."Name" ]:SetTextColor( 0.7, 0.7, 0.7 );
                         _G[ "Token"..line.."Count" ]:SetTextColor( 0.7, 0.7, 0.7 );
                     end;
                     _G[ "Token"..line.."Name" ]:SetText( "   "..( tokenList[index].name or "??" ) );
                     _G[ "Token"..line.."Count" ]:SetText( tokenData[tokenList[index].id] or 0 );
                     _G[ "Token"..line.."Count" ]:Show();
                else
                     _G[ "Token"..line.."Icon" ]:Hide();
                     _G[ "Token"..line.."Name" ]:SetTextColor( 1.0, 0.82, 0.0 );
                     _G[ "Token"..line.."Name" ]:SetText( tokenList[index].name );
                     _G[ "Token"..line.."Count" ]:Hide();
                end;
                button:Show();
            else
                button:Hide();
            end;
        end;

    end;
	
	
	-- Display list of characters to delete
    function UberInventory_DisplayDeletionList()
        g_deletionList = {};					-- this is a global so that it can be used in other functions
        local line, index, button, level;
        local offset = FauxScrollFrame_GetOffset( UberInventoryDeletionListScroll );
		local UBI_DELETION_INFO = {};

		-- _______________________________________________________________________________
		-- Guild section

		-- Title
		UBI_DELETION_INFO = { formatted_text = UBI_ALL_GUILDBANKS,
							  raw_text = "",
							  level = 0,
							  entryType = "HEADER",
							  title = true };
							   
		tinsert( g_deletionList, UBI_DELETION_INFO );
		
		-- Populate list of guilds
		
		for key, value in pairs( UBI_Guildbanks ) do
		
			UBI_DELETION_INFO = { formatted_text = "   > "..value,
								  raw_text = value,
								  level = 0,
								  entryType = "GUILD",
								  title = false };

			tinsert( g_deletionList, UBI_DELETION_INFO);
			
		end;
		
		-- _______________________________________________________________________________
		-- Character section
		
		-- Title
		UBI_DELETION_INFO = { formatted_text = UBI_ALL_CHARACTERS,
							  raw_text = "",
							  level = 0,
							  entryType = "HEADER",
							  title = true };
							   
		tinsert( g_deletionList, UBI_DELETION_INFO );
		
		-- Populate list of characters
        for key, value in pairs( UBI_Characters ) do
		    -- break apart "player-realm"
		    player = string.sub ( value, 1, string.find( value, "-", 1 ) - 1 );
			realm = string.sub ( value, string.find( value, "-", 1 ) + 1, string.len( value) );
			
			-- add the level in yellow
            if ( UBI_Data[realm][player]["Options"]["level"] ) then
                level = " ["..C_YELLOW..UBI_Data[realm][player]["Options"]["level"]..C_CLOSE.."]";
            else
                level = "";
            end;
			
			UBI_DELETION_INFO = { formatted_text = "   > "..value..level,
								  raw_text = value,
								  level = level,
								  entryType = "CHAR",
								  title = false };

			tinsert( g_deletionList, UBI_DELETION_INFO);
			--DEFAULT_CHAT_FRAME:AddMessage( string.format("tinsert: %s, %s", key, value) );
		end;
		
		-- _______________________________________________________________________________

        local length = #g_deletionList;			-- Number of items in the list

        -- Update scrollbars
        FauxScrollFrame_Update( UberInventoryDeletionListScroll, length+1, UBI_NUM_DELETIONBUTTONS, 17 );

        -- Show frame
        UberInventoryDeletionList:Show();

        -- Redraw
        for line = 1, UBI_NUM_DELETIONBUTTONS, 1 do
            index = offset + line;
            button = _G[ "DELETION"..line ];
            if index <= length then
				local buttonName = g_deletionList[index].formatted_text;
				if ( g_deletionList[index].title ) then
					button:Disable();
				else
					button:Enable();
				end;
				_G[ "DELETION"..line.."Name" ]:SetTextColor( 1.0, 1.0, 1.0 );
				_G[ "DELETION"..line.."Name" ]:SetText( buttonName );
				_G[ "DELETION"..line.."Name" ]:Show();
                button:Show();
				--DEFAULT_CHAT_FRAME:AddMessage( string.format( "button enabled? %s, %s", button:GetName(), tostring(button:IsEnabled()) ) );
            else
                button:Hide();
            end;
        end;

    end;


-- Process mouse click event for character / guild deletion
--[[
		Example of a player entry in the g_deletionList array:
			{ formatted_text = "   > Secretly-Medivh",
			  raw_text = "Secretly-Medivh",
			  level = 60,
			  entryType = "CHAR"
			  title = false };
--]]							  
    function UberInventory_DisplayDeletionList_Click( self )
		local line, index;
		local offset = FauxScrollFrame_GetOffset( UberInventoryDeletionListScroll );
		-- DEFAULT_CHAT_FRAME:AddMessage( string.format( "Debug UberInventory_DisplayDeletionList_Click: %d, %s, %s", self:GetID(), self:GetName(), _G[ self:GetName().."Name" ]:GetText() ) );
		
		line = tonumber(self:GetName():match "%d+");	-- Get button number. This looks for first number sequence (eg, DELETION12 returns 12)
		index = line + offset;							-- Need to add scroll offset to the line clicked to get the actual array index
		object_name = g_deletionList[index].raw_text;	-- Get the unformatted text of the object to delete. (eg, Ascent for guild, or Secretly-Medivh for player)
		
		if ( g_deletionList[index].entryType == "CHAR" ) then
			UberInventory_RemoveData ( "remchar "..object_name );
		end;
		
		if ( g_deletionList[index].entryType == "GUILD" ) then
			UberInventory_RemoveData ( "remguild "..object_name );
		end;
		
	end;
	
	
-- Update wallet/mail cash info on screen
    function UberInventory_WalletMailCashInfo()
        if(  UberInventoryFrame:IsVisible() ) then
            -- Update cash balance information

            UberInventory_UpdateCashField( UberInventoryFrameMoneyWalletCash, GetMoney() );
            UberInventory_UpdateCashField( UberInventoryFrameMoneyMailCash, UBI_Money["mail"] );
			UberInventory_UpdateCashField( UberInventoryFrameMoneyAccountCash, GetAccountWideGoldValue() );
        end;
    end;

-- Show or hide the Main dialog
    function UberInventory_Toggle_Main()
        if(  UberInventoryFrame:IsVisible() ) then
            UberInventoryFrame:Hide();
        else
            -- Show the frame
            UberInventoryFrame:Show();
            --UberInventoryFrame:SetBackdropColor( 0, 0, 0, 1 );			-- v9.0  not needed

            -- Update wallet/mail cash information
            UberInventory_WalletMailCashInfo();

            -- Force refresh
            UberInventory_DisplayItems();

            -- Update slot count information
            UberInventory_Update_SlotCount();
        end;
    end;

-- Show or hide the Main dialog
    function UberInventory_Toggle_Tokens()
        if(  UberInventoryTokens:IsVisible() ) then
            UberInventoryTokens:Hide();
        else
            -- Show the frame
            UberInventoryTokens:Show();
			UberInventoryDeletionList:Hide();
            --UberInventoryTokens:SetBackdropColor( 0, 0, 0, 1 );			-- v9.0 not needed
        end;
    end;
	
-- Show or hide the Character Deletion dialog
    function UberInventory_Toggle_DeletionList()
        if(  UberInventoryDeletionList:IsVisible() ) then
            UberInventoryDeletionList:Hide();
        else
            -- Show the frame
            UberInventoryDeletionList:Show();
			UberInventoryTokens:Hide();
        end;
    end;

-- Show/Hide tooltip info
    function UberInventory_Toggle_Tooltip()
        UBI_Options["show_tooltip"] = not UBI_Options["show_tooltip"];
    end;

-- Set/Remove hightlight for container/item
    function UberInventory_Highlighter( item, state )
        -- Set hightlight from container/item
        function HighlightOn( frame )
            SetItemButtonTextureVertexColor( frame, .6, .6, .6, 1 );
            frame:GetNormalTexture():SetVertexColor( .6, .6, .6, 1 );
            frame:LockHighlight();
            tinsert( UBI_Highlights, frame );
        end;

        -- Remove hightlight from container/item
        function HighlightOff( frame )
            SetItemButtonTextureVertexColor( frame, 1, 1, 1 );
            frame:GetNormalTexture():SetVertexColor( 1, 1, 1 );
            frame:UnlockHighlight();
        end;

        -- Exit if highlighting has been turned off
        if ( not UBI_Options["show_highlight"] ) then
            return;
        end;

		-- DISABLE HIGHLIGHTING UNTIL OFFSETS CAN BE FIXED
		if ( 1 == 1 ) then
			return;
		end;
		
        -- Set or remove highlights
        if ( state == "off" ) then
            -- Remove all previous highlights
            for id, frame in pairs( UBI_Highlights ) do
                HighlightOff( frame );
            end;
            wipe( UBI_Highlights );
        else
            -- Initialize
            local bagid, slotid, itemid, itemlink, index, container, _;

            -- Travese all containers and slots (bag, bank) to locate items
            --for bagid = -2, 11, 1 do
			for bagid = REAGENTBANK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS, 1 do
                index = IsBagOpen( bagid );
                for slotid = 1, C_Container.GetContainerNumSlots( bagid ) do
                    itemlink = C_Container.GetContainerItemLink( bagid, slotid );
                    if ( itemlink ) then
                        _, _, itemid = strsplit( ":", itemlink );		-- 20250504 new 2nd attribute
                        if ( tonumber(itemid) == item and UI_CONTAINER_OBJECTS[bagid]:IsShown() ) then
                            -- Highlight container
                            if ( bagid ~= BANK_CONTAINER and bagid ~= REAGENTBANK_CONTAINER ) then
                                HighlightOn( UI_CONTAINER_OBJECTS[bagid] );
                            end;

                            -- Highlight item
                            if ( index or bagid == BANK_CONTAINER or bagid == REAGENTBANK_CONTAINER ) then
                                if ( bagid == BANK_CONTAINER ) then
                                    container = "BankFrameItem"..slotid;
								elseif ( bagid == REAGENTBANK_CONTAINER ) then
                                    container = "ReagentBankFrameItem"..slotid;
                                else
                                    slotid = C_Container.GetContainerNumSlots( bagid ) - slotid + 1;
                                    --container = "ContainerFrame"..index.."Item"..slotid;
									container = "ContainerFrame"..bagid.."Item"..slotid;
                                end;
                                HighlightOn(  _G[ container ] );
                            end;
                        end;
                    end;
                end;
            end;

            -- Travese all guild bank slots to locate item
            if ( UBI_GUILDBANK_OPENED ) then
                local gbTab, gbSlot;
                for gbTab = 1, GetNumGuildBankTabs() do
                    for gbSlot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                        itemlink = GetGuildBankItemLink( gbTab, gbSlot );
                        if ( itemlink ) then
                            _, _, itemid = strsplit( ":", itemlink );			-- 20250504 new 2nd attribute
                            if ( tonumber(itemid) == item ) then
                                -- Highlight tab
                                container = "GuildBankTab"..gbTab.."Button";
                                HighlightOn(  _G[ container ] );

                                -- Highlight item
                                if ( GetCurrentGuildBankTab() == gbTab ) then
                                    index = mod( gbSlot, NUM_SLOTS_PER_GUILDBANK_GROUP );
                                    if ( index == 0 ) then
                                        index = NUM_SLOTS_PER_GUILDBANK_GROUP;
                                    end
                                    column = ceil( ( gbSlot - 0.5 ) / NUM_SLOTS_PER_GUILDBANK_GROUP );
                                    container = "GuildBankColumn"..column.."Button"..index;
                                    HighlightOn(  _G[ container ] );
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;

-- Perform item search
    function UberInventory_Search( str )
        -- From global to local
        local itemText, msg, count = "", "", 0;
        local icon;
		local accountbank_total = 0;
		local found_something = false;

        -- Display search criteria
        UberInventory_Message( UBI_ITEM_SEARCH:format( str ), true );

        -- Search and display items found
        local itemCounts = { 0, 0, 0, 0, 0 };
        for key, value in pairs( UBI_Items ) do
            if ( ( strfind( strlower( value.name ) , strlower( str ) ) or 0 ) > 0 ) then
				found_something = true;
                -- Get item count
                itemCounts = { value.total,
                               value.bag_count or 0,
                               value.bank_count or 0,
                               value.mailbox_count or 0,
                               value.equip_count or 0,
                               value.void_count or 0,
                               value.reagent_count or 0, };

                -- Set item image
                if ( value.type == UBI_BATTLEPET_CLASS and value.itemid ~= 82800 ) then
                    _, icon = C_PetJournal.GetPetInfoBySpeciesID( value.itemid );
                else
                    icon = GetItemIcon( value.itemid );
                end;

				-- Build search result for account bank
				accountbank_total = 0;
				for key, record in pairs( UBI_Accountbank["Items"] ) do
					--UberInventory_Message ( "##"..strlower(record.name).."##    ##"..strlower(value.name).."##" );
					if ( strlower( record.name ) == strlower( value.name ) ) then
						if ( record.total > 0 ) then
							accountbank_total = record.total;
						end;
					end;
				end;
				
                -- Build search result for local player
                itemText = "|T"..icon..":0|t "..UberInventory_GetLink( value.itemid, value );
                msg = "  "..itemText.." "..UBI_ITEM_COUNT_SINGLE:format( itemCounts[1] + accountbank_total ).." (";
                for loc = 2, #itemCounts do
                    if ( itemCounts[loc] > 0 ) then
                        msg = msg.."|T"..UBI_LOCATION_TEXTURE[loc-1]..":0|t "..UBI_LOCATIONS[loc-1].." = "..itemCounts[loc].." / ";
                    end;
                end;
				
				-- Append account bank results
				if ( accountbank_total > 0 ) then
					msg = msg.."|T"..UBI_LOCATION_TEXTURE[2]..":0|t "..UBI_ACCOUNT_BANK_TITLE.." = "..accountbank_total.." / ";
				end;

                -- Display result
                count = count + 1;
                UberInventory_Message( msg:sub( 1, msg:len()-3 )..")", true );
            end;
        end;
		
		-- Nothing found by joining player and account banks, so now just search account bank
		if ( found_something == false ) then
			for key, record in pairs( UBI_Accountbank["Items"] ) do
				if ( ( strfind( strlower( record.name ) , strlower( str ) ) or 0 ) > 0 ) then
					if ( record.total > 0 ) then
						found_something = true;
						accountbank_total = record.total;
						
						-- Set item image
						if ( record.type == UBI_BATTLEPET_CLASS and record.itemid ~= 82800 ) then
							_, icon = C_PetJournal.GetPetInfoBySpeciesID( record.itemid );
						else
							icon = GetItemIcon( record.itemid );
						end;
						
						-- Build search result
						itemText = "|T"..icon..":0|t "..UberInventory_GetLink( record.itemid, record );
						msg = "  "..itemText.." "..UBI_ITEM_COUNT_SINGLE:format( accountbank_total ).." (";
						msg = msg.."|T"..UBI_LOCATION_TEXTURE[2]..":0|t "..UBI_ACCOUNT_BANK_TITLE.." = "..accountbank_total.." / ";
						UberInventory_Message( msg:sub( 1, msg:len()-3 )..")", true );
					end;
				end;
			end;
		end;

        -- Display end of search
        if ( found_something == false ) then
           UberInventory_Message( UBI_ITEM_SEARCH_NONE, true );
        else
           UberInventory_Message( UBI_ITEM_SEARCH_DONE, true );
        end;
    end;


-- Remove character or guildbank data
    function UberInventory_RemoveData( data )
		-- split of command and name (guildbank names can contain spaces, unlike character names)
        local command, _ = strsplit( " ", data ):lower();
        local name = data:sub( command:len()+2 );

        -- Remove the data for a character
        if ( command == "remchar"  and name ~= "Guildbank" ) then
			-- Check for valid formatting of character-realm (eg, Secretly-Medivh)
			if (not string.find( name, "-", 1 ) ) then
				UberInventory_Message( UBI_REM_CHARACTER_FORMAT, true );
				return;
			end;

	        -- Break apart "player-realm"
		    local player = string.sub ( name, 1, string.find( name, "-", 1 ) - 1 );
		    local realm = string.sub ( name, string.find( name, "-", 1 ) + 1, string.len( name ) );

            -- Do not remove data for the current connected character and realm
            if ( player == UBI_PLAYER and realm == UBI_REALM ) then
                UberInventory_Message( UBI_REM_NOTALLOWED:format( name ), true );
                return;
            end;

            -- Check if character has data stored and delete it if so
            if ( UBI_Data[realm][player] ) then
                StaticPopupDialogs["UBI_CONFIRM_DELETE"].OnAccept = function()
                    -- Remove data
                    UBI_Data[realm][player] = nil;

                    -- Display message
                    UberInventory_Message( UBI_REM_DONE:format( name ), true );

                    -- Rebuild list of alts
                    UberInventory_GetAlts();

                    -- Reset filters
                    UberInventory_ResetFilters();
					
					-- Refresh data deletion dialog
					UberInventory_DisplayDeletionList();
                end;

                -- Ask for remove confirmation
                StaticPopup_Show( "UBI_CONFIRM_DELETE", UBI_REM_CHARACTER:format( name ) );
            else
                UberInventory_Message( UBI_REM_CHARNOTFOUND:format( name ), true );
            end;
		end;
		
		-- Remove the data for a guild
        if ( command == "remguild" ) then
            -- Check if guildbank has data stored and delete it if so
            if ( UBI_Guildbank[name] ) then
                StaticPopupDialogs["UBI_CONFIRM_DELETE"].OnAccept = function()
                    -- Remove data
                    UBI_Guildbank[name] = nil;

                    -- Display message
                    UberInventory_Message( UBI_REM_DONE:format( name ), true );

                    -- When current guild is removed reinitialize data structure
                    if ( UBI_GUILD == name ) then
                        UberInventory_Guildbank_Init();
                    end;

                    -- Rebuild list of guildbanks
                    UberInventory_GetGuildbanks();

                    -- Reset filters
                    UberInventory_ResetFilters();
					
					-- Refresh data deletion dialog
					UberInventory_DisplayDeletionList();
                end;

                -- Ask for remove confirmation
                StaticPopup_Show( "UBI_CONFIRM_DELETE", UBI_REM_GUILDBANK:format( name ) );
            else
                UberInventory_Message( UBI_REM_GUILDNOTFOUND:format( name ), true );
            end;
        end;

        -- Rebuild location list
        UberInventory_Build_Locations();
    end;

-- Show help message
    function UberInventory_ShowHelp()
        for key, value in pairs( UBI_HELP ) do
            UberInventory_Message( value, true );
        end;
    end;

-- Handle slash commands
    function UberInventory_SlashHandler( msg, editbox )
        -- arguments should be handled case-insensitve
        local orgData = msg;
        msg = strlower( msg );

        -- Handle each individual argument
        if ( msg == "" ) then
        -- Show main dialog
            UberInventory_Toggle_Main();
        elseif ( msg:find( "remchar" ) or msg:find( "remguild" ) ) then
            -- Remove character or guild data
            UberInventory_RemoveData( orgData );
        elseif ( msg == "help" ) or ( msg == "?" ) then
            -- Show help info
            UberInventory_ShowHelp();
        elseif ( msg == "minimap" ) then
            -- Toggle minimap icon
            addon:MinimapToggle()
        elseif ( msg == "resetpos" ) then
            UberInventoryFrame:ClearAllPoints();
            UberInventoryFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
        elseif ( msg == "sendgb" ) then
            if ( UBI_GUILDBANK_OPENED and UBI_GUILDBANK_VIEWACCESS ) then
                UberInventory_Send_Guildbank();
            else
                if ( not UBI_GUILDBANK_OPENED ) then
                    UberInventory_Message( UBI_SENDGB_VISIT, true );
                end;
                if ( not UBI_GUILDBANK_VIEWACCESS ) then
                    UberInventory_Message( UBI_SENDGB_ACCESS, true );
                end;
            end;
        elseif ( msg == "requestgb" ) then
            UBI_GUILDBANK_FORCED = true;
            TaskHandlerLib:AddTask( "UberInventory", UBI_Task_SendMessage, "GBREQUEST" );
            UberInventory_Message( UBI_GB_REQUESTED, true );
	    elseif ( msg == "dumpcurrencies" ) then
			DumpCurrencies();
	    elseif ( msg == "popup" ) then
			UberInventory_Message( UBI_POPUP_REQUESTED, true );
			UberInventory_UpgradeMessage();
	    elseif ( msg == "test" ) then
			UberInventory_TestHarness();
	    elseif ( msg == "rested" ) then
			UberInventory_Rested();
        else
            -- Perform item search
            UberInventory_Search( msg or "" );
        end;
    end;

-- Create a minimap button & data table using ACE 3	
    function addon:OnInitialize()
	    -- data table
	    self.db = LibStub("AceDB-3.0"):New("UBI_Minimap", {
		    profile = {
			    minimap = {
				    hide = false,
			    },
		    },
	    })
		-- register button & chat command
	    minimapIcon:Register("UberInventory", UBILDB, self.db.profile.minimap)
		--self:RegisterChatCommand("ubi_minimap", "MinimapToggle")
		
		if self.db.profile.minimap.hide then
		    UberInventory_Message( UBI_MINIMAP_OFF, true );
		end
    end

-- Show/Hide minimap icon
    function addon:MinimapToggle()
	    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
	    if self.db.profile.minimap.hide then
		    minimapIcon:Hide("UberInventory");
			UberInventory_Message( UBI_MINIMAP_OFF, true );
	    else
		    minimapIcon:Show("UberInventory");
			UberInventory_Message( UBI_MINIMAP_ON, true );
	    end
    end

-- list all currencies that have been DISCOVERED to the local chat window
-- updated for v9.0
    function DumpCurrencies()
		UberInventory_Message( "Debugging Currencies", true );
		
		for i = 61,3000,1 do
		    --v9.0 moved to C_CurrencyInfo
			local CurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(i);
		    if ( CurrencyInfo ) then
			    DEFAULT_CHAT_FRAME:AddMessage( string.format("ID: %d | %s: Current: %d | Discovered: %s", i, CurrencyInfo.name, CurrencyInfo.quantity, tostring(CurrencyInfo.discovered)) )
			end
		end
	end
	
-- Get account-wide gold amount
    function GetAccountWideGoldValue()
		local DEBUG = false;
		
		local UBI_Data = UBI_Data;
        local realm;
		local currencyTotal = 0;

		if ( DEBUG ) then
			UberInventory_Message( "Debugging GetAccountWideGoldValue()", true );
		end;
		
 	    for key, record in pairs( UBI_Data ) do
			realm = key;

			for player, value in pairs( UBI_Data[realm] ) do
				if ( player ~= "Guildbank" ) then
					currencyTmp = UBI_Data[realm][player]["Money"]["Cash"];
					currencyTotal = currencyTotal + currencyTmp;
					
					if ( DEBUG ) then 
						currencyStr = GetCoinTextureString( currencyTmp );
						currencyTotalStr = GetCoinTextureString( currencyTotal );
						DEFAULT_CHAT_FRAME:AddMessage( string.format("Player: %s | %s", player, currencyStr) );
						DEFAULT_CHAT_FRAME:AddMessage( string.format("TOTAL: %s", currencyTotalStr) );
					end;
				end
			end
			
		end
		
		currencyTotal = currencyTotal + UBI_Accountbank["Cash"];
		
		return currencyTotal;

	end


-- Called by the timer below upon first load
-- Resolves taint issues with the inventory caused by addons such as CanIMogIt
	function UberInventory_UpdateInventoryNewLoad()
		UberInventory_UpdateInventory( "all" );
		UberInventory_Message( UBI_ADDON_FIRSTLOAD, true );
	end;
	

-- Test harness
	function UberInventory_TestHarness()
		UberInventory_Message("START of test harness.", true);

		UberInventory_Save_AccountBank();
			
		UberInventory_Message("END of test harness.", true);
	end;
	
	

-- Rested XP slash command output
	function UberInventory_Rested()
		local iRested = GetXPExhaustion();
		if ( iRested ~= nil ) then
			UberInventory_Message( string.format( UBI_RESTED_STRING1, 100 * iRested / UnitXPMax("player") ), true );
		else
			UberInventory_Message( UBI_RESTED_NONE, true );
		end;
	end;
	
	
-- Ask for a reload of the UI
	function UberInventory_ReloadUI()
		StaticPopupDialogs["UberInventory_ReloadUI"] = {
			text = C_GOLD..UBI_NAME..C_GOLD.." - "..UBI_VERSION..C_CLOSE..
			       "\n\nA reload is required to enable this option."..C_CLOSE.."\nClick "..C_YELLOW.."OK"..C_CLOSE.." to continue.",
			button1 = "OK",
			button2 = "Cancel",
			OnAccept = function (self) ReloadUI() end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		}
		StaticPopup_Show("UberInventory_ReloadUI");
	end;
	
	-- Current Upgrade Message
	function UberInventory_UpgradeMessage()
		StaticPopupDialogs["UberInventory_UpgradeMessage"] = {
			text = C_GOLD..UBI_NAME..C_GOLD.." - "..UBI_VERSION.." Information"..C_CLOSE..
			       C_GREEN.."\n\nUpdates for this release:"..C_CLOSE..
				   "\n\n** "..C_RED.."Reload any played characters **"..C_CLOSE.." if UBI was enabled since the patch."..
				   "\n\n   > Changes to item links and qualities caused item ids to not function. All have been fixed."..
				   "\n\n   > If your tooltip data looks incorrect, reload your characters and visit the bank & mailbox."..
				   "\n\nSilentsongEQ."..
				   C_CLOSE.."\n\n",
			button1 = "OK",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		}
		StaticPopup_Show("UberInventory_UpgradeMessage");
	end;
	
