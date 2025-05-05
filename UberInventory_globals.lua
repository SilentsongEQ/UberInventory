--[[ =================================================================
    Description:
        All globals used within UberInventory.
    ================================================================= --]]

-- Base colors
    C_GOLD   = "|cFFFFD700";
    C_SILVER = "|cFFC7C7CF";
    C_COPPER = "|cFFEDA55F";
    C_GREEN  = "|cFF00FF00";
    C_WHITE  = "|cFFFFFFFF";
    C_BLUE   = "|cFF3366FF";
    C_RED    = "|cFFFF5533";
    C_YELLOW = "|cFFFFFF00";
    C_GREY   = "|cFFAAAAAA";
	C_CYAN   = "|cFF00FFFF";
    C_CLOSE  = "|r";
	
-- Class colors
-- Ref: https://wow.gamepedia.com/Class_colors
	C_PRIEST = "|cFFFFFFFF";
	C_DEATHKNIGHT = "|cFFC41F3B";
	C_WARRIOR = "|cFFC79C6E";
	C_PALADIN = "|cFFF58CBA";
	C_ROGUE = "|cFFFFF569";
	C_HUNTER = "|cFFA9D271";
	C_SHAMAN = "|cFF0070DE";
	C_MAGE = "|cFF40C7EB";
	C_WARLOCK = "|cFF8787ED";
	C_MONK = "|cFF00FF96";
	C_DRUID = "|cFFFF7D0A";
	C_DEMONHUNTER = "|cFFA330C9";
	C_EVOKER = "|cFF33937F";
	
-- Image path
    UBI_IMG_PATH = "Interface\\AddOns\\UberInventory\\artwork\\";

-- Custom textures
    UBI_SIGMA_ICON = "|T"..UBI_IMG_PATH.."sigma:0|t";

-- Events tracked by UBI
    UBI_TRACKED_EVENTS = { -- Startup events
                           "PLAYER_LOGIN",
                           "PLAYER_LOGOUT",
                           "ADDON_LOADED",

                           -- Character event (equipped items)
                           "UNIT_INVENTORY_CHANGED",

                           -- Bank events
                           "BANKFRAME_OPENED",
                           "BANKFRAME_CLOSED",
                           "PLAYERBANKSLOTS_CHANGED",
                           "PLAYERBANKBAGSLOTS_CHANGED",
						   
						   -- Account bank Events
						   "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",

                           -- Guildbank events
                           "GUILDBANKFRAME_OPENED",
                           "GUILDBANKFRAME_CLOSED",
                           "GUILDBANK_UPDATE_MONEY",

                           -- Mailbox events
                           "MAIL_SHOW",
                           "MAIL_INBOX_UPDATE",
                           "MAIL_SUCCESS",

                           -- Player events
                           "PLAYER_ENTERING_WORLD",
                           "PLAYER_LEAVING_WORLD",

                           -- Chat events
                           "CHAT_MSG_ADDON",

                           -- Currency events
                           "PLAYER_MONEY",
                           "CURRENCY_DISPLAY_UPDATE",

                           -- Miscellaneous events
                           "PLAYER_LEVEL_UP",

                           -- Void Storage
                           "VOID_STORAGE_UPDATE",
                           "VOID_TRANSFER_DONE",
                           "VOID_STORAGE_CONTENTS_UPDATE",

                           -- Pandarian toon has selected faction
                           "NEUTRAL_FACTION_SELECT_RESULT",

                           -- Reagents
                           "REAGENTBANK_UPDATE",
                           "PLAYERREAGENTBANKSLOTS_CHANGED",
						   
						   -- Merchant window (repairs, selling)
						   "MERCHANT_SHOW",
						   
						   -- Generic window handler (use v10 client and above)
						   -- https://wowpedia.fandom.com/wiki/PLAYER_INTERACTION_MANAGER_FRAME_SHOW
						   "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
						   "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
                         };

-- Drop rates
    UBI_Droprates = { "1%-2%" ,    -- Extremely low
                      "3%-14%" ,   -- Very low
                      "15%-24%" ,  -- Low
                      "25%-50%" ,  -- Medium
                      "51%-99%" ,  -- High
                      "100%" };    -- Guaranteed

-- Global variables
    UBI = _G["UBI"]; -- AddOn object itself
    UBI_NAME = C_AddOns.GetAddOnMetadata( "UberInventory", "Title" );
    UBI_VERSION = C_AddOns.GetAddOnMetadata( "UberInventory", "Version" );
	UBI_PATCHER = C_AddOns.GetAddOnMetadata( "UberInventory", "X-Patcher" );
	UBI_SHOWUPGRADEMESSAGE = C_AddOns.GetAddOnMetadata( "UberInventory", "X-ShowUpgradeMessage" );
    UBI_NAME_VERSION = UBI_NAME.." - "..UBI_VERSION;
    UBI_TOKEN = TOKENS.." (%s)";
    UBI_REALM = GetRealmName();
    UBI_PLAYER = UnitName( "player" );
    UBI_PLAYER_CLASS = UnitClass( "player" );
    UBI_PLAYER_RACE = UnitRace( "player" );
    UBI_GUILD = nil;
    UBI_FACTION = UnitFactionGroup( "player" );
    UBI_EMPTY_TEXT = "---";
    UBI_MAILBOX_OPEN = false;          -- Is the mailbox open?
    UBI_BANK_OPEN = false;             -- Is the bank open?
    UBI_GUILDBANK_VIEWACCESS = true;   -- View access to all guildbank tabs?
    UBI_GUILDBANK_OPENED = false;      -- Has the guildbank been opened during current session
    UBI_GUILDBANK_FORCED = false;      -- Force receiving of guildbank data (when requesting data manually)
    UBI_SEC_IN_DAY = 60 * 60 * 24;     -- The number of seconds in a day
    UBI_VERSION_WARNING = false;       -- Received version warning
    UBI_TooltipItem = nil;             -- Filled from main inventory frame (used to show correct counts when showing alt information)
    UBI_TooltipLocation = nil;         -- Filled from main inventory frame (used to hide alt if the alt is viewed)
    UBI_CHECK_DATE = date( "%Y%m%d" ); -- Date when last daily check has been performed
    UBI_PROCESSING_GB = false;         -- Currently processing/saving GB data
    UBI_MINIMAP_ANGLE = nil;           -- Current angle for the minimap
    UBI_ACTIVE = true;
    UBI_BATTLEPET_CLASS = GetItemClassInfo(17);

-- Alts and Guildbanks
    UBI_Characters = {};               -- Used for list of alt characters
    UBI_Guildbanks = {};               -- Used for list of guildbanks
    UBI_Guildbank = {};                -- Shortcut for guildbank data for current realm
    UBI_LocationList = {};             -- Used to track all locations combined
    UBI_LocationCounter = 0;           -- Used to track the number of items in location dropdownbox
	g_deletionList = {};			   -- Used to store the list of guilds and playernames that can be deleted in the deletion dialog

-- Globals for receiving guildbank data
    UBI_GBData = {};                   -- Array for receiving guildbank data through the guild chat channel
    UBI_GBSender = nil;                -- Who is sending guildbank data (only the latest player is tracked)

-- Days between collection events before message is displayed to visit mailbox, bank or guildbank
    UBI_MAILBOX_VISIT_INTERVAL = 21;   -- in days
    UBI_BANK_VISIT_INTERVAL = 30;      -- in days
    UBI_GUILDBANK_VISIT_INTERVAL = 14; -- in days

-- When should expiring mail be reported
    UBI_MAIL_EXPIRE_WARNING = 5;       -- in days
	UBI_MAIL_EXPIRE_CUTOFF = 14;       -- in days - do not report expired mails older than this number

-- Filter settings
    UBI_FILTER_TEXT = "";              -- Default no search string
    UBI_FILTER_LOCATIONS = 4;  		   -- Default Items dropdown selection (player)
    UBI_FILTER_QUALITY = 1;            -- Default all qualities
    UBI_FILTER_CLASSES = 1;            -- Default all classes
    UBI_FILTER_SUBCLASSES = 0;         -- Default no subclass
    UBI_FILTER_USABLE = false;         -- Only show usable items
    UBI_SCAN_DATE = time();            -- Latest inventory scan
    UBI_Filter = { text = nil,
                   location = nil,
                   quality = nil,
                   class = nil,
                   subclass = nil,
                   usable = nil,
                   date = nil }; -- Track current search settings

-- Equip slots
    UBI_EQUIP_SLOTS = { "HeadSlot",
                        "NeckSlot",
                        "ShoulderSlot",
                        "BackSlot",
                        "ChestSlot",
                        "ShirtSlot",
                        "TabardSlot",
                        "WristSlot",
                        "HandsSlot",
                        "WaistSlot",
                        "LegsSlot",
                        "FeetSlot",
                        "Finger0Slot",
                        "Finger1Slot",
                        "Trinket0Slot",
                        "Trinket1Slot",
                        "MainHandSlot",
                        "SecondaryHandSlot" }; -- AmmoSlot is excluded, counts as 1 regardless number of arrows/bullets are linked

-- Container objects
    UI_CONTAINER_OBJECTS = { [-3] = ReagentBankFrame, 			-- Reagent bank
							 [-1] = BankFrame,
                             [0] = MainMenuBarBackpackButton,
                             [1] = CharacterBag0Slot,
                             [2] = CharacterBag1Slot,
                             [3] = CharacterBag2Slot,
                             [4] = CharacterBag3Slot,
							 [5] = CharacterReagentBag0Slot,	-- Reagent bag
                             [6] = BankSlotsFrame["Bag1"],
                             [7] = BankSlotsFrame["Bag2"],
                             [8] = BankSlotsFrame["Bag3"],
                             [9] = BankSlotsFrame["Bag4"],
                             [10] = BankSlotsFrame["Bag5"],
                             [11] = BankSlotsFrame["Bag6"],
                             [12] = BankSlotsFrame["Bag7"]
                             };
    UBI_Highlights = {};

-- Quality names (using Blizzards localized strings) and colors
-- https://warcraft.wiki.gg/wiki/Enum.ItemQuality
    UBI_QUALITY = { ITEM_QUALITY0_DESC,
                    ITEM_QUALITY1_DESC,
                    ITEM_QUALITY2_DESC,
                    ITEM_QUALITY3_DESC,
                    ITEM_QUALITY4_DESC,
                    ITEM_QUALITY5_DESC,
                    ITEM_QUALITY6_DESC,
                    ITEM_QUALITY7_DESC,
                    ITEM_QUALITY8_DESC };

-- Location texture (Guildbank image dynamic based on faction)
    UBI_LOCATION_TEXTURE = { UBI_IMG_PATH.."bag",
                             UBI_IMG_PATH.."bank",
                             UBI_IMG_PATH.."mail",
                             UBI_IMG_PATH.."equipped",
                             UBI_IMG_PATH.."voidstorage",
                             UBI_IMG_PATH.."reagents",
                             UBI_IMG_PATH..string.lower( UBI_FACTION ) };

-- Frame/tooltip related options
    UBI_NUM_ITEMBUTTONS = 16;
    UBI_NUM_TOKENBUTTONS = 20;
	UBI_NUM_DELETIONBUTTONS = 20;
    UBI_MAX_RECIPE_INFO = 10;

-- Saved variable
    UBI_Data = {};           -- Main data structure for UberInventory (items, prices, options)
	UBI_Global_Options = {}; -- Settings that are not character bound

-- Inventory items (Sorted and filtered)
    UBI_Sorted = {};
    UBI_Track = {};
    UBI_Inventory_count = 0;
    UBI_Items_Work = {};

-- Tooltip hook related stuff
    currentItemCount = 0;
    currentItemId = nil;
    UBI_Hooks = {};
    --UBI_Hooks["OnTooltipSetItem"] = {};
    UBI_Hooks["OnTooltipCleared"] = {};
    UBI_Hooks["ReturnInboxItem"] = {};
    UBI_Hooks["SendMail"] = {};

-- Mail transfer
    UBI_Mail_Transfer = {};
    
-- Default settings
    UBI_Defaults = { ["show_money"] = false,
                     ["show_balance"] = false,
                     ["show_tooltip"] = true,
                     ["show_item_count"] = true,
                     ["show_highlight"] = true,
                     ["show_recipe_prices"] = false,
                     ["show_recipe_reward"] = true,
                     ["show_recipe_drop"] = true,
                     ["alpha"] = 1,
                     ["take_money"] = false,
                     ["track_gb_data"] = true,
                     ["send_gb_data"] = true,
                     ["receive_gb_data"] = true,
                     ["warn_mailexpire"] = true,
					 ["ignore_realm"] = true,
					 ["sell_greys"] = false,
					 ["autorepair_self"] = false,
					 ["show_item_id"] = true,
					 ["patch_message_version"] = "1.1.1.1",
					 };